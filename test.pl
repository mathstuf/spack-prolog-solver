#!/usr/bin/swipl -s

:- include("depsolve").

test_deptree(Spec, Expected) :-
    spec_deptree(Spec, Computed),
    !,
    subtract(Computed, Expected, []),
    subtract(Expected, Computed, []).

:- initialization(main).

main :-
    test_deptree(cmake_0,
        [
            [curl, [7, 49, 1], [], []],
            [zlib, [1, 2, 8], [], []]
        ]),
    test_deptree(cmake_1,
        [
            [curl, [7, 49, 1], [], []],
            [qt, [4, 8, 6], [], []],
            [zlib, [1, 2, 8], [], []]
        ]),
    halt.
