#!/bin/sh

# Isle.Computer - Chapter 1: Verilator Lint Script
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

# check for Verilator 5
vlt_version=$(verilator --version | cut -d' ' -f2 | cut -d'.' -f1)
if [ $vlt_version -lt 5 ]; then
    echo "ERROR: Lint not run - requires Verilator 5 or later."
    exit 1
fi

LINT_DIR=`dirname $0`
HW_DIR="../../${LINT_DIR}"  # hardware source directory

verilator --lint-only -Wall \
    -I${HW_DIR} \
    -I${HW_DIR}/gfx \
    ch01_square.v

verilator --lint-only -Wall \
    -I${HW_DIR} \
    -I${HW_DIR}/gfx \
    ch01_pattern.v
