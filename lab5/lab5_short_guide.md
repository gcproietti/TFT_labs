# Testing and Fault Tolerance (01RKZYG) — Laboratory 5 (short version)
## Pseudo-Random Test and Logic BIST: exercises and command cheat sheet

> **What this is:** the exercises of Lab 5 without the explanations, plus a summary of the scripts and of the TestMAX commands. The full guide (`lab5_guide.html`) explains every step, the reasons behind it and the theory: use it the first time, or whenever something here is not clear.  
> **Working directory:** `~/lab5` · all outputs in `~/lab5/run` · **Tools:** Siemens Questa (`vsim`), Synopsys TestMAX (`tmax`)  
> **Self-check:** Moodle quiz *Lab 5 - Pseudo-random test and logic BIST*, one section per part.

---

## 1. Cheat sheet

### 1.1 Scripts

| What | How |
|---|---|
| Functional self-test of b10 (Part B) | `./func_bist.sh` · variables `STOP` (session, default 1000), `SEED`, `PS=1` (phase shifter), `GOLDEN=<hex>`, `DUMP=1` (→ `run/b10_func_bist.vcd`), `INJECT=1`, `GUI=1` |
| Self-test per scan of b10_scan (Part C) | `./scan_bist.sh` · variables `N` (patterns, default 50), `CAPTURE` (default 1), `SEED`, `PS=1`, `GOLDEN=<hex>`, `DUMP=1` (→ `run/b10_scan_bist.vcd`), `INJECT=1` |
| Your command file for several lengths | `./sweep_bist.sh func <file>.tcl "<STOP values>"` · `./sweep_bist.sh scan <file>.tcl "<N values>"` → `run/sweep/<file>.txt`; same variables (`PS=1 ./sweep_bist.sh ...`) |
| Inject stuck-at faults, GO/NOGO | `GOLDEN=<hex> ./inject_faults.sh func\|scan <list>`; one line per fault: `sa0\|sa1 <class> <cell>/O\|Q` |
| Run a TestMAX command file | `./tmax.sh <file>.tcl` → `run/<file>.log`; prints the **first** error, if any |
| One-line summary · faults by class | `./summary.sh run/<file>.log [label]` · `./list_faults.sh run/<list>.txt [classes]` |

Example: `STOP=500 ./func_bist.sh` then `STOP=500 GOLDEN=<signature> ./func_bist.sh`. Variables apply to one command only when written before it; `export` keeps them for the whole terminal (and for the sweeps: check with `env`).

### 1.2 TestMAX: fault simulation of the self-test patterns (eVCD)

| Mode | Command | Purpose |
|---|---|---|
| BUILD | `read_netlist ../pdt2002.v -format verilog -insensitive -library` | cell library (always first) |
| BUILD | `read_netlist ../b10.v` or `../b10_scan.v` `-format verilog -insensitive` · `run_build_model b10` | design → **DRC** mode |
| DRC | `run_drc ../b10.spf` (b10) · `set_drc ../b10_scan.spf` + `run_drc` (b10_scan) | clocks and reset from the protocol file → **TEST** mode |
| TEST | `set_patterns -external <file>.vcd -sensitive -strobe_period {100 ns} -strobe_offset {40 ns} -vcd_clock auto` | the eVCD of the simulation (in `run/`) as external patterns |
| TEST | `run_simulation -sequential` | good machine: `#fail_pats=0` |
| TEST | `set_faults -model stuck\|transition` · `set_faults -fault_coverage` · `add_faults -all` | fault model, report option, fault list |
| TEST | `run_fault_sim -sequential` · `report_summaries` | fault simulation of the sequence, summary |
| TEST | `report_faults -profile` | new detections pattern by pattern |
| TEST | `write_faults <file> -all -uncollapsed -replace` | fault list with classes |

First line `set_messages -display`, last line `quit`. Transition faults need only `-model transition`: the eVCD already contains the clock cycles.

### 1.3 Formulas

| Quantity | Formula |
|---|---|
| Period of a maximum-length LFSR of n bits | 2ⁿ − 1 (primitive polynomial, non-absorbing seed) |
| SISR, modular form, P(x) = x⁴ + x + 1 | D0 ← D3 ⊕ in · D1 ← D0 ⊕ D3 · D2 ← D1 · D3 ← D2 |
| Aliasing | E(x) multiple of P(x); probability ≈ 2⁻ⁿ |
| Test time of the self-test per scan | N · (L + C) + L clock cycles (L chain length, C capture cycles) |
| Largest N for a budget of B cycles | ⌊(B − L) / (L + C)⌋ |

---

## 2. Exercises

Set-up: `unzip ~/Downloads/lab5.zip -d ~/lab5; cd ~/lab5; chmod +x *.sh; ./func_bist.sh` (ends with GO). For every exercise: **predict first**, then run. The number in brackets is the section of the full guide.

### Part A — LFSRs and signatures by hand (no tool)

