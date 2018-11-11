vlib work
vlog spriteFSMandDrawer.v movementLogic.v
vsim spriteDrawer
log -r {/*}
add wave -r {/*}

force {clock} 0 0ns, 1 {0.5ns} -r 1ns
force {resetn} 0
force {data_x} 000000001
force {data_y} 00010000
force {clear} 0
force {erase} 0
force {drawChar} 1

run 2ns

force {resetn} 1
run 200ns