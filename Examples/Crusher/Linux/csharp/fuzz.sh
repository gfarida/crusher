#!/bin/bash

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ./fuzz.sh <path/to/fuzz_manager>"
    exit 1
fi

FUZZ_MAN=$1

$FUZZ_MAN --start 10 -F -i in -o out -I java --instrumented-class test -- ./bin-instr:./target/commons-math3-3.6.1-instr.jar __DATA__

