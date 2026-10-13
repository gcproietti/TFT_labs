#!/bin/sh

# Move to the run directory
mkdir -p run && cd run

# Invoke DesignCompiler and run the TCL script
dc_shell-xg-t -64 -f ../synthesis_script.tcl
