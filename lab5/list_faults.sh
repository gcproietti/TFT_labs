#!/bin/bash
#
# list_faults.sh - faults of a TestMAX fault list, with their class
#
# Usage:  ./list_faults.sh <fault_list> [class ...]
#   ./list_faults.sh run/b06_los_faults.txt          faults NOT detected (every class except DS, DI, DR, DT)
#   ./list_faults.sh run/b06_los_faults.txt AN NO    only the classes given
# Output: one line per fault ("str  AN  U30/I2"), then "# <n> faults  <class>=<count> ...".
#
# Works for stuck-at (sa0/sa1) and transition (str/stf) fault lists. In a fault list
# written with -uncollapsed, an equivalent fault has the code "--": its class is the
# class of the primary fault written above it (User Guide, Working with Fault Lists),
# so a plain grep would miss it.

list=${1}
[ -z "${list}" ] && echo "Usage: $0 <fault_list> [class ...]" && exit 1
[ ! -f "${list}" ] && echo "Fault list \"${list}\" not found!" && exit 1
shift
codes="$*"

awk -v codes="${codes}" '
	BEGIN { nc = split(codes, c, " "); for (i = 1; i <= nc; i++) want[c[i]] = 1 }
	$1 ~ /^(sa0|sa1|str|stf)$/ && NF >= 3 {
		cls = $2
		if (cls == "--") cls = last; else last = cls
		if (nc > 0) { if (!(cls in want)) next }
		else if (cls ~ /^(DS|DI|DR|DT)$/) next
		printf "%s  %s  %s\n", $1, cls, $3
		n++; cnt[cls]++
		if (!(cls in seen)) { seen[cls] = 1; order[++k] = cls }
	}
	END {
		s = "# " n + 0 " faults"
		for (i = 1; i <= k; i++) s = s "  " order[i] "=" cnt[order[i]]
		print s
	}' "${list}"
