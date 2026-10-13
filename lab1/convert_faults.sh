#!/bin/sh
#
# Usage: ./convert_faults.sh <fault_list> <line_number>
#
# Prints the Questa force command for the fault at <line_number>.
# The DUT instance in the testbench is u_<DESIGN> (DESIGN defaults to ex1,
# so the instance is u_ex1); set DUT to override it.

infile=$1
line=$2
DESIGN=${DESIGN:-ex1}
DUT=${DUT:-u_${DESIGN}}

head -$line $infile | tail -1 | awk -v dut="${DUT}" '
/^sa[01]/ {
	path = $3
	sub(/^\//, "", path)              # TestMAX paths start with "/"
	print "force -freeze /" dut "/" path, ($1 == "sa0" ? "0" : "1")
}
'
