vlib work
vlog spriteFSMandDrawer.v movementLogic.v
vsim spriteFSM
log -r {/*}
add wave -r {/*}

force {clock} 0 0ns, 1 {0.5ns} -r 1ns
force {resetn} 0
force {move} 0
force {ld_dir} 0
force {clear} 0
force {dir} 00
run 2ns

force {resetn} 1
force {ld_dir} 1
run 2ns

force {ld_dir} 0
force {move} 1
run 120ns

force {ld_dir} 1
force {move} 0
run 2ns

force {ld_dir} 0
force {move} 1
run 120ns