// This is a module used to access the RAM addresses of an image (Starting with background specifically, will see if it can be refactored
// for more general use

module getBackgroundPixel(
	input clock,
	input [8:0] X,
	input [7:0] Y,
	output [2:0] color
	);

	reg [17:0] memoryAddress;
	
	// converts the X and Y coordinates into a memory address
	always @(*) begin
		memoryAddress = Y*9'd320 + X;
	end
	
	BG_original bg(.address(memoryAddress), .clock(clock), .q(color));
//	MapImage bg(.address(memoryAddress), .clock(clock), .data(3'b111), .wren(1'b0), .q(color));

endmodule
