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

	//**************** ROM Modules and their corresponding wires here:
	wire [2:0] original;
	BG_original bg1(.address(memoryAddress), .clock(clock), .q(original));

	wire [2:0] bridge2;
	Bridge2Formed bg2(.address(memoryAddress), .clock(clock), .q(bridge2));

	wire [2:0] pillarRisen;
	PillarRisen bg3(.address(memoryAddress), .clock(clock), .q(pillarRisen));
	// ***************

	localparam
		DRAW_INITIAL = 4'd10,
		INITIAL = 4'd0,
		UPDATE_BRIDGE_1 = 4'd1,
		FORMED_BRIDGE_1 = 4'd2,
		UPDATE_BRIDGE_2 = 4'd3,
		FORMED_BRIDGE_2 = 4'd4,
		UPDATE_BRIDGE_3 = 4'd5,
		FORMED_BRIDGE_3 = 4'd6,
		UPDATE_PILLAR = 4'd7,
		PILLAR_RISED = 4'd8,
		FINISHED_GAME = 4'd9;


	// The memory block that is used to determine the color changes depending on the gameState
	always @(*) begin
		if (gameState == DRAW_INITIAL || gameState == INITIAL)
			color = original;
		else if (gameState == UPDATE_BRIDGE_1 || gameState == FORMED_BRIDGE_1)
			color = bridge2;
		else if (gameState == UPDATE_BRIDGE_2 || gameState == FORMED_BRIDGE_2)
			color = pillarRisen;
		else if (gameState == UPDATE_BRIDGE_3 || gameState == FORMED_BRIDGE_3)
			color = bridge2;
		else if (gameState == UPDATE_PILLAR || gameState == PILLAR_RISED)
			color = pillarRisen;
		else
			color = original;
	end

endmodule
