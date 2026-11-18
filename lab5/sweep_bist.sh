#!/bin/bash
#
# sweep_bist.sh - fault coverage of a self-test for several test lengths
#
# Usage (from ~/lab5):
#   ./sweep_bist.sh func <command file> "<STOP values>"     e.g. ./sweep_bist.sh func fsim_b10_func.tcl "100 1000"
#   ./sweep_bist.sh scan <command file> "<N values>"        e.g. ./sweep_bist.sh scan fsim_b10_scan.tcl "10 50"
# The other settings come from the same variables as func_bist.sh / scan_bist.sh
# (SEED, PS, CAPTURE, ...), e.g.  PS=1 ./sweep_bist.sh func fsim_b10_func.tcl "1000".
#
# For each value: the self-test with DUMP=1 (the eVCD in run/ has always the same name),
# then ./tmax.sh <command file>, i.e. YOUR command file, unchanged. Each TestMAX log is
# kept as run/sweep/<file>_<value>.log. Table on the screen and in run/sweep/<file>.txt.
# Validate it: the row of the value that you ran by hand must coincide with your run.

cd "$(dirname "${0}")"
bench=${1}; cmd=${2}; values=${3}
case "${bench}" in
	func) sim=./func_bist.sh; var=STOP ;;
	scan) sim=./scan_bist.sh; var=N ;;
	*) echo "Usage: $0 func|scan <command file> \"<values>\""; exit 1 ;;
esac
[ ! -f "${cmd}" ] && echo "Command file \"${cmd}\" not found!" && exit 1
[ -z "${values}" ] && echo "No values given" && exit 1
name=$(basename "${cmd}" .tcl)
mkdir -p run/sweep
table=run/sweep/${name}.txt
settings="SEED=${SEED:-1234} PS=${PS:-0}"; [ "${bench}" = scan ] && settings="${settings} CAPTURE=${CAPTURE:-1}"
{
echo "# ${bench} self-test, ${settings}, command file ${cmd}"
printf "%-7s %-8s %-9s %s\n" "${var}" "cycles" "signature" "summary.sh: label #faults DT PT UD AU ND (NC/NO) patterns test_cov fault_cov"
} | tee "${table}"
for v in ${values}; do
	out=$(env ${var}=${v} DUMP=1 ${sim})
	if echo "${out}" | grep -q "Error"; then echo "${out}"; exit 1; fi
	cyc=$(echo "${out}" | sed -n -e 's/.*session of \([0-9]*\) clock cycles.*/\1/p' -e 's/.*number of test cycles = //p')
	sig=$(echo "${out}" | sed -n 's/.*signature = //p')
	./tmax.sh "${cmd}" > /dev/null
	mv run/${name}.log run/sweep/${name}_${v}.log
	sum=$(./summary.sh run/sweep/${name}_${v}.log "${var}=${v}")
	printf "%-7s %-8s %-9s %s\n" "${v}" "${cyc}" "${sig}" "${sum}" | tee -a "${table}"
done
