#!/bin/bash
#
# inject_faults.sh - inject stuck-at faults one at a time and print the GO/NOGO result
#
# Usage (from ~/lab5):
#   ./inject_faults.sh func <fault list>      b10 with the functional self-test (func_bist.sh)
#   ./inject_faults.sh scan <fault list>      b10 with the self-test per scan (scan_bist.sh)
# Each line of the fault list:  <sa0|sa1> <class> <pin>,  as in the files of write_faults,
# e.g.   sa1  DS  U91/O
# Only output pins of cells (<cell>/O, <cell>/Q) are injected: one force command on the
# output pin of the cell (in run/inject_fault.tcl, as in Lab 1) fixes the value of the whole
# net that the pin drives, i.e. a stem fault. The other settings come from the same
# variables as the simulation script; GOLDEN must be the signature of the fault-free circuit
# WITH THE SAME SETTINGS.

cd "$(dirname "${0}")"
bench=${1}; list=${2}
case "${bench}" in
	func) sim=./func_bist.sh; netlist=b10.v;      dut=/tb_b10_wrapper/u_b10_wrapper/u_b10 ;;
	scan) sim=./scan_bist.sh; netlist=b10_scan.v; dut=/tb_b10_scan_bist/u_b10 ;;
	*) echo "Usage: $0 func|scan <fault list>"; exit 1 ;;
esac
[ ! -f "${list}" ] && echo "Fault list \"${list}\" not found!" && exit 1
[ -z "${GOLDEN}" ] && echo "Warning: GOLDEN not set, the default golden signature of the script is used"
mkdir -p run

printf "%-4s %-6s %-24s %-10s %s\n" "sa" "class" "pin" "signature" "result"
grep -v '^\s*#' "${list}" | while read -r sa cls pin rest; do
	[ -z "${pin}" ] && continue
	cell=${pin%/*}; port=${pin##*/}
	case "${port}" in O|Q) ;; *) echo "${pin}: not an output pin of a cell, skipped"; continue ;; esac
	# the cell must exist in the netlist (escaped names such as \stato_reg[0] included)
	if ! grep -qF -- " ${cell} " "${netlist}" && ! grep -qF -- " ${cell}(" "${netlist}"; then
		echo "${pin}: cell not found in ${netlist}, skipped"; continue
	fi
	# Questa path of the pin: an escaped name ends with a space (\stato_reg[0] /Q)
	case "${cell}" in \\*) path="{${dut}/${cell} /${port}}" ;; *) path="{${dut}/${cell}/${port}}" ;; esac
	echo "force -freeze ${path} ${sa#sa}" > run/inject_fault.tcl
	out=$(INJECT=1 ${sim})
	err=$(echo "${out}" | grep -m1 "Error")
	sig=$(echo "${out}" | sed -n 's/.*signature = //p')
	res=$(echo "${out}" | sed -n 's/.*result = //p')
	printf "%-4s %-6s %-24s %-10s %s %s\n" "${sa}" "${cls}" "${pin}" "${sig}" "${res}" "${err}"
done
