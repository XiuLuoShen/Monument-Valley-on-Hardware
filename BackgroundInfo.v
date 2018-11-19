/*  This module is used to access the appropriate memory to get the correct pixel to
 draw the map for the given gameState
*/

module getBackgroundPixel(
	input clock,
	input [3:0] gameState,
	input [8:0] X,
	input [7:0] Y,
	output reg [2:0] color
	);

	reg [16:0] memoryAddress;
	// converts the X and Y coordinates into a memory address
	always @(*) begin
		memoryAddress = Y*9'd320 + X;
	end

	// ROM Modules and their corresponding wires here:
	wire [2:0] original;
	BG_original bg(.address(memoryAddress), .clock(clock), .q(original));

	localparam
		DRAW_INITIAL = 4'10,
		INITIAL = 4'b0,
		UPDATE_BRIDGE_1 = 4'b1,
		FORMED_BRIDGE_1 = 4'b2,
		UPDATE_BRIDGE_2 = 4'b3,
		FORMED_BRIDGE_2 = 4'b4,
		UPDATE_BRIDGE_3 = 4'b5,
		FORMED_BRIDGE_3 = 4'b6,
		UPDATE_PILLAR = 4'b7,
		PILLAR_RISED = 4'b8,
		FINISHED_GAME = 4'b9;

	always @(*) begin
		if (gameState == DRAW_INITIAL || gameState == INITIAL)
			color = original;
		else if (gameState == UPDATE_BRIDGE_1 || gameState == FORMED_BRIDGE_1)
			color = ........;
		else if .....

endmodule
