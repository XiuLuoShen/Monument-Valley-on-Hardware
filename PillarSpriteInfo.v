/*  This module is used to access the appropriate memory to get the correct pixel to
 draw the map for the given gameState
*/

module getPillarPixel(
	input clock,
	input [4:0] X,
	input [4:0] Y,
	output [2:0] color
	);

	reg [9:0] memoryAddress;
	always @(*) begin
		memoryAddress = Y*5'd20 + X;
	end
	
	Pillar pixel(.clock(clock), .address(memoryAddress), .q(color));
	

endmodule
