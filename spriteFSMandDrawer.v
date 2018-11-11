module spriteFSM(
	input clock, resetn, move, ld_dir, clear,
	input [1:0] dir,
	output plot,
	output [2:0] color,
	output [8:0] xCoord,
	output [7:0] yCoord
);

	wire doneDraw, drawChar, drawBG;
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
		.clear(1'b0),
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
			color <= 3'b000;
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
		doneDraw = 1'b0;
		load_data = 1'b0;
		load_color = 1'b0;
		counterPlus = 1'b0;
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
	reg [16:0] counter_black;
	
	
	always @(posedge clk) begin
		if (!resetn) begin
			X <= 9'd0;
			Y <= 8'd16;
			colorToDraw <= 3'b111;
			Counter <= 4'b0;
			counter_black <= 17'b0;
			drawOnVGA <= 1'b0;
			xCoordinate <= 9'd1;
			yCoordinate <= 8'd16;
		end
		else if (clear) begin
			colorToDraw <= 3'b111;
			if (&counter_black != 1'b1)
				counter_black <= counter_black + 1'b1;
			xCoordinate <= counter_black[8:0];
			yCoordinate <= counter_black[16:9];
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
			if (draw) begin
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