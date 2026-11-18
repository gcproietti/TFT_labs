#!/bin/bash
#
# dc.sh - run a Design Compiler command file in batch mode, and check the log
#
# Usage (from ~/lab3):   ./dc.sh <command_file.tcl>
#   e.g.  ./dc.sh b10_scan_insertion.tcl
#
# - Design Compiler runs inside run/ (created if needed): the netlist and the
#   STIL procedure file it writes end up in ~/lab3/run, next to the TestMAX
#   outputs, and the command file reads the sources as ../<file>.
# - The transcript is shown on the screen AND saved in run/<name>.log.
# - At the end the script tells you whether the log contains errors and prints
#   the first one, as tmax.sh does.
# The executable is dc_shell (dc_shell-xg-t in older installations: both are tried).

cd "$(dirname "${0}")"
script=${1}
if [ -z "${script}" ]; then
	echo "Usage: $0 <command_file.tcl>"
	exit 1
fi
[ ! -f "${script}" ] && echo "Command file \"${script}\" not found in $(pwd)!" && exit 1
script=$(readlink -f "${script}")
log="$(pwd)/run/$(basename "${script}" .tcl).log"

dc=$(command -v dc_shell || command -v dc_shell-xg-t)
[ -z "${dc}" ] && echo "Design Compiler (dc_shell) not found in PATH: did you source the setup of the Synopsys tools?" && exit 1

mkdir -p run && cd run
# stdin from /dev/null: if the command file stops at an error, dc_shell exits
# instead of waiting at its prompt
"${dc}" -f "${script}" < /dev/null 2>&1 | tee "${log}"

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
