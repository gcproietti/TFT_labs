# Testing and Fault Tolerance (01RKZYG) — Laboratory 4 (short version)
## Transition-Delay Faults and Scan Compression: exercises and command cheat sheet

> **What this is:** the exercises of Lab 4 without the explanations, plus a summary of the TestMAX and Design Compiler commands. The full guide (`lab4_guide.html`) explains every step, the reasons behind it and the theory: use it the first time, or whenever something here is not clear.  
> **Working directory:** `~/lab4` · all outputs in `~/lab4/run` · **Tools:** Synopsys TestMAX (`tmax`), Design Compiler (`dc_shell`)  
> **Self-check:** Moodle quiz *Lab 4 - Transition-delay faults and scan compression*, one section per part.

---

## 1. Command cheat sheet

### 1.1 Running the tools

| What | How |
|---|---|
| Try TestMAX commands one at a time | `cd ~/lab4/run; tmax -shell`, then type at the prompt; `quit` |
| Run a TestMAX command file | `cd ~/lab4; ./tmax.sh <file>.tcl` → `run/<file>.log`; the last lines show the **first** error, if any |
| Run a Design Compiler command file | `cd ~/lab4; ./dc.sh <file>.tcl` → `run/<file>.log`; outputs (netlist, SPFs) in `run/` |
| One-line summary of a TestMAX log | `./summary.sh run/<file>.log [label]` → faults, DT, PT, UD, AU, ND, patterns (basic/fast), coverages, test cycles |
| Faults of a fault list by class | `./list_faults.sh run/<list>.txt` (not detected) · `./list_faults.sh run/<list>.txt DI` (given classes); stuck-at and transition |
| Sweeps | `./sweep_delay.sh` (Part B) · `./sweep_compress.sh [stuck\|transition]` (Part D), after your hand runs |

Paths: both tools run in `run/`. Sources are `../<file>`; files written by Design Compiler (`b12_scan.v`, `b12_scan.spf`, `b12_scancompress.spf`) are in `run/`, so TestMAX reads them **without** `../`. A command file **stops at the first error**.

### 1.2 TestMAX commands, in the order of the modes

| Mode | Command | Purpose |
|---|---|---|
| BUILD | `read_netlist ../pdt2002.v -format verilog -insensitive -library` | cell library (always first) |
| BUILD | `read_netlist <netlist> -format verilog -insensitive` · `run_build_model <top>` | design → **DRC** mode |
| DRC | `set_drc <spf>` | protocol file; b12: `b12_scan.spf` (bypass) or `b12_scancompress.spf` (compressed) |
| DRC | `set_delay -launch_cycle last_shift` | transition faults, launch on shift (LOS) |
| DRC | `set_delay -launch_cycle system_clock` · `set_delay -nopi_changes` · `add_pi_constraints 0 test_se` | launch on capture (LOC), inputs held, scan enable inactive |
| DRC | `run_drc` | design rule check, scan chain tracing → **TEST** mode |
| TEST | `report_scan_chains` · `report_compressors -load -verbose` · `report_compressors -unload -verbose` | chains; decompressor; compressor (compressed mode only) |
| TEST | `set_faults -model stuck\|transition` · `-summary verbose` · `-fault_coverage` · `add_faults -all` | fault model, report options, fault list |
| TEST | `set_atpg -capture_cycles 2` | LOC: fast-sequential ATPG (≥ 2), before `run_atpg` |
| TEST | `run_atpg -auto_compression` · `report_summaries` · `report_patterns -all` | ATPG, summaries, patterns |
| TEST | `analyze_faults <pin> -slow r\|f -verbose` | why one transition fault is (not) detected |
| TEST | `write_faults <file> -all -uncollapsed -replace` · `write_patterns <file> -format stil -replace` | fault list; patterns (prints the test cycles) |

### 1.3 Transition faults

| Item | LOS (`last_shift`) | LOC (`system_clock`) |
|---|---|---|
| V1 | state after L − 1 shifts; PIs forced **before** the load | loaded state + PIs |
| launch | last shift (scan enable = 1) | system clock (scan enable = 0) |
| V2 | V1 shifted by one cell along the chain; PIs forced again | next state F(V1); PIs held with `-nopi_changes` |
| scan enable | must fall **at speed**, between launch and capture | constrained to 0: `add_pi_constraints 0 test_se` |
| ATPG engine | basic-scan (`capture_cycles` not needed) | fast-sequential: `set_atpg -capture_cycles 2` |
| procedures between two loads (k) | 2 (PI force before the load, capture) | 2 (launch, capture); 3 with `-nopi_changes` |

