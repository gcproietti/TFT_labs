#!/bin/bash
#
# summary.sh - extract the LAST fault summary printed in a TestMAX log
#
# Usage:  ./summary.sh <log> [label]
# Prints one line:
#   label  #faults  DT  PT  UD  AU  ND (NC/NO)  patterns (basic/fast)  test_cov  fault_cov  cycles
#
# It reads the "Fault Summary Report" and the pattern summary printed by
# report_summaries, and the number of test cycles printed by write_patterns
# ("-" if the log contains no write_patterns). Always check one log by hand.

log=${1}
label=${2:-$(basename "${log}" .log)}
[ ! -f "${log}" ] && echo "Log \"${log}\" not found!" && exit 1

awk -v label="${label}" '
	/Fault Summary Report/ { n++; delete v; pats = "-"; bs = 0; fs = 0 }   # a new report starts
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
		# pattern summary: "#internal patterns  N", then one line per ATPG mode
		if ($0 ~ /#(internal|external) patterns/ && $NF ~ /^[0-9]+$/) pats = $NF
		else if ($0 ~ /#.*patterns/ && $NF ~ /^[0-9]+$/ && pats == "-") pats = $NF
		if ($0 ~ /#basic_scan patterns/ && $NF ~ /^[0-9]+$/)      bs = $NF
		if ($0 ~ /#fast_sequential patterns/ && $NF ~ /^[0-9]+$/) fs = $NF
		# write_patterns: "... generating N test cycles"
		if (match($0, /generating [0-9]+ test cycles/)) { split(substr($0, RSTART), a, " "); cyc = a[2] }
	}
	END {
		if (n == 0) { print label "  (no fault summary found in the log)"; exit 1 }
		f = "%-34s %7s %7s %5s %5s %6s %6s (%s/%s) %6s (%s/%s) %8s %8s %7s\n"
		printf f, label, v["TOT"], v["DT"], v["PT"]+0, v["UD"]+0, v["AU"]+0, v["ND"]+0, \
		       v["NC"]+0, v["NO"]+0, pats, bs, fs, v["TC"], v["FC"], (cyc == "" ? "-" : cyc)
	}' "${log}"
