// This is a module used to access the RAM addresses of an image (Starting with background specifically, will see if it can be refactored
// for more general use

module getBackgroundPixel(
	input clock,
	input [8:0] X,
	input [7:0] Y,
	output [2:0] color
	);

	wire [16:0] memoryAddress;
	
	// converts the X and Y coordinates into a memory address
	vga_address_translator address_translator(.x(X), .y(Y), .mem_address(memoryAddress));
//	BG_original bg(.address(memoryAddress), .clock(clock), .q(color));
	MapImage bg(.address(memoryAddress), .clock(clock), .data(3'b111), .wren(1'b0), .q(color));

endmodule
