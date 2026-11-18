# Questa commands for func_bist.sh (they run inside run/)

# eVCD of the ports of b10 (the circuit under test, inside the wrapper): the patterns that
# the self-test applies, with the responses of the fault-free circuit, for TestMAX.
# -force_direction: b10 is inside the wrapper and its outputs drive signals of the wrapper;
# without it Questa would dump them as inputs, and TestMAX would have no output to observe.
if { $env(DUMP) == 1 } {
	vcd dumpports -file b10_func_bist.vcd -force_direction /tb_b10_wrapper/u_b10_wrapper/u_b10/*
}

# Fault injection, as in Lab 1: run/inject_fault.tcl contains one force command, e.g.
#   force -freeze /tb_b10_wrapper/u_b10_wrapper/u_b10/n66 1
# If the command fails (e.g. a wrong path), catch reports the error and ends the simulation.
if { $env(INJECT) == 1 } {
	if { [catch { source inject_fault.tcl } msg] } {
		puts "BIST: ** Error: fault injection failed: $msg"
		quit -f
	}
	puts "BIST: injected [string trim [exec cat inject_fault.tcl]]"
}

run -all

echo "BIST: signature = [examine -radix hex /tb_b10_wrapper/u_b10_wrapper/lbist_i/signature]"
quit -f
