module lab7pt3_fpga(
	input [3:0] KEY,
	input CLOCK_50,
	output	[7:0] VGA_R, VGA_G, VGA_B,
	output 	VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK
	);

	wire resetnn = KEY[0];
	wire resetnnMonitor = KEY[3];
	wire go = ~KEY[1];

	wire [7:0] X;
	wire [6:0] Y;
	wire [2:0] colorToDraw;
	wire plot;

	mainFSM main(
		.resetn(resetn),
		.go(go),
		.clock(CLOCK_50),
		.X(X),
		.Y(Y),
		.colorToDraw(colorToDraw),
		.plot(plot)
	);

	defparam display.RESOLUTION = "320x240";
	defparam display.MONOCHROME = "FALSE";
	defparam display.BITS_PER_COLOUR_CHANNEL = 1;
	defparam display.BACKGROUND_IMAGE = "map.mif";

	vga_adapter display(
		.resetnn(resetnnMonitor),
		.clock(CLOCK_50),
		.colour(colorToDraw),
		.x(X),
		.y(Y),
		.plot(plot),
		/* Signals for the DAC to drive the monitor. */
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK),
		.VGA_SYNC(VGA_SYNC),
		.VGA_CLK(VGA_CLK)
	);

endmodule


module mainFSM(
	input resetnn, go, clock,
	output plot,
	output [7:0] X,
	output [6:0] Y,
	output [2:0] colorToDraw
	// output drawOnVGA
	);

	wire [7:0] data_x;
	wire [6:0] data_y;
	wire [2:0] colorIn;
	wire ld_x, ld_y, doneDraw;
	wire offreset = 1'b0;



  pt2FSM drawer(
		.data_x(data_x),
		.data_y(data_y),
		.reset(resetn),
		.clear(offreset),
		.plot(ld_y),
		.inputX(ld_x),
		.clock(clock),
		.xCoordinate(X),
		.yCoordinate(Y),
		.colorIn(colorIn),
		.colorToDraw(colorToDraw),
		.drawOnVGA(plot),
		.doneDraw(doneDraw)	// setToHighWhenDoneDrawing
	);

endmodule



module pt2FSM(
	input [8:0] data_x,
	input [7:0] data_y,
	input resetn, plot, inputX, clock, clear,
	input [2:0] colorIn,
	output [2:0] colorToDraw,
	output [8:0] xCoordinate,
	output [7:0] yCoordinate,
	output drawOnVGA, doneDraw
	);

	wire [3:0] Counter;
	wire draw;
	wire load_x, load_y, load_color, counterPlus, out; // enable signals

	control1 C1(
		.clk(clock),
		.resetn(resetn),
		.inputX(inputX),
		.plot(plot),
		.Counter(Counter),
		.load_x(load_x),
		.load_y(load_y),
		.load_color(load_color),
		.counterPlus(counterPlus),
		.out(out),
		.draw(draw),
		.doneDraw(doneDraw)
	);

	datapath1 D1(
		.clk(clock),
		.resetn(resetn),
		.load_x(load_x),
		.load_y(load_y),
		.load_color(load_color),
		.counterPlus(counterPlus),
		.clear(clear),
		.out(out),
		.draw(draw),
		.data_x(data_x),
		.data_y(data_y),
		.colorIn(colorIn),
		.colorToDraw(colorToDraw),
		.Counter(Counter),
		.xCoordinate(xCoordinate),
		.yCoordinate(yCoordinate),
		.drawOnVGA(drawOnVGA)
		);
endmodule

module control1(
	input clk, resetn, inputX, plot,
	input [3:0] Counter,
	output reg load_x, load_y, load_color, counterPlus, out, draw, doneDraw);

	reg [3:0] current_state, next_state;

	localparam
					LOADX	= 3'd0,
					LOADY = 3'd1,
					PREPARE_TO_DRAW = 3'd2,
					DRAW	= 3'd3,
					INCREASE_COUNT 	= 3'd4;

	always @(*)
	begin: state_table
		case (current_state)
			LOADX:	next_state = inputX? LOADY: LOADX;
			LOADY:	next_state = plot? PREPARE_TO_DRAW:LOADY;
			PREPARE_TO_DRAW:		next_state = DRAW; // load x and y into the coordinate registers
			DRAW:		next_state = INCREASE_COUNT;						// set plot to 1
			INCREASE_COUNT:	next_state = (Counter == 4'd15)? LOADX : PREPARE_TO_DRAW;
		endcase
	end

	always @(*)
	begin: enable_signals
		doneDraw = 1'b0;
		load_x = 1'b0;
		load_y = 1'b0;
		load_color = 1'b0;
		counterPlus = 1'b0;
		out = 1'b0; // loads the x and y into register for for vga coordinates
		draw = 1'b0;	// plot on VGA
		case (current_state)
			LOADX:	begin
						doneDraw = 1'b1;
						load_x = 1'b1;
						end
			LOADY:	begin
						load_y = 1'b1;
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
			current_state <= LOADX;
		else
			current_state <= next_state;
	end
endmodule


module datapath1(
	input clk, resetn,
	input load_x, load_y, load_color, counterPlus, out, draw, clear,
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


	// x register
	always @(posedge clk) begin
		if (!resetn || clear)
			X <= 8'b0;
		else if (load_x)
			X <= data_x;
		else X <= X;
	end

	// y register
	always @(posedge clk) begin
		if (!resetn || clear)
			Y <= 7'b0;
		else if (load_y)
			Y <= data_y;
		else Y <= Y;
	end

	// color to draw
	always @(posedge clk) begin
		if (!resetn)
			colorToDraw <= 3'b000;
		else if (clear)
			colorToDraw <= 3'b000;
		else if (load_color)
			colorToDraw <= colorIn;
		else if (draw)
			colorToDraw <= colorToDraw;
		end

	// Counter for normal drawing
	always @(posedge clk) begin
		if (!resetn || load_x)
			Counter <= 4'b0;
		else if (counterPlus)
			Counter <= Counter + 1'b1;
		else
			Counter <= Counter;
	end


		// Counter for clearing
	always @(posedge clk) begin
		if (!resetn || draw)
			counter_black <= 1'b0;
		else if (clear)
			if (&(counter_black) != 1'b1)
				counter_black <= counter_black+1'b1;
		else
			counter_black <= 1'b0;
		end

	// drawing
	always @(posedge clk) begin
		if (draw || clear)
			drawOnVGA <= 1'b1;
		else
			drawOnVGA <= 1'b0;
	end


	// Output registers
	always @(posedge clk) begin
		if (!resetn) begin
			xCoordinate <= 8'b0;
			yCoordinate <= 7'b0;
			end
		else if (clear) begin
			xCoordinate <= counter_black[8:0];
			yCoordinate <= counter_black[16:9];
			end
		else begin
			if (out) begin
				xCoordinate <= X+Counter[1:0];
				yCoordinate <= Y+Counter[3:2];
				end
			end
	end

endmodule
