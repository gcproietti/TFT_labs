# Testing and Fault Tolerance (01RKZYG) — Laboratory 3 (short version)
## Scan-Based ATPG and Scan Chain Insertion: exercises and command cheat sheet

> **What this is:** the exercises of Lab 3 without the explanations, plus a summary of the TestMAX and Design Compiler commands. The full guide (`lab3_guide.html`) explains every step, the reasons behind it and the theory: use it the first time, or whenever something here is not clear.  
> **Working directory:** `~/lab3` · all outputs in `~/lab3/run` · **Tools:** Synopsys TestMAX (`tmax`), Design Compiler (`dc_shell`)  
> **Self-check:** Moodle quiz *Lab 3 - Scan-based ATPG and scan insertion*, one section per part.

---

## 1. Command cheat sheet

### 1.1 Running the tools

| What | How |
|---|---|
| Try TestMAX commands one at a time | `cd ~/lab3/run; tmax -shell`, then type at the prompt; `quit` |
| Run a TestMAX command file | `cd ~/lab3; ./tmax.sh <file>.tcl` → `run/<file>.log`; the last lines show the **first** error, if any |
| Run a Design Compiler command file | `cd ~/lab3; ./dc.sh <file>.tcl` → `run/<file>.log`; outputs (netlist, SPF) in `run/` |
| One-line summary of a TestMAX log | `./summary.sh run/<file>.log [label]` → faults, DT, PT, UD, AU, ND, patterns (basic/fast), coverages, test cycles |
| Faults of a fault list by class | `./list_faults.sh run/<list>.txt` (not detected) · `./list_faults.sh run/<list>.txt DI` (given classes) |
| Sweeps | `./sweep_cells.sh` (Part B) · `./sweep_scan.sh [b10\|b12]` (Part C) · `./sweep_capture.sh [b10_partial]` (Part D) |

Paths: both tools run in `run/`. Sources are `../<file>`; files written by Design Compiler (`b10_scan.v`, `b10_scan.spf`) are in `run/`, so TestMAX reads them **without** `../`. A command file **stops at the first error**.

### 1.2 TestMAX commands, in the order of the modes

| Mode | Command | Purpose |
|---|---|---|
| BUILD | `read_netlist ../pdt2002.v -format verilog -insensitive -library` | cell library (always first) |
| BUILD | `read_netlist <netlist> -format verilog -insensitive` | `../b06_scan.v`, or `b10_scan.v` from Design Compiler |
| BUILD | `run_build_model <top>` | `b06`, `b10`, `b12` → **DRC** mode |
| DRC | `set_drc <spf>` | protocol file: clocks, scan chains, `load_unload`, `capture` |
| DRC | `add_cell_constraints <value> <chain> -position <p>` · `-position {<first> <last>}` | constrain scan cells (between `set_drc` and `run_drc`) |
| DRC | `run_drc` | design rule check, **scan chain tracing** → **TEST** mode |
| TEST | `report_scan_chains` · `report_scan_cells -all` · `report_nonscan_cells -summary` | chains (length, scan-in, scan-out); cells by position; non-scan cells |
| TEST | `set_faults -model stuck` · `-summary verbose` · `-fault_coverage` · `add_faults -all` | fault model, report options, fault list |
| TEST | `set_atpg -capture_cycles <N>` | 0: basic-scan only; 2–10: also fast-sequential ATPG |
| TEST | `run_atpg -auto_compression` | ATPG |
| TEST | `report_summaries` · `report_patterns -all` | summaries; every pattern step by step |
| TEST | `analyze_faults <pin> -stuck 0\|1 -verbose` | why one fault is (not) detected |
| TEST | `write_faults <file> -all -uncollapsed -replace` · `write_patterns <file> -format stil -replace` | fault list; patterns (prints the number of test cycles) |
| any | `drc -force` | back from TEST to DRC mode |

### 1.3 Cell constraints

| Value | Load (PPI) | Observation (PPO) |
|---|---|---|
| `0` / `1` | always 0 / 1 | normal |
| `X` | always X | normal |
| `OX` | free | captured value = X |
| `0X` / `1X` | always 0 / 1 | captured value = X |
| `XX` | always X | captured value = X |

Positions count from the **scan-out** (position 0 = cell next to scan-out). b06, chain `1`: `state_reg[0]` = 4, `state_reg[1]` = 3, `state_reg[2]` = 2. A new constraint on the same cell **replaces** the previous one.

### 1.4 Design Compiler script (`b10_scan_insertion.tcl`)

