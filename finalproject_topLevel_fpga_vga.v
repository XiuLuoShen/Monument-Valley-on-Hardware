// This is the highest level module of the project

module finalProject_Top(
	input [3:0] KEY,
	input [9:0] SW,
	input CLOCK_50,
	output	[7:0] VGA_R, VGA_G, VGA_B,				// these might have to be [9:0], honestly not sure
	output 	VGA_HS, VGA_VS, VGA_BLANK, VGA_SYNC, VGA_CLK,
	output [9:0] LEDR

	// for the PS2 controller
	input reset,
	input [7:0] the_command,
	input send_command,
	inout PS2_CLK,
	inout PS2_DAT,
	output command_was_sent,
	output error_communication_timed_out,
	output [7:0] received_data,
	output received_data_en
	);

	wire resetn = KEY[0];
	wire move = ~KEY[1];
	wire activate = ~KEY[2];
	wire resetnMonitor = KEY[3];

  // potentially reg for dir
	wire [1:0] dir = SW[1:0];
	assign LEDR[3] = activate;			// LED to indicate when the board is being cleared/reset

	wire plot;
	wire [2:0] color;
	wire [8:0] X;
	wire [7:0] Y;


	// PS2 wires
	wire ps2_reset = reset;
	wire command = the_command;
	wire send_command = send_command;
	wire ps2_clck = PS2_CLK;
	wire ps2_dat = PS2_DAT;
	wire command_was_sent = command_was_sent;
	wire error_time_out = error_communication_timed_out;
	wire received_data_en = received_data_en;


	PS2_Controller Keyboard(
		.clock(CLOCK_50),
		.resetn(ps2_reset),
		.command(the_command),
		.send_command(send_command),
		.ps2_clck(ps2_clck),	// PS2 Clock
	 	.ps2_dat(ps2_dat),	// PS2 Data
		.command_was_sent(command_was_sent),
		.error_time_out(error_communication_timed_out),
		.received_data(received_data),
		.received_data_en(received_data_en)
	);

		// PS2 output wires
	wire data = received_data;
	wire data_en = received_data_en;

	always @ (posedge CLOCK_50)
		if (received_data_en = 1'b1) begin
			move = 1'b1;
			if (received_data_en == 8'h75) // UP; topleft
			  	dir = 8'd2;
			else if (received_data_en == 8'h6B) // LEFT; bottomleft
			  	dir = 8'd0;
			else if (received_data_en == 8'h72) // DOWN; bottomright
			  	dir = 8'd1;
			else if (received_data_en == 8'h74) // RIGHT; topright
			  	dir = 8'd0;
			else dir = 8'd0;
		end
		else if (received_data_en = 1'b0)
			move = 1'b0;
	endcase

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
