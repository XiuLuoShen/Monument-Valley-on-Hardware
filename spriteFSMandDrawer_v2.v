// This file contains the top level module for the sprite and the FSM for the spriteDrawer
// Currently spriteDrawer attempts to redraw the BG at the old sprite location and
// then draws a new red square (the sprite) at the new location

module spriteFSM(
	input clock, resetn, move,
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
		.drawChar(drawChar),
		.drawBG(drawBG),
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
	input resetn, drawChar, drawBG, clock,
	output [8:0] xCoordinate,
	output [7:0] yCoordinate,
	output [2:0] colorToDraw,
	output drawOnVGA, doneDraw
	);

	wire [3:0] Counter;
	wire draw;
	wire load_data, load_color, counterPlus, out; // enable signals

	control1 C1(
		.clk(clock),
		.resetn(resetn),
		.drawChar(drawChar),
		.drawBG(drawBG),
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
		.out(out),
		.draw(draw),
		.drawChar(drawChar),
		.drawBG(drawBG),
		.data_x(data_x),
		.data_y(data_y),
		.load_color(load_color),
		.colorToDraw(colorToDraw),
		.Counter(Counter),
		.xCoordinate(xCoordinate),
		.yCoordinate(yCoordinate),
		.drawOnVGA(drawOnVGA)
		);
endmodule

module control1(
	input clk, resetn, drawChar, drawBG,
	input [3:0] Counter,
	output reg load_data, load_color, counterPlus, out, draw, doneDraw);

	reg [3:0] current_state, next_state;

	localparam
					WAIT	= 3'd0,
					PREPARE_TO_DRAW = 3'd1,
					GET_COLOR = 3'd2,
					DRAW	= 3'd3,
					INCREASE_COUNT 	= 3'd4,
					DONE = 3'd5;

	always @(*)
	begin: state_table
		case (current_state)
			WAIT:	next_state = (drawChar || drawBG)? PREPARE_TO_DRAW: WAIT;
			PREPARE_TO_DRAW:		next_state = GET_COLOR; // load x and y into the coordinate registers
			GET_COLOR: next_state = DRAW;
			DRAW:		next_state = INCREASE_COUNT;						// set plot to 1
			INCREASE_COUNT:	next_state = (Counter == 4'd15)? DONE : PREPARE_TO_DRAW;
			DONE:	next_state = (drawChar) ? DONE: WAIT;
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
						load_data = 1'b1;
						end

			PREPARE_TO_DRAW: begin
						out = 1'b1;
						end
			GET_COLOR: load_color = 1'b1;

			DRAW:		begin
						draw = 1'b1;
						end

			INCREASE_COUNT: begin
						counterPlus = 1'b1;
						end

			DONE:	doneDraw = 1'b1;
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
	input clk, resetn, drawBG, drawChar, // inputs from outside the FSM
	input load_data, load_color, counterPlus, out, draw,
	input [8:0] data_x,
	input [7:0] data_y,
//	input [2:0] colorIn,
	output reg drawOnVGA,
	output reg [2:0] colorToDraw,
	output reg [3:0] Counter,
	output reg [8:0] xCoordinate,
	output reg [7:0] yCoordinate
	);

	reg [8:0] X;
	reg [7:0] Y;

	wire [2:0] background_color;
	reg [2:0] color;			// the color of the current pixel we're trying to draw
	// this is not the output for insurance, instead the color output is loaded from this

	getBackgroundPixel bg(.clock(clk), .X(X + Counter[1:0]), .Y(Y + Counter[3:2]), .color(background_color));

	// should this use the clock as well?
	always @(*) begin
		if (drawBG)
			color = background_color;
		else if (drawChar)
			color = 3'b100;
		else
			color = 3'b100;
	end


	always @(posedge clk) begin
		if (!resetn) begin
			X <= 9'd0;
			Y <= 8'd16;
			colorToDraw <= background_color;			// hmm maybe use nonblocking statements...
			Counter <= 4'b0;
			drawOnVGA <= 1'b0;
			xCoordinate <= 9'd1;
			yCoordinate <= 8'd16;
		end

		else begin
			if (load_data) begin
				X <= data_x;
				Y <= data_y;
				Counter <= 4'b0;
			end

			if (load_color && drawBG) begin
				colorToDraw <= background_color;
			end
			else if (load_color) begin
				colorToDraw <= color;
			end

			if (counterPlus) begin
				Counter <= Counter +1'b1;
			end

			if (draw) begin
				drawOnVGA <= 1'b1;
			end
			else
				drawOnVGA <= 1'b0;

			if (out) begin
				xCoordinate <= X + Counter[1:0];
				yCoordinate <= Y + Counter[3:2];
			end
		end
	end

endmodule
