#!/bin/sh
#
# Usage (from the lab1 folder):
#   ./simulation.sh                            simulates ex1 (default)
#   DESIGN=mux ./simulation.sh                 simulates the mux circuit
#   NETLIST=../ex1_synth.vhd ./simulation.sh   simulates another netlist of ex1
#   INJECT=1 ./simulation.sh                   also sources run/inject_fault.tcl
#
# Files used for DESIGN=<d>:  <d>_structural.vhd (unless NETLIST is set),
#                             <d>_testbench.vhd (entity tb_<d>), <d>_patterns.txt

DESIGN=${DESIGN:-ex1}
NETLIST=${NETLIST:-../${DESIGN}_structural.vhd}

# Move to the run directory
mkdir -p run && cd run

# Build the files
vlog ../pdt2002.v
vcom -2008 -suppress 1141 ${NETLIST} ../${DESIGN}_testbench.vhd

[ -z "${INJECT}" ] && export INJECT=0

# Invoke QuestaSim shell and run the TCL script
vsim -c -vopt -voptargs="+acc" -debugDB work.tb_${DESIGN} -do ../simulation_script.tcl -wlf sim.wlf
