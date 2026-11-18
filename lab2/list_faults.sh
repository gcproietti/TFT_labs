#!/bin/bash
#
# list_faults.sh - list the faults of a TestMAX fault list by class
#
# Usage:  ./list_faults.sh <fault_list> [code ...]
#   ./list_faults.sh run/ex1_fsim_faults.txt          faults NOT detected (class not DS/DI)
#   ./list_faults.sh run/atpg_c6288_faults.txt UR AN  only the faults of classes UR and AN
#
# In a fault list, a line with code "--" is a fault equivalent to the
# primary fault above it, so it has the same class: the script prints
# every fault with its real class, then a count per class.

list=${1}
[ -z "${list}" ] && echo "Usage: $0 <fault_list> [code ...]" && exit 1
[ ! -f "${list}" ] && echo "Fault list \"${list}\" not found!" && exit 1
shift
codes="$*"

awk -v codes="${codes}" '
	BEGIN { n = split(codes, c, " "); for (i = 1; i <= n; i++) want[c[i]] = 1 }
	$1 ~ /^sa[01]$/ {
		if ($2 != "--") cls = $2               # primary fault: remember its class
		keep = (n > 0) ? (cls in want) : (cls != "DS" && cls != "DI")
		if (keep) { printf "%-4s %-3s %s\n", $1, cls, $3; cnt[cls]++; tot++ }
	}
	END {
		printf "# %d faults", tot + 0
		for (k in cnt) printf "  %s=%d", k, cnt[k]
		printf "\n"
	}' "${list}"
