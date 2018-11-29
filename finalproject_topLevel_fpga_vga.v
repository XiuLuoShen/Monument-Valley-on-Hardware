// This is the highest level module of the project

module finalProject_Top(
	input [3:0] KEY,
	input [9:0] SW,
	input CLOCK_50,
	output	[7:0] VGA_R, VGA_G, VGA_B,				// these might have to be [9:0], honestly not sure
	output 	VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK,
	output [9:0] LEDR,
	input [7:0] the_command,
	input send_command,
	inout PS2_CLK,
	inout PS2_DAT
	);

	wire resetn = KEY[0];
//	wire move = ~KEY[1];
	wire activate = ~KEY[2];
	wire resetnMonitor = KEY[3];
	wire resetKeyboard = ~KEY[3];

	reg move;
	reg [1:0] dir;

	wire plot;
	wire [2:0] color;
	wire [8:0] X;
	wire [7:0] Y;


	// PS2 wires
//	wire ps2_reset = reset;
//	wire command = the_command;
//	wire send_cmd = send_command;
//	wire cmd_was_sent = command_was_sent;
//	wire error_time_out = error_communication_timed_out;

	// PS2 output wires
	wire [7:0] data;
	wire data_en;
	reg data_sent;
	assign LEDR[0] = move;
	assign LEDR[9:2] = data;


	PS2_Controller Keyboard(
		.CLOCK_50(CLOCK_50),
		.reset(resetKeyboard),
		.PS2_CLK(PS2_CLK),	// PS2 Clock
	 	.PS2_DAT(PS2_DAT),	// PS2 Data
		.received_data(data),
		.received_data_en(data_en)
	);

	//  wire clock2;
	// rateDivider r(
	// 	.clock(CLOCK_50),
	// 	.speed(2'b10),
	// 	.resetn(resetn),
	// 	.enableOut(clock2)
	// );


	always @(*) begin
		if (data_en == 1'b1)
			move = 1'b1;
		else if (data == 8'hF0)
			move = 1'b0;
	end

	always @(*) begin
		if (data == 8'h1D) // UP; topleft
	  	dir = 2'b11;
		else if (data == 8'h1C) // LEFT; bottomleft
	  	dir = 2'b01;
		else if (data == 8'h1B) // DOWN; bottomright
  		dir = 2'b00;
		else if (data == 8'h23) // RIGHT; topright
	  	dir = 2'b10;
		else
			dir = 2'b00;
	end

	MonumentValley Game(
		.clock(CLOCK_50),
		.resetn(resetn),
		.move(move),
		.activate(activate),
		.dir(dir),
		.plot(plot),
		.color(color),
		.X(X),
		.Y(Y)
	);


	vga_adapter display(
		.resetn(resetnMonitor),
		.clock(CLOCK_50),
		.colour(color),
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

	defparam display.RESOLUTION = "320x240";
	defparam display.MONOCHROME = "FALSE";
	defparam display.BITS_PER_COLOUR_CHANNEL = 1;
	defparam display.BACKGROUND_IMAGE = "castle.mif";
	defparam display.USING_DE1 = "TRUE";

endmodule
