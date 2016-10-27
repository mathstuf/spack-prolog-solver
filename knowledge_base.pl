%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% virtual package test
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
virtual_package(virtual).
virtual_package_package(virtual, virtual_impl_a).
virtual_package_package(virtual, virtual_impl_b).

package(virtual_impl_a).
package_version(virtual_impl_a, [1, 0, 0], "https://example.org/a.tar.gz", "0123456789").

package(virtual_impl_b).
package_version(virtual_impl_b, [2, 0, 0], "https://example.org/b.tar.gz", "0123456789").
package_version(virtual_impl_b, [3, 0, 0], "https://example.org/b.tar.gz", "0123456789").

package_dep_package(req_virtual_virtual_0, virtual).

package(req_virtual).
package_version(req_virtual, [1], "https://example.org/virt.tar.gz", "0123456789").
package_depends_on(req_virtual, req_virtual_virtual_0).

spec_package(req_virtual_0, req_virtual).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% deptype test tree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% dtlink1
package(dtlink1).
package_version(dtlink1, [1], "", "").

package_dep_package(dtlink1_dtlink3, dtlink3).

package_dep_package(dtlink1_dtbuild1, dtbuild1).
package_dep_nvariants(dtlink1_dtbuild1, ["x"]) :- !.
package_dep_deptypes(dtlink1_dtbuild1, [build]) :- !.

package_depends_on(dtlink1, dtlink1_dtlink3).
package_depends_on(dtlink1, dtlink1_dtbuild1).

% dtlink2
package(dtlink2).
package_version(dtlink2, [1], "", "").

% dtlink3
package(dtlink3).
package_version(dtlink3, [1], "", "").

package_dep_package(dtlink3_dtlink4, dtlink4).

package_dep_package(dtlink3_dtbuild2, dtbuild2).
package_dep_deptypes(dtlink3_dtbuild2, [build]) :- !.

package_depends_on(dtlink3, dtlink3_dtlink4).
package_depends_on(dtlink3, dtlink3_dtbuild2).

% dtlink4
package(dtlink4).
package_version(dtlink4, [1], "", "").

% dtlink6
package(dtlink6).
package_version(dtlink6, [1], "", "").

package_dep_package(dtlink6_dtbuild1, dtbuild1).
package_dep_variants(dtlink6_dtbuild1, ["x"]) :- !.
package_dep_deptypes(dtlink6_dtbuild1, [build]) :- !.

package_depends_on(dtlink6, dtlink6_dtbuild1).

% dtbuild1
package(dtbuild1).
package_version(dtbuild1, [1], "", "").
package_variant(dtbuild1, "x").

package_dep_package(dtbuild1_dtbuild2, dtbuild2).
package_dep_deptypes(dtbuild1_dtbuild2, [build]) :- !.

package_dep_package(dtbuild1_dtlink2, dtlink2).

package_dep_package(dtbuild1_dtrun2, dtrun2).
package_dep_deptypes(dtbuild1_dtrun2, [run]) :- !.

package_depends_on(dtbuild1, dtbuild1_dtbuild2).
package_depends_on(dtbuild1, dtbuild1_dtlink2).
package_depends_on(dtbuild1, dtbuild1_dtrun2).

% dtbuild2
package(dtbuild2).
package_version(dtbuild2, [1], "", "").

% dtrun2
package(dtrun2).
package_version(dtrun2, [1], "", "").

% sepbuild
package(dtsepbuild).
package_version(dtsepbuild, [1], "", "").

package_dep_package(dtsepbuild_dtlink1, dtlink1).

package_dep_package(dtsepbuild_dtlink4, dtlink4).

package_depends_on(dtsepbuild, dtsepbuild_dtlink1).
package_depends_on(dtsepbuild, dtsepbuild_dtlink4).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% specs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

spec_package(sep, dtsepbuild).
spec_package(link1, dtlink1).
spec_package(link2, dtlink2).
spec_package(link3, dtlink3).
spec_package(link4, dtlink4).
spec_package(link6, dtlink6).
spec_package(build1, dtbuild1).
spec_package(build2, dtbuild2).
spec_package(run2, dtrun2).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Package declarations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The zlib package.
package(zlib).
package_version(zlib, [1, 2, 8], "http://curl.haxx.se", "abcdef").

% The curl package.
package(curl).
package_version(curl, [7, 49, 1], "http://curl.haxx.se", "abcdef").
package_version(curl, [7, 49, 2], "http://curl.haxx.se", "abcdef").
package_version(curl, [7, 50, 0], "http://curl.haxx.se", "abcdef").
package_version_default(curl, [7, 49, 1]) :- !.

% curl depends on zlib.
package_dep_package(curl_zlib_0, zlib).

package_depends_on(curl, curl_zlib_0).

% The qt package.
package(qt).
package_version(qt, [4, 8, 6], "http://curl.haxx.se", "abcdef").
package_version_default(qt, [4, 8, 6]) :- !.

% The cmake package.
package(cmake).
package_version(cmake, [3, 6, 0], "https://cmake.org", "abcdef").
package_version_default(cmake, [3, 6, 0]) :- !.
package_variant(cmake, "qt").

% CMake depends on curl.
package_dep_package(cmake_curl_0, curl).

% CMake depends on qt if the "qt" variant is enabled.
package_dep_package(cmake_qt_0, qt).
package_dep_when(Spec, cmake_qt_0) :-
    !,
    spec_variant_enabled(Spec, "qt").

% CMake dependencies.
package_depends_on(cmake, cmake_curl_0).
package_depends_on(cmake, cmake_qt_0).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Spec declarations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% A test spec.
spec_package(cmake_0, cmake) :- !.
spec_version(cmake_0, Version) :-
    package_find_best_version(cmake, [3, 6], Version),
    !.

spec_package(cmake_1, cmake) :- !.
spec_version(cmake_1, Version) :-
    package_find_best_version(cmake, [3, 6], Version),
    !.
spec_variants(cmake_1, ["qt"]) :- !.

spec_package(curl_1, curl) :- !.
