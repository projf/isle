#!/bin/sh

# Isle.Computer - Summarise cocotb Test Results
# Copyright Will Green and Isle Contributors
# SPDX-License-Identifier: MIT

fail=0

echo ""
echo "==== Test Summary =========================="

for dut in "$@"; do
    f="results_${dut}.xml"
    if [ ! -f "$f" ]; then
        printf "  %-16s: FAIL (no results file)\n" "$dut"
        fail=1
    elif grep -q '<failure' "$f"; then
        printf "  %-16s: FAIL\n" "$dut"
        fail=1
    else
        printf "  %-16s: PASS\n" "$dut"
    fi
done

echo "============================================"

exit $fail