| Command | Purpose | You change |
|---|---|---|
| `uplevel #0 source ../pdt2002.dc_setup.tcl` | library, cells not to use | — |
| `read_verilog ../b10.v` · `current_design b10` · `link` · `check_design` | read and link the netlist | design name |
| `#set_dont_touch voto2_reg` | keep a flip-flop **out** of the chain | remove `#` (Part D) |
| `set test_default_scan_style multiplexed_flip_flop` · `create_test_protocol -infer_asynch -infer_clock` · `dft_drc` | mux-scan, test protocol, checks | — |
| `set_scan_configuration -chain_count 1` | number of chains | the number |
| `preview_dft` · `insert_dft` · `dft_drc` | insert the chains | — |
| `report_scan_path -view existing -chain all` · `-cell all` · `report_area` | chains, cells, area | — |
| `write -hierarchy -format verilog -output b10_scan.v` · `write_test_protocol -output b10_scan.spf` | netlist with scan, SPF | file names |

### 1.5 Reading the results

| Look for | Means |
|---|---|
| `Chain 1 successfully traced with 9 scan_cells.` · `Design rules checking was successful` | DRC found the chain |
| `Error: extra positional option '4' (CMD-012)` | write `-position 4` |
| **DI** (in DT) | detected by implication: faults on the scan path, shift clock, reset lines (chain test) |
| **AN** (in AU) | untestable under the current constraints / mode |
| `Pattern 0 (basic_scan-chain_test)` | chain test: load/unload `0011…`, no capture pulse |
| `load` → `force_all_pis` → `measure_all_pos` → `pulse clocks` → `unload` | one basic-scan pattern |
| `Ann {* fast_sequential *}` in the STIL | the following pattern has several `multiclock_capture` cycles |
| TAT = (N + 1) · L + N | N patterns, L = longest chain; the tool adds a few protocol cycles |
| test coverage = (DT + ½ PT) / (all − UD) | fault coverage = (DT + ½ PT) / all |

---

## 2. Exercises

Set-up: `unzip ~/Downloads/lab3.zip -d ~/lab3; cd ~/lab3; chmod +x *.sh; which tmax dc_shell`. For every exercise: **predict first**, then run. The number in brackets is the section of the full guide.

### Part A — A full-scan design: b06

**A.1** [A.1] Count the scan cells of `b06_scan.v`. Follow the `SI` pins (`grep -n "SI(" b06_scan.v`) and **draw the chain** from scan-in to scan-out, with the position of each cell. Which port is the scan-out? Compare with `ScanStructures` in `b06_scan.spf`. In `load_unload`, when is `test_se` = 1? *Predict* the number of faults (6 pins per scan cell; `grep -o "^ *[A-Z0-9]*_GATE" b06_scan.v | sort | uniq -c`).

**A.2** [A.2] Write `atpg_b06.tcl` (start from `~/lab2/atpg_b10.tcl`): `../b06_scan.v`, top `b06`, `set_drc ../b06_scan.spf` + `run_drc`, the three scan reports, `run_atpg -auto_compression`, `report_summaries`, `report_patterns -all`, outputs `b06_atpg_faults.txt`, `b06_atpg.stil`.

**Checkpoint.** No errors; one chain traced with your number of cells; positions as in your drawing; no non-scan cells; total faults = your count.

**A.3** [A.3] *Predict* the coverage (b10 without scan had 0 % with basic-scan ATPG) and write the TAT formula. Fill in: faults, DT (DI), AU, test coverage, patterns, TAT by formula, test cycles from `grep "test cycles" run/atpg_b06.log`. Which faults are DI (`./list_faults.sh run/b06_atpg_faults.txt DI`)? What does pattern 0 do? Why is `measure_all_pos` before `pulse clocks`? Where do the extra tool cycles come from?

### Part B — Cell constraints (b06)

**B.1** [B.1] *Predict:* with `OX` on `state_reg[0]`, the gates that drive **only** its `D` input (`grep -n "N46" b06_scan.v` and backwards): how many faults are certainly lost? `0`, `1` or `X`: which costs more? `X` or `OX`? Is `0X` = `0` + `OX`? Is `XX` = `X` + `OX`?

**B.2** [B.2] `atpg_b06_cc.tcl` = `atpg_b06.tcl` + `add_cell_constraints OX 1 -position 4` between `set_drc` and `run_drc`, without the reports, outputs `b06_cc_*`.

**Checkpoint.** At least your count of faults lost, all in class AN (`./list_faults.sh run/b06_cc_faults.txt`).

Then `atpg_b06_0x.tcl`: the same with `0X` instead of `OX`, outputs `b06_0x_*`. *Predict* first: is the loss `0` + `OX`? **Checkpoint.** `0X` loses more than `OX`.

