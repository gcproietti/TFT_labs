#!/bin/bash
#
# tmax.sh - run a TestMAX command file in batch mode, and check the log
#
# Usage (from ~/lab4):   ./tmax.sh <command_file.tcl>
#   e.g.  ./tmax.sh atpg_b06_los.tcl
#
# - TestMAX runs inside run/ (created if needed): every file it writes ends up in
#   ~/lab4/run, and the command file reads the sources as ../<file>.
# - tmax -shell is the non-GUI mode of the tool. Standard input comes from
#   /dev/null: if the command file stops at an error, TestMAX exits instead of
#   waiting at its prompt.
# - The transcript is shown on the screen AND saved in run/<name>.log.
# - At the end the script tells you whether the log contains errors and prints
#   the first one: fix that one before anything else.

cd "$(dirname "${0}")"
script=${1}
if [ -z "${script}" ]; then
	echo "Usage: $0 <command_file.tcl>"
	exit 1
fi
[ ! -f "${script}" ] && echo "Command file \"${script}\" not found in $(pwd)!" && exit 1
script=$(readlink -f "${script}")
log="$(pwd)/run/$(basename "${script}" .tcl).log"

command -v tmax > /dev/null || { echo "TestMAX (tmax) not found in PATH: did you source the setup of the Synopsys tools?"; exit 1; }

mkdir -p run && cd run
tmax -shell "${script}" < /dev/null 2>&1 | tee "${log}"

echo
echo "================================================================"
echo "Log saved in run/$(basename "${log}")"
n_err=$(grep -c "^ *Error" "${log}")
if [ "${n_err}" -eq 0 ]; then
	echo "No errors in the log."
else
	echo "${n_err} error(s) in the log. The FIRST one (fix it before anything else):"
	grep -n -m1 -B3 "^ *Error" "${log}"
fi
echo "================================================================"
