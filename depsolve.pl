%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dependency types.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A build dependency.
deptype(build).
% A linker dependency.
deptype(link).
% A runtime-only dependency.
deptype(run).

% Check that all values in a list are deptypes.
deptypes_are_valid([]).
deptypes_are_valid([Deptype|Deptypes]) :-
    % Deptypes are a closed set.
    deptype(Deptype), !,
    deptypes_are_valid(Deptypes).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Version checks.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Compare two version numbers.

% Open-ended ranges.
version_compare(ver_any, _).
version_compare(_, ver_any).

% Exhausted the version range.
version_compare([], []).

% Extend the lower version with 0.
version_compare([], High) :-
    version_compare([0], High).
% Extend the higher version with 0.
version_compare(Low, []) :-
    version_compare(Low, [0]).

% Check the top-most version number.
version_compare([Low|_], [High|_]) :-
    Low < High.
% If the version numbers are equal, check the next version part.
version_compare([Low|Lows], [High|Highs]) :-
    Low == High,
    version_compare(Lows, Highs).

% Check if a version number is within a range.
version_between(Low, High, Version) :-
    % Ensure that Low <= High. If this is bad, things are not going well.
    version_compare(Low, High), !,
    % Check the version against the given bounds.
    version_compare(Low, Version),
    version_compare(Version, High).

version_match(ver_any, _).
version_match(_, []).
version_match([Version|Versions], [VersionRequest|VersionRequests]) :-
    Version == VersionRequest, !,
    version_match(Versions, VersionRequests).

% A single range is fine.
versions_resolve_ranges([[VersionLow, VersionHigh]], [VersionLow, VersionHigh]).
% Ignore unbounded ranges.
versions_resolve_ranges([[ver_any, ver_any]|VersionRanges], [ReqVersionLow, ReqVersionHigh]) :-
    versions_resolve_ranges(VersionRanges, [ReqVersionLow, ReqVersionHigh]),
    !.
