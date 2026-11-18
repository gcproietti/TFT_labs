# waveforms for GUI=1 ./func_bist.sh
add wave -noupdate /tb_b10_wrapper/clock /tb_b10_wrapper/reset /tb_b10_wrapper/normal_test
add wave -noupdate /tb_b10_wrapper/testing /tb_b10_wrapper/test_over /tb_b10_wrapper/go_nogo
add wave -noupdate -divider LBIST
add wave -noupdate /tb_b10_wrapper/u_b10_wrapper/lbist_i/controller_i/sm_i/current_state
add wave -noupdate -radix hex /tb_b10_wrapper/u_b10_wrapper/lbist_i/tpg_i/tmp_dout
add wave -noupdate /tb_b10_wrapper/u_b10_wrapper/lbist_i/test_pis
add wave -noupdate -radix hex /tb_b10_wrapper/u_b10_wrapper/lbist_i/signature
add wave -noupdate -divider b10
add wave -noupdate /tb_b10_wrapper/u_b10_wrapper/u_b10/*