Slow-to-rise (`str`) on a node: V1 sets it to 0; V2 sets it to 1 **and** detects a stuck-at-0 on it. Slow-to-fall (`stf`): the opposite. TestMAX places transition faults on the stuck-at sites **except** the clock, reset and scan-enable networks. Test cycles = (N + 1) · (L + 1) + 2 + 1 + k · (N − 1).

### 1.4 Design Compiler: from `b10_scan_insertion.tcl` (Lab 3) to `b12_compress.tcl`

| Change | Command |
|---|---|
| design | `read_verilog ../b12.v` · `current_design b12`; no `set_dont_touch` |
| add, before `create_test_protocol` | `set_dft_configuration -scan_compression enable` |
| external chains (scan pin pairs) | `set_scan_configuration -chain_count 3` |
| add: internal chains | `set_scan_compression_configuration -chain_count 4` |
| add, after `insert_dft` and `dft_drc` | `change_names -rules verilog -hierarchy` |
| keep | `report_scan_path -view existing -chain all` (standard scan chains only) · `report_area` |
| outputs | `write -hierarchy -format verilog -output b12_scan.v` |
| two protocol files | `write_test_protocol -output b12_scan.spf -test_mode Internal_scan` · `write_test_protocol -output b12_scancompress.spf -test_mode ScanCompression_mode` |

The two SPFs describe the same netlist: `test_mode` = 0 (bypass: 3 chains from `test_si<n>` to `test_so<n>`) or 1 (compressed: internal chains between decompressor and compressor, groups `load_group`/`unload_group`/`mode_group`, block `CompressorStructures`).

### 1.5 Reading the results

| Look for | Means |
|---|---|
| `#basic_scan` / `#fast_sequential patterns` | LOS gives basic-scan patterns, LOC fast-sequential (2 capture cycles) |
| `M236` at `run_atpg` | LOC without `set_atpg -capture_cycles 2` |
| `<n> faults were added to fault list.` | transition faults: 368 on b06 (432 stuck-at) |
| M977 · M487 | scan enable not declared in the SPF · an input (reset) may change at speed |
| `str`/`stf` in the fault list | transition faults: slow-to-rise / slow-to-fall |
| `ScanLength` in the two SPFs | bypass: ⌈121 / N<sub>e</sub>⌉; compressed: ⌈121 / N<sub>i</sub>⌉ (b12) |
| test time reduction | (L<sub>scan</sub> · N<sub>scan</sub>) / (L<sub>comp</sub> · N<sub>comp</sub>) |
| test data volume | scan: 3 · L · chains · N; compressed: L · (scan-in + 2 · scan-out) · N |

---

## 2. Exercises

Set-up: `unzip ~/Downloads/lab4.zip -d ~/lab4; cd ~/lab4; chmod +x *.sh; which tmax dc_shell`; check that `~/lab3` has `atpg_b06.tcl`, `atpg_b10_scan.tcl`, `b10_scan_insertion.tcl`, `run/b06_atpg_faults.txt`. **Every command file is written by you**, starting from a file of Lab 3 or of a previous step. For every exercise: **predict first**, then run. The number in brackets is the section of the full guide.

### Part A — Transition faults and launch on shift (b06)

**A.1** [A.1] Slow-to-rise: which stuck-at does it behave like in the capture cycle? Conditions on V1 and V2. *Predict* the number of transition faults of b06.

**A.2** [A.2] With the chain order of Lab 3 (LOS: V2 of a cell = V1 of the previous cell, PIs free in V1 and V2; LOC: V2 = F(V1)), decide for `str U51/O`, `str U30/I2`, `str U33/O`, `str eql` whether a pair exists in LOS, in LOC with PIs held, in LOC with PIs changing.

**A.3** [A.3] `atpg_b06_los.tcl` = `~/lab3/atpg_b06.tcl` + `set_delay -launch_cycle last_shift` before `run_drc`, `set_faults -model transition`, outputs `b06_los_*`. *Predict* coverage and pattern type. Find which sites have no transition fault (`diff` with `~/lab3/run/b06_atpg_faults.txt`). Check the four faults: `./list_faults.sh run/b06_los_faults.txt | grep -E " (U51/O|U30/I2|U33/O|eql)$"`.

