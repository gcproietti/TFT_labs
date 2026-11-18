#!/bin/sh
#
# func_bist.sh - b10 with its functional self-test (Part B): Questa, batch mode
#
# Usage (from ~/lab5):
#   ./func_bist.sh                     session of 1000 clock cycles, LFSR and MISR seeds 1234
#   STOP=500 ./func_bist.sh            session length (COUNTER_STOP)
#   SEED=4321 ./func_bist.sh           seed of the LFSR
#   PS=1 ./func_bist.sh                phase shifter between the LFSR and the inputs of b10
#   GOLDEN=1A2B3C4D ./func_bist.sh     golden signature (hex) for the GO/NOGO comparison
#   DUMP=1 ./func_bist.sh              also writes run/b10_func_bist.vcd (eVCD of the b10 ports, for TestMAX)
#   INJECT=1 ./func_bist.sh            also sources run/inject_fault.tcl (one force command, as in Lab 1)
#   GUI=1 ./func_bist.sh               Questa GUI with the waveforms of func_wave.do
# Printed at the end: length of the session, signature, golden signature, GO/NOGO.
# Transcript: run/func_bist.log. HDL compiled into the library run/func (again only
# when a source changes).

cd "$(dirname "${0}")"
STOP=${STOP:-1000}; SEED=${SEED:-1234}; PS=${PS:-0}; GOLDEN=${GOLDEN:-A88DEC5B}
export INJECT=${INJECT:-0}
export DUMP=${DUMP:-0}

mkdir -p run && cd run
if [ ! -f func/_info ] || [ -n "$(find ../rtl ../b10.v ../pdt2002_sim.vhd -newer func/_info 2>/dev/null)" ]; then
	rm -rf func; vlib func > /dev/null
	{
	vcom -2008 -quiet -work func -suppress 1141 ../pdt2002_sim.vhd
	vlog -quiet -work func ../b10.v
	for f in lfsr tpg misr ode mux2to1_n test_counter lbist_state_machine lbist_controller lbist b10_wrapper b10_wrapper_testbench; do
		vcom -2008 -quiet -work func ../rtl/${f}.vhd
	done
	} > func_compile.log 2>&1
	if grep -q "\*\* Error" func_compile.log; then
		echo "Compilation errors (run/func_compile.log):"; grep -m5 "\*\* Error" func_compile.log; rm -rf func; exit 1
	fi
fi

if [ -n "${GUI}" ]; then
	vsim -voptargs="+acc" -GCOUNTER_STOP=${STOP} -GLFSR_SEED=${SEED} -GPHASE_SHIFTER=${PS} -GGOLDEN_SIGNATURE=X\"${GOLDEN}\" \
		func.tb_b10_wrapper -do ../func_wave.do -do ../func_bist.tcl -wlf func.wlf
else
	# -onfinish stop: when the testbench stops, Questa goes back to func_bist.tcl
	vsim -c -onfinish stop -voptargs="+acc" -GCOUNTER_STOP=${STOP} -GLFSR_SEED=${SEED} -GPHASE_SHIFTER=${PS} -GGOLDEN_SIGNATURE=X\"${GOLDEN}\" \
		func.tb_b10_wrapper -do ../func_bist.tcl < /dev/null > func_bist.log 2>&1
	grep -E "BIST|\*\* (Error|Fatal|Failure)" func_bist.log | grep -v "^# \*\* Note: (vsim" | sed -e 's/^# //' -e 's/\*\* Note: //'
fi
