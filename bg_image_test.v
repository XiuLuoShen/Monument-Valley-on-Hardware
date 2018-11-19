module vga_test(
	input [3:0] KEY,
	input [9:0] SW,
	input CLOCK_50,
	output	[7:0] VGA_R, VGA_G, VGA_B,				// these might have to be [9:0], honestly not sure
	output 	VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK,
	output [9:0] LEDR
	);

	wire resetn = KEY[0];
	wire move = ~KEY[1];
	wire resetnMonitor = KEY[3];
	wire clear = ~KEY[2];
	wire [1:0] dir = SW[1:0];
	assign LEDR[3] = clear;			// LED to indicate when the board is being cleared/reset

	wire plot;
	wire [2:0] color;
	wire [8:0] X;
	wire [7:0] Y;

	MonumentValley Game(
		.clock(CLOCK_50),
		.resetn(resetn),
		.move(move),
		.clear(clear),
		.dir(dir),
		.plot(plot),
		.color(color),
		.X(X),
		.Y(Y),
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
