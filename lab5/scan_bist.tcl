# Questa commands for scan_bist.sh (they run inside run/)

# eVCD of the ports of the circuit, for the fault simulation in TestMAX
# (-force_direction: use the declared direction of the ports)
if { $env(DUMP) == 1 } {
	vcd dumpports -file $env(DESIGN)_scan_bist.vcd -force_direction /tb_$env(DESIGN)_scan_bist/u_$env(DESIGN)/*
}

# Fault injection, as in Lab 1: run/inject_fault.tcl contains one force command, e.g.
#   force -freeze /tb_b10_scan_bist/u_b10/n_12 0
if { $env(INJECT) == 1 } {
	if { [catch { source inject_fault.tcl } msg] } {
		puts "BIST: ** Error: fault injection failed: $msg"
		quit -f
	}
	puts "BIST: injected [string trim [exec cat inject_fault.tcl]]"
}

run -all
quit -f
