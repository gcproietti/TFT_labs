#!/bin/bash
#
# summary.sh - extract the LAST fault summary printed in a TestMAX log
#
# Usage:  ./summary.sh <log> [label]
# Prints one line:
#   label  #faults  DT  PT  UD  AU  ND (NC/NO)  patterns  test_cov  fault_cov
#
# It only reads the "Fault Summary Report" and "Pattern Summary Report"
# printed by report_summaries: always check one log by hand (Part B.3).

log=${1}
label=${2:-$(basename "${log}" .log)}
[ ! -f "${log}" ] && echo "Log \"${log}\" not found!" && exit 1

awk -v label="${label}" '
	/Fault Summary Report/ { n++; delete v; pats = "-" }      # a new report starts
	{
		# main classes:  "Detected   DT   144361"
		if (match($0, /[ \t](DT|PT|UD|AU|ND)[ \t]+[0-9]+[ \t]*$/)) {
			split(substr($0, RSTART), a, /[ \t]+/); v[a[2]] = a[3]
		}
		# sub-classes (verbose):  "not-observed   NO   (7104)"
		if (match($0, /[ \t](NC|NO|UR|AN|DS|DI)[ \t]+\([0-9]+\)/)) {
			s = substr($0, RSTART, RLENGTH); gsub(/[()]/, "", s)
			split(s, a, /[ \t]+/); v[a[2]] = a[3]
		}
		if ($0 ~ /total faults/)   v["TOT"] = $NF
		if ($0 ~ /test coverage/)  v["TC"]  = $NF
		if ($0 ~ /fault coverage/) v["FC"]  = $NF
		if ($0 ~ /#.*patterns/ && $NF ~ /^[0-9]+$/) pats = $NF   # last pattern count line
	}
	END {
		if (n == 0) { print label "  (no fault summary found in the log)"; exit 1 }
		f = "%-42s %7s %7s %5s %5s %6s %6s (%s/%s) %6s %8s %8s\n"
		printf f, label, v["TOT"], v["DT"], v["PT"]+0, v["UD"]+0, v["AU"]+0, v["ND"]+0, \
		       v["NC"]+0, v["NO"]+0, pats, v["TC"], v["FC"]
	}' "${log}"
