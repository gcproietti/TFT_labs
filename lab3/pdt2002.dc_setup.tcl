# pdt2002.dc_setup.tcl - technology library set-up for Design Compiler
# (sourced by the scan insertion scripts; Design Compiler runs in run/, hence ../)

# the cells of the netlists are linked to, and new cells are taken from, this library
set link_library   {../pdt2002.db}
set target_library {../pdt2002.db}

# cells that Design Compiler must NOT use when it modifies the netlist.
# The only scan cell left available is FLIP_FLOP_D_RESET_SCAN: it is the only
# scan cell modelled in pdt2002.v, the library read by TestMAX.
set_dont_use "pdt2002/FLIP_FLOP_D_SCAN"
#set_dont_use "pdt2002/FLIP_FLOP_D_RESET_SCAN"
set_dont_use "pdt2002/FLIP_FLOP_D_PRESET_SCAN"
set_dont_use "pdt2002/FLIP_FLOP_D_RESET_PRESET_SCAN"
# no XOR/XNOR cells: the netlists keep the simple gates used in the previous labs
set_dont_use "pdt2002/XOR_GATE"
set_dont_use "pdt2002/XOR3_GATE"
set_dont_use "pdt2002/XOR4_GATE"
set_dont_use "pdt2002/XOR5_GATE"
set_dont_use "pdt2002/XNOR_GATE"
set_dont_use "pdt2002/XNOR3_GATE"
set_dont_use "pdt2002/XNOR4_GATE"
set_dont_use "pdt2002/XNOR5_GATE"
