vlib work
vlog bg_image_test.v spriteFSMandDrawer.v movementLogic.v vga_adapter/vga_adapter.v vga_adapter/vga_address_translator.v vga_adapter/vga_controller.v vga_adapter/vga_pll.v
vsim vga_test -L altera_mf_ver
log -r {/*}
add wave -r {/*}

force {CLOCK_50} 0 0ns, 1 {0.5ns} -r 1ns
force {KEY[0]} 0
force {KEY[1]} 1
force {KEY[2]} 1
force {SW[3]} 0
force {SW[1:0]} 00
run 2ns

force {KEY[0]} 1
force {KEY[1]} 0
run 2ns

force {KEY[1]} 1
force {KEY[2]} 0
run 120ns

force {KEY[1]} 0
force {KEY[2]} 1
run 2ns

force {KEY[1]} 1
force {KEY[2]} 0
run 120ns