**Checkpoint.** No errors; 368 transition faults (no clock, reset, scan-enable sites), 40 DI; basic-scan patterns only; coverage below stuck-at; the four faults as predicted.

### Part B — Launch on capture (b06)

**B.1** [B.1] `atpg_b06_loc.tcl`: `set_delay -launch_cycle system_clock`, `set_delay -nopi_changes`, `add_pi_constraints 0 test_se` before `run_drc`; `set_atpg -capture_cycles 2` before `run_atpg`; outputs `b06_loc_*`. `atpg_b06_loc_pi.tcl`: the same with `-pi_changes`. *Predict* pattern type, pulses per pattern, coverage. What does `str U33/O` tell you about state 111? Warning M977?

**Checkpoint.** Fast-sequential patterns (pattern 0 is the chain test); two pulses between load and unload; the four faults as predicted.

**B.2** [B.2] `atpg_b06_los_af.tcl`, `atpg_b06_loc_af.tcl`: `analyze_faults U30/I2 -slow r -verbose` instead of `report_patterns`. Class in each mode; which scan cell blocks LOS?

**B.3** [B.3] `./sweep_delay.sh` → `run/sweep_delay/table.txt` (stuck-at, LOS, LOC held, LOC changing, LOC held without `test_se` constraint). Validate rows 01–04. Rank the coverages; faults gained by `-pi_changes` (and M487); why row 05 = row 03; k for each row from the test cycles and from the procedures in the STIL; faults no setting detects.

### Part C — Scan compression (b12)

**C.1** [C.1] `b12_compress.tcl` from `~/lab3/b10_scan_insertion.tcl` (§1.4). *Predict* chains and lengths in both modes, cycles per load, new ports. Run with `./dc.sh`; ports, modules, area, `ScanLength` in both SPFs; which test mode does `report_scan_path` show?

**Checkpoint.** No errors; 3 chains (41) and 4 internal chains (31); decompressor and compressor modules.

**C.2** [C.2] `diff run/b12_scan.spf run/b12_scancompress.spf`: value of `test_mode`; chains with and without `ScanIn`/`ScanOut`; `sccompin`/`sccompout` and the groups; `CompressorStructures`; `ScanEnable` (compare with `b06_scan.spf`).

**C.3** [C.3] `atpg_b12_bypass.tcl` (`set_drc b12_scan.spf`) and `atpg_b12_comp.tcl` (`set_drc b12_scancompress.spf` + `report_compressors -load -verbose`, `-unload -verbose`), from `~/lab3/atpg_b10_scan.tcl`, stuck-at, no `../`. *Predict* faults (vs 6656 of Lab 3), patterns, test cycles. Table with the Lab 3 rows. Which faults does only the bypass mode miss?

**Checkpoint.** Same faults in both modes; 3 vs 4 chains traced; fewer test cycles and higher coverage in compressed mode.

**C.4** [C.4] Decompressor: data pins, mode pin, modes; chains sharing a bit in each mode; can 1, 0, 0 on output ids 0, 2, 3 be loaded in one shift cycle? Compressor: which errors cancel; an X on chain 1.

### Part D — How much compression? (b12)

**D.1** [D.1] `b12_compress_4x30.tcl` (4 external, 30 internal chains, outputs `b12_4x30*`) and `atpg_b12_4x30_comp.tcl`. *Predict* chain length, cycles, coverage vs 3 × 4.

**D.2** [D.2] *Predict* the chain lengths of 3 × 4, 1 × 2, 1 × 5, 1 × 30, 4 × 10, 4 × 30. `./sweep_compress.sh` → `run/sweep_compress/table_stuck.txt`; validate rows 3 × 4 and 4 × 30. 1 × 30: modes and coverage; coverage vs data pins per chain; bypass coverage; time and data volume reductions; 4 × 10 and 4 × 30 vs Lab 3 with 4 chains; why keep the bypass mode.

### Optional

E1 `-pi_changes` without the `test_se` constraint, and `set_delay -launch_cycle any` · E2 `add_po_masks -all` in LOC · E3 `./sweep_compress.sh transition` · E4 the decompressor in the Design Compiler GUI · E5 the launch/capture waveform tables · E6 LOS and LOC on the full-scan b10 of Lab 3 · E7 **from scratch:** LOC transition ATPG on the compressed b12 with `analyze_faults -class an`; compare with this cheat sheet only at the end · E8 further questions on your results (full guide, §5).
