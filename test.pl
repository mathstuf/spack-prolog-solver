#!/usr/bin/swipl -s

:- include("depsolve").

expect(Computed, Expected) :-
    subtract(Computed, Expected, []),
    subtract(Expected, Computed, []);
    print_message(error, Computed),
    print_message(error, Expected).

test_deptree(Spec, Expected) :-
    spec_deptree(Spec, Computed),
    !,
    expect(Computed, Expected).

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
