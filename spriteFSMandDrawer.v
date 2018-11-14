// This file contains the top level module for the sprite and the FSM for the spriteDrawer
// Currently spriteDrawer redraws a teal square at the old sprite location and
// then draws a new red square (the sprite) at the new location
// Clearing resets the screen to the background image

module spriteFSM(
	input clock, resetn, move, ld_dir, clear,
	input [1:0] dir,
	output plot,
	output [2:0] color,
	output [8:0] xCoord,
	output [7:0] yCoord
);

	wire doneDraw, drawChar, drawBG;				// communication signals between spriteDrawer and spriteInfo
	wire [8:0] x_pos;
	wire [7:0] y_pos;


	moveSprite spriteInfo(
		.move(move),
		.clock(clock),
		.ld_dir(ld_dir),
		.resetn(resetn),
		.doneChar(doneDraw),
		.doneBG(doneDraw),
		.dir(dir),
		.drawChar(drawChar),
		.drawBG(drawBG),
		.xCoordinate(x_pos),
		.yCoordinate(y_pos)
	);

	spriteDrawer drawer(
		.clock(clock),
		.data_x(x_pos),
		.data_y(y_pos),
		.resetn(resetn),
		.clear(clear),
		.drawChar(drawChar),
		.erase(drawBG),
		.xCoordinate(xCoord),
		.yCoordinate(yCoord),
		.drawOnVGA(plot),
		.colorToDraw(color),
		.doneDraw(doneDraw)
		);

endmodule



module spriteDrawer(
	input [8:0] data_x,
	input [7:0] data_y,
	input resetn, clear, drawChar, erase, clock,
	output [8:0] xCoordinate,
	output [7:0] yCoordinate,
	output [2:0] colorToDraw,
	output drawOnVGA, doneDraw
	);

	reg [2:0] color;
	always @(*)begin
		if (erase)
			color <= 3'b011;
		else if (drawChar)
			color <= 3'b100;
		else
			color <= 3'b010;
	end

	wire [3:0] Counter;
	wire draw;
	wire load_data, load_color, counterPlus, out; // enable signals

	control1 C1(
		.clk(clock),
		.resetn(resetn),
		.go(drawChar || erase),
		.Counter(Counter),
		.load_data(load_data),
		.load_color(load_color),
		.counterPlus(counterPlus),
		.out(out),
		.draw(draw),
		.doneDraw(doneDraw)
	);

	datapath1 D1(
		.clk(clock),
		.resetn(resetn),
		.load_data(load_data),
		.counterPlus(counterPlus),
		.clear(clear),
		.out(out),
		.draw(draw),
		.data_x(data_x),
		.data_y(data_y),
		.load_color(load_color),
		.colorIn(color),
		.colorToDraw(colorToDraw),
		.Counter(Counter),
		.xCoordinate(xCoordinate),
		.yCoordinate(yCoordinate),
		.drawOnVGA(drawOnVGA)
		);
endmodule

module control1(
	input clk, resetn, go,
	input [3:0] Counter,
	output reg load_data, load_color, counterPlus, out, draw, doneDraw);

	reg [3:0] current_state, next_state;

	localparam
					WAIT	= 3'd0,
					PREPARE_TO_DRAW = 3'd1,
					DRAW	= 3'd2,
					INCREASE_COUNT 	= 3'd3;

	always @(*)
	begin: state_table
		case (current_state)
			WAIT:	next_state = go? PREPARE_TO_DRAW: WAIT;
			PREPARE_TO_DRAW:		next_state = DRAW; // load x and y into the coordinate registers
			DRAW:		next_state = INCREASE_COUNT;						// set plot to 1
			INCREASE_COUNT:	next_state = (Counter == 4'd15)? WAIT : PREPARE_TO_DRAW;
		endcase
	end


	always @(*)
	begin: enable_signals
		doneDraw = 1'b0;			// signals whether a new drawing can be started
		load_data = 1'b0;			// tells dataPath to take in the new coordinates
		load_color = 1'b0;
		counterPlus = 1'b0;		// increments the counter
		out = 1'b0; // loads the x and y into register for for vga coordinates
		draw = 1'b0;	// plot on VGA

		case (current_state)
			WAIT:	begin
						doneDraw = 1'b1;
						load_data = 1'b1;
						load_color = 1'b1;
						end
			PREPARE_TO_DRAW: begin
						out = 1'b1;
						end
			DRAW:		begin
						draw = 1'b1;
						end
			INCREASE_COUNT: begin
						counterPlus = 1'b1;
						end
		endcase
	end

	always @(posedge clk)
	begin: state_FFS
		if(!resetn)
			current_state <= WAIT;
		else
			current_state <= next_state;
	end
endmodule


module datapath1(
	input clk, resetn,
	input load_data, load_color, counterPlus, out, draw, clear,
	input [8:0] data_x,
	input [7:0] data_y,
	input [2:0] colorIn,
	output reg drawOnVGA,
	output reg [2:0] colorToDraw,
	output reg [3:0] Counter,
	output reg [8:0] xCoordinate,
	output reg [7:0] yCoordinate
	);

	reg [8:0] X;
	reg [7:0] Y;
	reg [16:0] counter_clear;
	wire [2:0] background_color;

	getBackgroundPixel bg(.clock(clk), .X(X), .Y(Y), .color(background_color));		// We will use this for clearing at the moment

	always @(posedge clk) begin
		if (!resetn) begin
			X <= 9'd0;
			Y <= 8'd16;
			colorToDraw <= background_color;			// hmm maybe use nonblocking statements...
			Counter <= 4'b0;
			counter_clear <= 17'b0;
			drawOnVGA <= 1'b0;
			xCoordinate <= 9'd1;
			yCoordinate <= 8'd16;
		end
		else if (clear) begin
			X <= counter_clear[8:0];				// the next 3 lines aren't unblocking for the sake of getting info as fast as possible and changing immediately
			Y <= counter_clear [16:9];			// this shouldn't have any effect on the functionality
			colorToDraw <= background_color;
			xCoordinate <= counter_clear[8:0];
			yCoordinate <= counter_clear[16:9];
			if (counter_clear[16:9] < 9'd240) begin		// This will allow the counter to draw from row 0 to 239
				counter_clear <= counter_clear + 1'b1;
			end
			drawOnVGA <= 1'b1;
		end

		else begin
			if (load_data) begin
				X <= data_x;
				Y <= data_y;
				Counter <= 4'b0;
			end
			if (load_color) begin
				colorToDraw <= colorIn;
			end
			if (counterPlus) begin
				Counter <= Counter +1'b1;
			end
			if (draw || out) begin
				drawOnVGA <= 1'b1;
			end
			else
				drawOnVGA <= 1'b0;
			if (out) begin
				xCoordinate <= X + Counter[1:0];
				yCoordinate <= Y + Counter [3:2];
			end
		end
	end

endmodule
