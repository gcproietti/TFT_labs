# pdt2002.dc_setup.tcl - PoliTo pdt2002 library for Design Compiler
# Sourced by the Design Compiler command files, which run in run/: the library is one level up.

set link_library {../pdt2002.db}
set target_library {../pdt2002.db}

# Cells Design Compiler must not use: every scan cell except FLIP_FLOP_D_RESET_SCAN (the only one
# modelled in pdt2002.v, read by TestMAX), and the XOR/XNOR cells.
set_dont_use "pdt2002/FLIP_FLOP_D_SCAN"
#set_dont_use "pdt2002/FLIP_FLOP_D_RESET_SCAN"
set_dont_use "pdt2002/FLIP_FLOP_D_PRESET_SCAN"
set_dont_use "pdt2002/FLIP_FLOP_D_RESET_PRESET_SCAN"
set_dont_use "pdt2002/XOR_GATE"
set_dont_use "pdt2002/XOR3_GATE"
set_dont_use "pdt2002/XOR4_GATE"
set_dont_use "pdt2002/XOR5_GATE"
set_dont_use "pdt2002/XNOR_GATE"
set_dont_use "pdt2002/XNOR3_GATE"
set_dont_use "pdt2002/XNOR4_GATE"
set_dont_use "pdt2002/XNOR5_GATE"
