log -r /*




### Examples of faults

#stuck-at-0
#force -freeze /u_ex1/net2 0

#stuck-at-1
#force -freeze /u_ex1/net2 1

########################

# You can write commands into a separate file 
# (this permits you to automatize the fault injection campaign)
#
# source inject_fault.tcl

if { $env(INJECT) == 1 } {
	# If a command in inject_fault.tcl fails (e.g. a wrong path in a force),
	# Questa would stop the script and wait at its prompt: the simulation
	# would hang. catch reports the error and ends the simulation instead.
	if { [catch { source inject_fault.tcl } msg] } {
		puts "** Error: fault injection failed: $msg"
		quit -f
	}
}

run -all

#noforce *

quit
