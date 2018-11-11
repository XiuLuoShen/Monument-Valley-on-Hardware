vlib work
vlog movementLogic.v
vsim moveSprite
log {/*}
add wave {/*}

force {clock} 0 0ns, 1 {0.5ns} -r 1ns
force {resetn} 0
force {dir} 00
force {doneBG, doneChar} 11
force {ld_dir} 1
run 1ns

force {resetn} 1
run 10ns

force {ld_dir} 0
force {move} 1
run 10ns

force {dir} 11
force {move} 0
run 1ns

force {ld_dir} 1
force {move} 1

run 10ns
force {dir} 01

run 20ns

force {dir} 10
run 30ns