**A.1** [A.1] P(x) = x³ + x² + 1. Standard form (Q1 → Q2 → Q3, Q1 ← Q2 ⊕ Q3) and modular form (D0 ← D2, D1 ← D0, D2 ← D1 ⊕ D2): sequences from 001. Number of states, missing state, same set of states?

**A.2** [A.2] Periods from 0001 and from 0110 of x⁴ + x³ + 1, x⁴ + x² + 1, x⁴ + x³ + x² + x + 1 (standard form). Which one is maximum length? Does the period depend on the seed?

**A.3** [A.3] `rtl/lfsr.vhd`, `NBITS = 32`: polynomial; lock-up state with XNOR (could the seed be 0?); period, and its length at 100 MHz.

**A.4** [A.4] SISR x⁴ + x + 1: signatures of 11010110, 11000110, 11000101; error polynomial of the last one; aliasing probability with n = 4 and n = 32.

### Part B — A functional self-test for b10

**B.1** [B.1] Figure 1 and `rtl/`: blocks of slide 6 of *09*; LFSR bits on the inputs of b10 (`PHASE_SHIFTER = 0`) and their relation in time; when TPG and MISR are enabled; when `go_nogo` is valid; which protocol.

**B.2** [B.2] *Predict* the cycles of a session of 1000. `./func_bist.sh`; `STOP=500 ./func_bist.sh` (why NOGO?); golden signature of `STOP=500`, then GO.

**B.3** [B.3] `fsim_b10_func.tcl` from `~/lab2/fsim_c6288.tcl` + `~/lab2/atpg_b10.tcl` (§1.2), with `report_faults -profile`, fault list `b10_func_faults.txt`. `DUMP=1 ./func_bist.sh; ./tmax.sh fsim_b10_func.tcl`. *Predict* against the full-sequential ATPG of Lab 2. Patterns read, last useful pattern, bursts.

**B.4** [B.4] `./sweep_bist.sh func fsim_b10_func.tcl "100 200 500 1000 2000 5000 10000"`; validate on B.3; then the same with `PS=1`. Where does the coverage stop? Why does the phase shifter help, and why would one with equal spacings not help?

**B.5** [B.5] Classes of `U91/O`, `U145/O`, `U154/O` stuck-at-1 in `run/b10_func_faults.txt`; *predict* GO/NOGO; `GOLDEN=A88DEC5B ./inject_faults.sh func my_faults.txt`. The `XXXXXXXX` signature; aliasing; cycles seen by TestMAX and not by the MISR.

### Part C — A self-test per scan for b10

**C.1** [C.1] `rtl/tps_ctrl.vhd`: cycles per pattern and per session; compare with the scan formula of Lab 3. *Predict* the cycles for N = 10, then `N=10 ./scan_bist.sh`.

**C.2** [C.2] `fsim_b10_scan.tcl` from `fsim_b10_func.tcl` (`../b10_scan.v`, `set_drc ../b10_scan.spf` + `run_drc`, `b10_scan_bist.vcd`, `b10_scan_faults.txt`). `N=10 DUMP=1 ./scan_bist.sh; ./tmax.sh fsim_b10_scan.tcl`. Faults and coverage vs Part B.

**C.3** [C.3] `./sweep_bist.sh scan fsim_b10_scan.tcl "10 20 50 100 200 500 1000"`; validate on C.2. Patterns and cycles for 95 % and 99 % vs ATPG of Lab 3 (48 patterns, 932 cycles, 100 %). **Budget:** at most 2500 cycles, at least 95 %: largest N, *predict*, run. Faults left at N = 1000.

**C.4** [C.4] `fsim_b10_scan_tdf.tcl` (`-model transition`). `CAPTURE=2 ./sweep_bist.sh scan fsim_b10_scan_tdf.tcl "50 200 1000"` and `./sweep_bist.sh scan fsim_b10_scan_tdf.tcl "200"`. Transition faults vs Lab 4; one or two capture cycles.

**C.5** [C.5] *Predict*, then `SEED=4321 ./sweep_bist.sh scan fsim_b10_scan.tcl "50 137"` and the same with `PS=1`. Is one seed enough? Why is the phase shifter useless with one chain?

**C.6** [C.6] Golden signature for the N of the budget; one DS and one ND fault (`/O` or `/Q`) from `run/b10_scan_faults.txt`, plus `U145/O` stuck-at-1 (GO in Part B); *predict*; `N=<n> GOLDEN=<hex> ./inject_faults.sh scan my_scan_faults.txt`.

### Optional

E1 reseeding (seeds whose detected faults complement each other) · E2 faults in the BIST circuitry, complementary Go/Nogo · E3 `MISR_MODE=0` and cancellation · E4 write the controller yourself · E5 the faults that random patterns miss (`analyze_faults`) · E6 weighted patterns on paper · E7 waveforms (`GUI=1`) · E8 further questions on your results (full guide, §5).