versions_resolve_ranges([[VersionLow, VersionHigh]|VersionRanges], [ReqVersionLow, ReqVersionHigh]) :-
    % We must have a lower bound higher than all requested lower bounds.
    version_compare(VersionLow, ReqVersionLow),
    % We must have an upper bound lower than all requested upper bounds.
    version_compare(ReqVersionHigh, VersionHigh),
    % Handle the remaining ranges.
    versions_resolve_ranges(VersionRanges, [ReqVersionLow, ReqVersionHigh]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Package predicates.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Package declaration API.
:- discontiguous(package/1).
:- discontiguous(package_version/4).
:- discontiguous(package_version_default/2).
:- discontiguous(package_variant/2).
:- discontiguous(package_variant_default/2).
:- discontiguous(package_depends_on/2).

% Package dependency API.
:- discontiguous(package_dep_package/2).
:- discontiguous(package_dep_version/3).
:- discontiguous(package_dep_variants/2).
:- discontiguous(package_dep_nvariants/2).
:- discontiguous(package_dep_when/2).
:- discontiguous(package_dep_deptypes/2).

% Check that a package has the variants requested.
package_has_variants(_, []).
package_has_variants(Package, [Variant|Variants]) :-
    package_variant(Package, Variant),
    package_has_variants(Package, Variants).

% Find all packages depended on by a package.
package_depends(Package, PackageDepends) :-
    findall(PackageDepend, package_depends_on(Package, PackageDepend), PackageDepends).

% Find out if a package is a pure builddep.
package_deps_pure_builddep([], []).
package_deps_pure_builddep([PackageDepend|PackageDepends], [PackageDepend|BuildDepends]) :-
    package_dep_deptypes(PackageDepend, [build]),
    !,
    package_deps_pure_builddep(PackageDepends, BuildDepends).
package_deps_pure_builddep([_|PackageDepends], BuildDepends) :-
    package_deps_pure_builddep(PackageDepends, BuildDepends).

package_deps_no_pure_builddep([], []).
package_deps_no_pure_builddep([PackageDepend|PackageDepends], NoBuildDepends) :-
    package_dep_deptypes(PackageDepend, [build]),
    !,
    package_deps_no_pure_builddep(PackageDepends, NoBuildDepends).
package_deps_no_pure_builddep([PackageDepend|PackageDepends], [PackageDepend|NoBuildDepends]) :-
    package_deps_no_pure_builddep(PackageDepends, NoBuildDepends).

package_deps_packages([], []).
package_deps_packages([PackageDepend|PackageDepends], [Package|Packages]) :-
    package_dep_package(PackageDepend, Package),
    package_deps_packages(PackageDepends, Packages).

package_deps_requirements([], [], [], []).
package_deps_requirements([PackageDepend|PackageDepends], [[VersionLow, VersionHigh]|Versions],
                          [Variant|Variants], [NotVariant|NotVariants]) :-
    package_dep_version(PackageDepend, VersionLow, VersionHigh),
    package_dep_variants(PackageDepend, Variant),
    package_dep_nvariants(PackageDepend, NotVariant),
    package_deps_requirements(PackageDepends, Versions, Variants, NotVariants).

package_find_best_version(Package, VersionRequest, Version) :-
    package_version(Package, Version, _, _),
    version_match(Version, VersionRequest).

package_find_best_version_candidates(Package, PackageVersion, []) :-
    package_version(Package, PackageVersion, _, _).
package_find_best_version_candidates(Package, PackageVersion, [Version|_]) :-
    package_find_best_version(Package, Version, PackageVersion).
package_find_best_version_candidates(Package, PackageVersion, [_|Versions]) :-
    package_find_best_version_candidates(Package, PackageVersion, Versions).

packages_check_virtuals([], _).
packages_check_virtuals([Package|Packages], Virtuals) :-
    virtual_package(Package),
    !,
    packages_check_virtuals(Packages, Virtuals).
packages_check_virtuals([Package|Packages], Virtuals) :-
    virtual_package_package(_, Package),
    !,
    setof(VirtualPackage, virtual_package_package(VirtualPackage, Package), VirtualPackages),
    intersection(VirtualPackages, Virtuals, []),
    !,
    packages_check_virtuals(Packages, [VirtualPackage|Virtuals]).
packages_check_virtuals([_|Packages], Virtuals) :-
    packages_check_virtuals(Packages, Virtuals).

%package_deps_resolve(Depends, [VirtualPackage|Packages], OldPackages, [[Package, Version, Variants, NotVariants]|ResolvedPackages]) :-
%    virtual_package(VirtualPackage),
%    findall(ImplPackage, virtual_package_package(VirtualPackage, ImplPackage), ImplPackages),
%    append(Packages, OldPackages, OtherPackages),
%    intersection(OtherPackages, ImplPackages, [ActiveImpl])
%    !,
%    findall(PackageDepPackage, (package_dep_package(PackageDepPackage, Package);
%                                package_dep_package(PackageDepPackage, VirtualPackage)),
%            PackageDepends),
%    true.

package_deps_resolve(_, [], []).
package_deps_resolve(Depends, [Package|Packages], [[Package, Version, AllVariants, AllNotVariants]|ResolvedPackages]) :-
    % Find all package depends which care about this package.
    findall(PackageDepPackage, package_dep_package(PackageDepPackage, Package), PackageDepends),
    % Filter them according to the package depends we're looking at now.
    intersection(Depends, PackageDepends, ActiveDepends),
    % Get all of the required dependency information.
    package_deps_requirements(ActiveDepends, Versions, Variants, NotVariants),
    % Make sure variants are OK.
    flatten(Variants, AllVariants),
    flatten(NotVariants, AllNotVariants),
    package_variants_ok(AllVariants, AllNotVariants),
    % Cut here because if variants don't work, nothing will.
    !,
    % Find a suitable version for the package.
    versions_resolve_ranges(Versions, [VersionLow, VersionHigh]),
    findall(PackageVersion, (package_version(Package, PackageVersion, _, _),
                             version_between(VersionLow, VersionHigh, PackageVersion)), PackageVersions),
    memberchk(Version, PackageVersions),
    % Resolve the reamining packages.
    package_deps_resolve(Depends, Packages, ResolvedPackages).

package_variants_ok([], _).
package_variants_ok(_, []).
package_variants_ok([Variant|Variants], NotVariants) :-
    \+memberchk(Variant, NotVariants),
    package_variants_ok(Variants, NotVariants).

resolved_package_install(ResolvedPackage, AllPackages, InstalledPackage) :-
    resolved_package_package(ResolvedPackage, Package),
    package_depends(Package, Depends),
    spec_active_dependencies(ResolvedPackage, Depends, ActiveDepends).

resolved_package_find_trees([], _, []).
resolved_package_find_trees([Package|Packages], AllPackages, [InstallTree|InstallTrees]) :-
    spec_deptree(Package, InstallTree),
    resolved_package_find_trees(Packages, AllPackages, InstallTrees).

resolved_packages_install([], _, []).
resolved_packages_install([Package|Packages], AllPackages, [InstalledPackage|InstalledPackages]) :-
    resolved_package_find_trees(Packages, AllPackages),
    resolved_package_install(Package, AllPackages, InstalledPackage),
    resolved_packages_install(Packages, AllPackages, InstalledPackages).

resolved_package([Package, Version, Variants, NotVariants]) :-
    package(Package),
    package_version(Package, Version, _, _),
    findall(Variant, package_variant(Package, Variant), Variants),
    findall(NotVariant, package_variant(Package, NotVariant), NotVariants).
resolved_package_package([Package, _, _, _], Package) :- !.
resolved_package_version([_, Version, _, _], Version) :- !.
resolved_package_variants([_, _, Variants, _], Variants) :- !.
resolved_package_nvariants([_, _, _, NotVariants], NotVariants) :- !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Virtual package predicates.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Virtual package API.
:- discontiguous(virtual_package/1).
:- discontiguous(virtual_package_package/2).
:- discontiguous(virtual_package_version/4).

package(VirtualPackage) :-
    virtual_package(VirtualPackage),
    !.
package_version(VirtualPackage, Version, Url, Hash) :-
    virtual_package(VirtualPackage),
    !,
    virtual_package_version(VirtualPackage, Version, ImplPackage, ImplVersion),
    virtual_package_package(VirtualPackage, ImplPackage),
    package_version(ImplPackage, ImplVersion, Url, Hash).
package_version_default(VirtualPackage, Version) :-
    package_version(VirtualPackage, Version, _, _),
    !.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Depspec predicates.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Depspec API.
:- discontiguous(depspec_package/2).
:- discontiguous(depspec_version/2).
:- discontiguous(depspec_variants/2).
:- discontiguous(depspec_nvariants/2).

% Check that a depspec is valid. `Package` is a package the depspec is valid for.
depspec_is_valid(Depspec, Package) :-
    depspec_package(Depspec, Package),
    package(Package),
    depspec_version(Depspec, _),
    depspec_variants(Depspec, Variants),
    package_has_variants(Package, Variants),
    depspec_nvariants(Depspec, NotVariants),
    package_has_variants(Package, NotVariants).

% Check a list of depspecs are valid.
depspecs_are_valid([]).
depspecs_are_valid([Depspec|Depspecs]) :-
    depspec_is_valid(Depspec, _),
    depspecs_are_valid(Depspecs).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spec predicates.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Spec API.
:- discontiguous(spec_package/2).
:- discontiguous(spec_version/2).
:- discontiguous(spec_variants/2).
:- discontiguous(spec_nvariants/2).
:- discontiguous(spec_dependencies/2).

% Package dep -> spec handling.
spec_package(PackageDepend, Package) :-
    package_dep_package(PackageDepend, Package),
    !.
spec_version(PackageDepend, Version) :-
    package_dep_version(PackageDepend, VersionMin, VersionMax),
    spec_package(PackageDepend, Package),
    !,
    % Try the default version.
    package_version_default(Package, Version),
    version_between(VersionMin, VersionMax, Version).
spec_version(PackageDepend, Version) :-
    package_dep_version(PackageDepend, VersionMin, VersionMax),
    spec_package(PackageDepend, Package),
    !,
    % Find a valid version.
    package_version(Package, Version, _, _),
    version_between(VersionMin, VersionMax, Version).
spec_variants(PackageDepend, Variants) :-
    package_dep_variants(PackageDepend, Variants),
    !.
spec_nvariants(PackageDepend, NotVariants) :-
    package_dep_nvariants(PackageDepend, NotVariants),
    !.
spec_dependencies(PackageDepend, []) :-
    package_dep_package(PackageDepend, _),
    % Package deps never have dependencies.
    !.

% Virtual package -> spec handling.
spec_package(VirtualPackage, Package) :-
    virtual_package(VirtualPackage),
    !,
    virtual_package_package(VirtualPackage, Package).
spec_version(VirtualPackage, Version) :-
    virtual_package(VirtualPackage),
    !,
    virtual_package_version(VirtualPackage, Version, _, _).
spec_variants(VirtualPackage, []) :-
    virtual_package(VirtualPackage),
    !.
spec_nvariants(VirtualPackage, []) :-
    virtual_package(VirtualPackage),
    !.
spec_dependencies(VirtualPackage, []) :-
    virtual_package(VirtualPackage),
    !.

% Depspec -> spec handling.
spec_package(Depspec, Package) :-
    depspec_package(Depspec, Package),
    !.
spec_version(Depspec, Version) :-
    depspec_version(Depspec, Version),
    !.
spec_variants(Depspec, Variants) :-
    depspec_variants(Depspec, Variants),
    !.
spec_nvariants(Depspec, NotVariants) :-
    depspec_nvariants(Depspec, NotVariants),
    !.
spec_dependencies(Depspec, []) :-
    depspec_package(Depspec, _),
    % Depspecs never have dependencies.
    !.

% Resolved package -> spec handling.
spec_package(ResolvedPackage, Package) :-
    resolved_package(ResolvedPackage),
    !,
    resolved_package_package(ResolvedPackage, Package).
spec_version(ResolvedPackage, Version) :-
    resolved_version(ResolvedPackage),
    !,
    resolved_package_version(ResolvedPackage, Version).
spec_variants(ResolvedPackage, Variants) :-
    resolved_variants(ResolvedPackage),
    !,
    resolved_package_variants(ResolvedPackage, Variants).
spec_nvariants(ResolvedPackage, NotVariants) :-
    resolved_nvariants(ResolvedPackage),
    !,
    resolved_package_nvariants(ResolvedPackage, NotVariants).
spec_dependencies(ResolvedPackage, []) :-
    resolved_package(ResolvedPackage),
    % Resolved packages never have dependencies.
    !.

% Check if a variant is enabled on a spec.
spec_variant_enabled(Spec, Variant) :-
    spec_variants(Spec, Variants),
    memberchk(Variant, Variants).
% Check the package to see if it defaults to on.
spec_variant_enabled(Spec, Variant) :-
    spec_package(Spec, Package),
    package_variant(Package, Variant),
    package_variant_default(Package, Variant).

% Ensure a spec has the variants specified.
spec_has_variant(Spec, Variant) :-
    spec_available_variants(Spec, Variants),
    memberchk(Variant, Variants).

% Get the available variants for a spec.
spec_available_variants(Spec, Variants) :-
    spec_package(Spec, Package),
    findall(Variant, package_variant(Package, Variant), Variants).

% Check that a spec is valid. `Package` is a package that the spec is valid for.
spec_is_valid(Spec, Package) :-
    spec_package(Spec, Package),
    package(Package),
    spec_version(Spec, Version),
    package_version(Package, Version, _, _),
    spec_variants(Spec, Variants),
    package_has_variants(Package, Variants),
    spec_nvariants(Spec, NotVariants),
    package_has_variants(Package, NotVariants),
    spec_dependencies(Spec, DepSpecs),
    depspecs_are_valid(DepSpecs).

spec_depends(Spec, Depends) :-
    % Find a package for which the spec works.
    spec_is_valid(Spec, Package),
    % Get all of its dependencies.
    package_depends(Package, Depends).
spec_depends_pure_builddep(Spec, BuildDepends) :-
    % Find a package for which the spec works.
    spec_is_valid(Spec, Package),
    % Get all of its dependencies.
    package_depends(Package, Depends),
    % Get only pure-builddeps.
    package_deps_pure_builddep(Depends, BuildDepends).
spec_depends_no_pure_builddep(Spec, NoBuildDepends) :-
    % Find a package for which the spec works.
    spec_is_valid(Spec, Package),
    % Get all of its dependencies.
    package_depends(Package, Depends),
    % Ignore pure-builddeps.
    package_deps_no_pure_builddep(Depends, NoBuildDepends).

% Find dependencies that matter for a spec.
spec_active_dependencies(_, [], []).
spec_active_dependencies(Spec, [Depend|AllDepends], [Depend|Depends]) :-
    % We cut here because if a package is depended upon due to the spec, we
    % cannot undepend on it.
    package_dep_when(Spec, Depend), !,
    spec_active_dependencies(Spec, AllDepends, Depends).
spec_active_dependencies(Spec, [_|AllDepends], Depends) :-
    spec_active_dependencies(Spec, AllDepends, Depends).

specs_depends([], []).
specs_depends([Spec|Specs], AllDepends) :-
    % Find all deps which aren't pure builddeps (handled later).
    spec_depends_no_pure_builddep(Spec, Depends),
    % Find dependencies which occur in the rest of the list.
    specs_depends(Specs, MoreDepends),
    append(Depends, MoreDepends, CurDepends),
    % Recurse into the deps for the current package.
    specs_depends(Depends, RecursiveDepends),
    append(CurDepends, RecursiveDepends, AllDepends).

% Get the deptree for a spec.
spec_deptree(Spec, ResolvedPackages) :-
    % Find all active dependencies of the top-level package. The top-level
    % spec is already fully specified, so don't backtrack over it.
    spec_depends(Spec, AllSpecDepends),
    spec_active_dependencies(Spec, AllSpecDepends, Depends), !,
    % Find all dependencies.
    specs_depends(Depends, RecursiveDepends),
    % Put the two together.
    append(Depends, RecursiveDepends, AllDepends),
    % Get the packages we depend on.
    package_deps_packages(AllDepends, Packages),
    % Uniquify packages.
    list_to_set(Packages, PackageSet),
    % Ensure that no two packages provide the same virtual.
    packages_check_virtuals(PackageSet, _),
    % Unify all packages against the requiring specs.
    package_deps_resolve(AllDepends, PackageSet, ResolvedPackages).

% Get the deptree for a spec.
spec_deptree_against_exist([Spec, Context], ResolvedPackages) :-
    % Find all active dependencies of the top-level package. The top-level
    % spec is already fully specified, so don't backtrack over it.
    spec_depends(Spec, AllSpecDepends),
    spec_active_dependencies(Spec, AllSpecDepends, Depends), !,
    % Find all dependencies.
    specs_depends(Depends, RecursiveDepends),
    % Put the two together.
    append(Depends, RecursiveDepends, AllDepends),
    % Get the packages we depend on.
    package_deps_packages(AllDepends, Packages),
    % Uniquify packages.
    list_to_set(Packages, PackageSet),
    % Ensure that no two packages provide the same virtual.
    packages_check_virtuals(PackageSet, _),
    % Unify all packages against the requiring specs.
    package_deps_resolve(AllDepends, PackageSet, ResolvedPackages).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

:- include("knowledge_base").

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spec fallbacks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get the default version of a spec.
spec_version(Spec, Version) :-
    spec_package(Spec, Package),
    package_version_default(Package, Version),
    !.
spec_variants(Spec, []) :-
    spec_package(Spec, _),
    !.
spec_nvariants(Spec, []) :-
    spec_package(Spec, _),
    !.
spec_dependencies(Spec, []) :-
    spec_package(Spec, _),
    !.

virtual_package_version(VirtualPackage, ver_any, _, _) :-
    virtual_package(VirtualPackage),
    !.

% Use the first-listed version of the package as the default.
package_version_default(Package, Version) :-
    package_version(Package, Version, _, _),
    !.

% By default, any version for a package dependency is OK.
package_dep_version(PackageDepend, ver_any, ver_any) :-
    package_depends_on(_, PackageDepend),
    !.
% By default, package dependency variants are empty.
package_dep_variants(PackageDepend, []) :-
    package_depends_on(_, PackageDepend),
    !.
package_dep_nvariants(PackageDepend, []) :-
    package_depends_on(_, PackageDepend),
    !.
% By default, package dependencies are unconditional.
package_dep_when(_, PackageDepend) :-
    package_depends_on(_, PackageDepend),
    !.
% By default, dependencies are build and link.
package_dep_deptypes(PackageDepend, [build, link]) :-
    package_depends_on(_, PackageDepend),
    !.
