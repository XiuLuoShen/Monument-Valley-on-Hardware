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
	wire clear = SW[3];


	reg plot;									// Connection to vga adapter telling to draw pixel X, Y with color
	wire drawOnVGA_Sprite;
	wire drawOnVGA_clear;			// Maybe connect this to map later
	always @(*) begin
		if (clear)
			plot = drawOnVGA_clear;
		else
			plot = drawOnVGA_Sprite;
	end

	reg [8:0] X;
	reg [7:0] Y;
	wire [8:0] X_clear;
	wire [7:0] Y_clear;
	wire [8:0] X_sprite;
	wire [7:0] Y_sprite;

	always @(*) begin
		if (clear) begin
			X = X_clear;
			Y = Y_clear;
		end
		else begin
			X = X_sprite;
			Y = Y_sprite;
		end
	end

	reg color;
	wire [2:0] color_sprite;
	wire [2:0] color_clear;
	always @(*) begin
		if (clear)
			color = color_clear;
		else
			color = color_sprite;
	end

	// direction that the sprite moves in, second bit is left right (0/1) and first bit is down up (0/1)
	wire [1:0] dir = SW[1:0];
	assign LEDR[3] = clear;			// LED to indicate when the board is being cleared

	spriteFSM sprite(
		.clock(CLOCK_50),
		.resetn(resetn),
		.move(move),
		.dir(dir),
		.plot(plot),
		.color(color),
		.xCoord(X_sprite),
		.yCoord(Y_sprite)
		);

	clearScreenFSM clearScreen(
		  .clock(CLOCK_50),
			.clear(clear),     // not sure if resetn is needed
		  .drawOnVGA(drawOnVGA),
			.color(color_clear),
			.X(X_clear),
			.Y(Y_clear)
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
