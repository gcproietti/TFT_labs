# b10_scan_insertion.tcl - scan chain insertion on b10 with Design Compiler
# Run from ~/lab3:   ./dc.sh b10_scan_insertion.tcl
# Outputs (in run/): b10_scan.v (netlist with scan) and b10_scan.spf (STIL procedure file)

uplevel #0 source ../pdt2002.dc_setup.tcl        ;# library and dont_use cells

# ---------------------------------------------------------------- read the netlist
read_verilog ../b10.v
current_design b10
link                                              ;# resolve the cells in pdt2002.db
check_design

report_area                                       ;# area BEFORE scan insertion

# flip-flops to keep OUT of the scan chain (partial scan, Part D)
#set_dont_touch voto2_reg
#set_dont_touch last_r_reg

# ---------------------------------------------------------------- scan configuration
set test_default_scan_style multiplexed_flip_flop  ;# mux-scan flip-flops
create_test_protocol -infer_asynch -infer_clock    ;# find the clock and the asynchronous reset
dft_drc                                            ;# test design rules BEFORE insertion
set_scan_configuration -chain_count 1              ;# number of scan chains

# ---------------------------------------------------------------- scan insertion
preview_dft                                        ;# what insert_dft is going to do
insert_dft
dft_drc                                            ;# test design rules AFTER insertion

report_scan_path -view existing -chain all         ;# the chains: scan-in, scan-out, length
report_scan_path -view existing -cell all          ;# the cells of each chain, in order

report_area                                        ;# area AFTER scan insertion

# ---------------------------------------------------------------- outputs
write -hierarchy -format verilog -output b10_scan.v
write_test_protocol -output b10_scan.spf

quit
