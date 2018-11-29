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

	reg [15:0] memoryAddress;
	// converts the X and Y coordinates into a memory address
	always @(*) begin
		memoryAddress = Y*9'd240 + X;
	end

	//**************** ROM Modules and their corresponding wires here:
	wire [2:0] original;
	BG_original bg0(.address(memoryAddress), .clock(clock), .q(original));
	
	wire [2:0] bridge1;
	Bridge1Formed bg1(.address(memoryAddress), .clock(clock), .q(bridge1));

	wire [2:0] bridge2;
	Bridge2Formed bg2(.address(memoryAddress), .clock(clock), .q(bridge2));
	
	wire [2:0] bridge3;
	Bridge3Formed bg3(.address(memoryAddress), .clock(clock), .q(bridge3));

	wire [2:0] pillarRisen;
	PillarRisen bg4(.address(memoryAddress), .clock(clock), .q(pillarRisen));

	wire [2:0] finishGame;
	endgameImage finished(.address(memoryAddress), .clock(clock), .q(finishGame));
	// ***************

	localparam
    DRAW_INITIAL = 4'd0,
    INITIAL = 4'd1,
    UPDATE_BRIDGE_1 = 4'd2,
    FORMED_BRIDGE_1 = 4'd3,
    UPDATE_BRIDGE_2 = 4'd4,
    FORMED_BRIDGE_2 = 4'd5,
    UPDATE_BRIDGE_3 = 4'd6,
    FORMED_BRIDGE_3 = 4'd7,
    ANIMATE_PILLAR = 4'd8,
    UPDATE_PILLAR = 4'd9,
    PILLAR_RISED = 4'd10,
    FINISHED_GAME = 4'd11;


	// The memory block that is used to determine the color changes depending on the gameState
	always @(*) begin
	case(gameState)
		DRAW_INITIAL, INITIAL: color = original;
		UPDATE_BRIDGE_1, FORMED_BRIDGE_1:	color = bridge1;
		UPDATE_BRIDGE_2, FORMED_BRIDGE_2:	color = bridge2;
		UPDATE_BRIDGE_3, FORMED_BRIDGE_3:	color = bridge3;
		UPDATE_PILLAR, PILLAR_RISED:	color = pillarRisen;
		FINISHED_GAME:	color = finishGame;
		default: color = original;
	endcase
	end

endmodule
