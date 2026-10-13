#!/bin/bash
#
# fault_injection.sh - serial stuck-at fault-injection campaign for Lab 1
#
# Usage (from any directory):
#   ./fault_injection.sh <fault_list> [first_line] [last_line]
#   DESIGN=mux ./fault_injection.sh <fault_list>     (other circuit; default ex1)
#
#   <fault_list>  TestMAX fault list (e.g. run/fault_list_stuckat_full.txt)
#   first_line    optional: first line of the list to process (default 1)
#   last_line     optional: last line of the list to process (default: end)
#
# For every fault (every line starting with sa0/sa1) the script:
#   1. converts the fault into a Questa force command (convert_faults.sh)
#      and writes it to run/inject_fault.tcl
#   2. runs the simulation with INJECT=1 (simulation.sh)
#   3. compares, pattern by pattern, the primary outputs (POs) written in
#      run/monitor.txt with the golden ones in run/<DESIGN>_monitor_golden.txt
#
# Output:
#   run/<DESIGN>_fault_dictionary.txt  one line per fault: faulty POs for each pattern,
#                             patterns that detect the fault, verdict
#   on screen                 the same lines + a summary with fault coverage
#
# Verdicts:
#   DETECTED      at least one PO differs at at least one strobe
#   NOT_DETECTED  the POs are identical to the golden ones at every strobe
#   INJ_FAILED    the simulation reported an error or did not produce a
#                 complete monitor.txt: the result is NOT valid
#
# Prerequisite: run the fault-free simulation once and save
#               run/monitor.txt as run/<DESIGN>_monitor_golden.txt

cd "$(dirname "${0}")"
root_dir=${PWD}
cd - &>/dev/null

export DESIGN=${DESIGN:-ex1}   # used also by simulation.sh and convert_faults.sh
run_dir="${root_dir}/run"
tmax_fault_list=${1}
golden_result="${run_dir}/${DESIGN}_monitor_golden.txt"
dictionary="${run_dir}/${DESIGN}_fault_dictionary.txt"

# ------------------------------------------------------------------ checks
if [ -z "${tmax_fault_list}" ]; then
	echo "Usage: $0 <fault_list> [first_line] [last_line]"
	exit 1
fi
# accept both absolute paths and paths relative to the current directory
tmax_fault_list=$(readlink -f "${tmax_fault_list}")

[ ! -f "${tmax_fault_list}" ] &&\
	echo "Fault list \"${1}\" not found!" &&\
	exit 1

[ ! -f "${golden_result}" ] &&\
	echo "Golden monitor file \"run/$(basename ${golden_result})\" does not exist!" &&\
	echo "Run the fault-free simulation first and copy run/monitor.txt to run/${DESIGN}_monitor_golden.txt" &&\
	exit 1

total_lines=$(wc -l < "${tmax_fault_list}")
first=${2:-1}
last=${3:-${total_lines}}

# golden POs, one line per pattern (e.g. "POs:10")
golden_pos=$(grep -o "POs:[01XUZ-]*" "${golden_result}")
n_patterns=$(echo "${golden_pos}" | wc -l)

# ------------------------------------------------------------------ header
{
	echo "# Fault dictionary - design: ${DESIGN} - list: $(basename ${tmax_fault_list})"
	echo "# Golden POs per pattern (P0..P$((n_patterns-1))): $(echo ${golden_pos} | sed 's/POs://g')"
	echo "# sa  code  site                     faulty POs per pattern     detected_by   verdict"
} > "${dictionary}"

n_total=0; n_det=0; n_undet=0; n_fail=0

# ------------------------------------------------------------------ loop
for (( i=first; i<=last; ++i )); do

	line=$(sed -n "${i}p" "${tmax_fault_list}")

	# skip blank lines and comments: only sa0/sa1 lines are faults
	echo "${line}" | grep -qE "^sa[01][[:space:]]" || continue

	sa=$(echo "${line}"   | awk '{print $1}')
	code=$(echo "${line}" | awk '{print $2}')
	site=$(echo "${line}" | awk '{print $3}')

	# 1. CONVERT TO QUESTA FORCE AND WRITE IT TO run/inject_fault.tcl
	#    (multiple slashes, if any, are collapsed into one)
	sh "${root_dir}/convert_faults.sh" "${tmax_fault_list}" "${i}" \
		| sed 's#//*#/#g' > "${run_dir}/inject_fault.tcl"

	# 2. LAUNCH THE SIMULATION WITH THE FAULT INJECTED
	#    the old monitor.txt is removed, so that a failed run cannot
	#    silently reuse the results of the previous fault
	rm -f "${run_dir}/monitor.txt"
	(
		cd "${root_dir}"
		export INJECT=1
		# stdin from /dev/null: if the simulator ever stops at its prompt,
		# it reads end-of-file instead of waiting for the keyboard;
		# timeout: a run that does not finish in 5 minutes is killed
		timeout 300 sh ./simulation.sh > "${run_dir}/sim_fault.log" 2>&1 < /dev/null
	)

	n_total=$((n_total+1))

	# 3. COMPARE run/monitor.txt WITH run/monitor_golden.txt
	faulty_pos=""
	[ -f "${run_dir}/monitor.txt" ] &&\
		faulty_pos=$(grep -o "POs:[01XUZ-]*" "${run_dir}/monitor.txt")
	n_faulty=0
	[ -n "${faulty_pos}" ] && n_faulty=$(echo "${faulty_pos}" | wc -l)

	if grep -qE "\*\* (Error|Fatal)" "${run_dir}/sim_fault.log" \
	   || [ "${n_faulty}" -ne "${n_patterns}" ]; then
		verdict="INJ_FAILED"
		detected_by="-"
		pos_list="see run/sim_fault.log"
		n_fail=$((n_fail+1))
		cp "${run_dir}/sim_fault.log" "${run_dir}/sim_fault_line${i}.log"
	else
		# pattern-by-pattern comparison of the POs
		detected_by=$(paste -d' ' <(echo "${golden_pos}") <(echo "${faulty_pos}") \
			| awk '$1 != $2 { printf "%s%d", (n++ ? "," : ""), NR-1 }')
		pos_list=$(echo ${faulty_pos} | sed 's/POs://g')
		if [ -n "${detected_by}" ]; then
			verdict="DETECTED"
			n_det=$((n_det+1))
		else
			verdict="NOT_DETECTED"
			detected_by="-"
			n_undet=$((n_undet+1))
		fi
	fi

	result=$(printf "%-4s %-4s %-24s %-26s %-13s %s" \
		"${sa}" "${code}" "${site}" "${pos_list}" "${detected_by}" "${verdict}")
	echo "${result}"
	echo "${result}" >> "${dictionary}"

done

# ------------------------------------------------------------------ summary
valid=$((n_det+n_undet))
coverage="n.a."
[ ${valid} -gt 0 ] && coverage=$(awk -v d=${n_det} -v t=${valid} 'BEGIN{printf "%.2f%%", 100*d/t}')

{
	echo "#"
	echo "# Faults simulated : ${n_total}"
	echo "# Detected         : ${n_det}"
	echo "# Not detected     : ${n_undet}"
	echo "# Injection failed : ${n_fail}   (excluded from the coverage: fix them and rerun)"
	echo "# Fault coverage   : ${coverage}   (= detected / (detected + not detected))"
} | tee -a "${dictionary}"

echo "Fault dictionary written to run/$(basename ${dictionary})"

exit 0
