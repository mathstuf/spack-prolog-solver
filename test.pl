#!/usr/bin/swipl -s

:- include("depsolve").

expect(Name, Computed, Expected) :-
    subtract(Computed, Expected, []),
    subtract(Expected, Computed, []);
    print_message(error, Name),
    print_message(error, Computed),
    print_message(error, Expected).

test_deptree(Name, Spec, Expected) :-
    spec_deptree(Spec, Computed),
    !,
    expect(Name, Computed, Expected).

:- initialization(main).

test :-
    test_deptree("cmake~qt",
        cmake_0,
        [
            [curl, [7, 49, 1], [], []],
            [zlib, [1, 2, 8], [], []]
        ]),
    test_deptree("cmake+qt",
        cmake_1,
        [
            [curl, [7, 49, 1], [], []],
            [qt, [4, 8, 6], [], []],
            [zlib, [1, 2, 8], [], []]
        ]).

main :-
    test,
    halt.
