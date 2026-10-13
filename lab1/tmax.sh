#!/bin/sh
#
# Usage (from the lab1 folder):
#   ./tmax.sh                        runs tmax_script.tcl (ex1)
#   ./tmax.sh tmax_script_mux.tcl    runs another TestMAX script

# Move to the run directory
mkdir -p run && cd run

# Invoke TestMAX and run the TCL script
tmax -shell ../${1:-tmax_script.tcl}