**B.3** [B.3] `./sweep_cells.sh` → `run/sweep_cells/table.txt` (15 settings: 7 values on `state_reg[0]`, 7 on `state_reg[2:0]`). Validate rows 01, 05 and 06. Rank the values; check your predictions on additivity; where are the PT faults? Why is the whole state register so expensive?

**B.4** [B.4] `atpg_b06_xx.tcl`: `XX` on `-position {2 4}` and `analyze_faults U51/O -stuck 0 -verbose`. Excitation or observation? Which cells? In row 08 (`XX` on `state_reg[0]` only) is the fault detected (`./list_faults.sh run/sweep_cells/08_state0_XX_faults.txt | grep U51/O`)? Why?

### Part C — Scan insertion (b10, b12)

**C.1** [C.1] *Predict* chain length and new ports. `./dc.sh b10_scan_insertion.tcl`; check `run/b10_scan.v` (scan cells, module header), `run/b10_scan.spf` (`ScanLength`, `ScanIn`, `ScanOut`), the two `report_area` totals.

**Checkpoint.** No errors; 17 scan cells; one chain of 17. Which port is the scan-out? Did the area change, and why?

**C.2** [C.2] `atpg_b10_scan.tcl` from `atpg_b06.tcl`: `read_netlist b10_scan.v`, `set_drc b10_scan.spf` (no `../`), top `b10`. *Predict* the faults (Lab 2: 1124) and the coverage. Compare with Lab 2 (91.10 %, 32 patterns, 416 cycles, 37 s).

**C.3** [C.3] `b10_scan4.tcl` = `b10_scan_insertion.tcl` with `-chain_count 4` and outputs `b10_scan4.v`/`.spf`; `atpg_b10_scan4.tcl` with the new names. *Predict* longest chain and new ports, then run both.

**Checkpoint.** Four chains, the longest as predicted; about the same patterns, far fewer test cycles than with one chain.

*Predict* longest chain, patterns and TAT for the other configurations, then `./sweep_scan.sh` → `run/sweep_scan/table.txt`; validate the rows b10/1 and b10/4 (`diff b10_scan4.tcl run/sweep_scan/b10_4_dc.tcl`). Is the TAT divided exactly by 4? Do patterns and coverage depend on the chains? What is the cost of more chains (ports of `run/sweep_scan/b12_4.v`)?

### Part D — Partial scan and fast-sequential ATPG (b10)

**D.1** [D.1] Where are `voto2` and `last_r` used? *Predict* which faults basic-scan ATPG loses if those two flip-flops are not scanned, and the trend of the coverage with 0, 2, 4, 10 capture cycles.

**D.2** [D.2] `b10_partial.tcl` = `b10_scan_insertion.tcl` with the two `set_dont_touch` lines active and outputs `b10_partial.v`/`.spf`; run it with `./dc.sh`. `atpg_b10_partial.tcl` = `atpg_b10_scan.tcl` with the new names.

**Checkpoint.** Chain of 15; 2 non-scan cells; coverage lower than full scan.

**D.3** [D.3] `atpg_b10_partial_cc4.tcl` = `atpg_b10_partial.tcl` + `set_atpg -capture_cycles 4` before `run_atpg`, outputs `b10_partial_cc4_*`. *Predict* the change in patterns and coverage.

**Checkpoint.** Basic-scan and fast-sequential patterns; coverage higher than in D.2.

`./sweep_capture.sh b10_partial` → `run/sweep_capture/b10_partial_table.txt`; validate rows 0 and 4. How many fast-sequential patterns, how much coverage? Find a fast-sequential pattern in `run/b10_partial_cc4.stil` (`grep -n -A12 fast_sequential`): how many capture cycles, where are the outputs compared? Which faults remain with 10 cycles? No scan, partial scan or full scan: which one would you choose?

### Optional

E1 `analyze_faults U51/O -stuck 0 -display` in the GUI · E2 `XX` on `state_reg[1]` only: is `U51/O` sa0 detected? · E3 count the cycles of a pattern in `run/b06_atpg.stil` · E4 which flip-flops in which chain (`run/sweep_scan/b10_4.spf`) · E5 full-sequential ATPG on the partial-scan b10 · E6 your own partial scan of b12 · E7 `add_pi_constraints 0 test_se` · E8 further questions on your results (full guide, §5) · **E9 from scratch:** without copying, write the DC file for b12 with 2 chains and 2 non-scan flip-flops, and the TestMAX file with 4 capture cycles; compare with this cheat sheet only at the end.
