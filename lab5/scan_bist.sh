#!/bin/sh
#
# scan_bist.sh - b10 with full scan and its self-test per scan (Part C): Questa, batch mode
#
# Usage (from ~/lab5):
#   ./scan_bist.sh                     50 patterns, 1 capture cycle, LFSR seed 1234, no phase shifter
#   N=200 ./scan_bist.sh               number of patterns
#   CAPTURE=2 ./scan_bist.sh           capture cycles per pattern (2 for transition faults)
#   SEED=4321 ./scan_bist.sh           seed of the LFSR
#   PS=1 ./scan_bist.sh                phase shifter between the LFSR and the circuit
#   GOLDEN=1A2B3C4D ./scan_bist.sh     golden signature (hex) for the GO/NOGO comparison
#   DUMP=1 ./scan_bist.sh              also writes run/<design>_scan_bist.vcd (eVCD of the circuit ports, for TestMAX)
#   INJECT=1 ./scan_bist.sh            also sources run/inject_fault.tcl (one force command, as in Lab 1)
#   DESIGN=b10 ./scan_bist.sh          the circuit: <design>_scan.v and rtl/<design>_scan_bist_testbench.vhd
# Printed at the end: number of test cycles, signature, golden signature, GO/NOGO.
# Transcript: run/scan_bist.log. HDL compiled into the library run/scan_<design>
# (again only when a source changes).

cd "$(dirname "${0}")"
DESIGN=${DESIGN:-b10}
N=${N:-50}; CAPTURE=${CAPTURE:-1}; SEED=${SEED:-1234}; PS=${PS:-0}; GOLDEN=${GOLDEN:-00000000}; MISR_MODE=${MISR_MODE:-1}
export INJECT=${INJECT:-0}
export DUMP=${DUMP:-0}
export DESIGN
lib=scan_${DESIGN}

mkdir -p run && cd run
if [ ! -f ${lib}/_info ] || [ -n "$(find ../rtl ../${DESIGN}_scan.v ../pdt2002_sim.vhd -newer ${lib}/_info 2>/dev/null)" ]; then
	rm -rf ${lib}; vlib ${lib} > /dev/null
	{
	vcom -2008 -quiet -work ${lib} -suppress 1141 ../pdt2002_sim.vhd
	vlog -quiet -work ${lib} ../${DESIGN}_scan.v
	for f in lfsr tpg misr tps_ctrl stumps1 ${DESIGN}_scan_bist_testbench; do
		vcom -2008 -quiet -work ${lib} ../rtl/${f}.vhd
	done
	} > scan_compile.log 2>&1
	if grep -q "\*\* Error" scan_compile.log; then
		echo "Compilation errors (run/scan_compile.log):"; grep -m5 "\*\* Error" scan_compile.log; rm -rf ${lib}; exit 1
	fi
fi

vsim -c -voptargs="+acc" -GN_PATTERNS=${N} -GCAPTURE=${CAPTURE} -GLFSR_SEED=${SEED} -GPHASE_SHIFTER=${PS} -GMISR_MODE=${MISR_MODE} \
	-GGOLDEN_SIGNATURE=X\"${GOLDEN}\" ${lib}.tb_${DESIGN}_scan_bist -do ../scan_bist.tcl < /dev/null > scan_bist.log 2>&1
grep -E "BIST|\*\* (Error|Fatal|Failure)" scan_bist.log | grep -v "^# \*\* Note: (vsim" | sed -e 's/^# //' -e 's/\*\* Note: //'
