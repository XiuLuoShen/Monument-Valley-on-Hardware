// This files contains the modules needed to draw the map for a given state
// After it has drawn the map, it will draw the character at the appropropriate location

module DrawMapFSM(
  input clock, drawMap,
  input [3:0] gameState,
  // input about info for where the character is when the map changes
  input [8:0] x_pos,
  input [7:0] y_pos,

  // output for VGA
  output reg drawOnVGA,
  output reg [2:0] color,
  output reg [8:0] X,
  output reg [7:0] Y,
  output doneRedraw  // Send to gameState to tell it that the update has been completed
);

  wire done, draw, nextPixel, doneChar, drawChar, initialize; // connections between the modules

  // ********************************** FOR THE VGA OUTPUT *************************
  wire drawOnVGA_char, drawOnVGA_Map;   // connected to output
  wire [2:0] color_char, color_BG;
  wire [8:0] X_char, X_BG;
  wire [7:0] Y_char, Y_BG;

  always @(*) begin
    if (drawChar) begin
      X = X_char;
      Y = Y_char;
      drawOnVGA = drawOnVGA_char;
      color = color_char;
    end
    else begin
      X = X_BG;
      Y = Y_BG;
      drawOnVGA = drawOnVGA_Map;
      color = color_BG;
    end
  end
// *********************************************************

  DrawMapControl dmControl(
    .clock(clock),
    .go(drawMap),
    .done(done),
    .doneChar(doneChar),
    .nextPixel(nextPixel),
    .draw(draw),
    .drawChar(drawChar),
    .doneRedraw(doneRedraw),
    .initialize(initialize)
  );

  DrawMapDataPath dmDP(
    .clock(clock),
    .initialize(initialize),
    .draw(draw),
    .nextPixel(nextPixel),
    .gameState(gameState),
    .drawOnVGA(drawOnVGA_Map),
    .done(done),
    .X(X_BG),
    .Y(Y_BG),
    .color(color_BG)
  );

  // Used for redrawing the sprite after the background has been drawn
  spriteDrawer drawer(
		.clock(clock),
		.data_x(x_pos),
		.data_y(y_pos),
		.resetn(!initialize),
		.drawChar(drawChar),
		.drawBG(1'b0),
		.xCoordinate(X_char),
		.yCoordinate(Y_char),
		.drawOnVGA(drawOnVGA_char),
		.colorToDraw(color_char),
		.doneDraw(doneChar)
		);

endmodule

module DrawMapControl(
  input clock, go, done, doneChar,
  output reg nextPixel, draw, drawChar, doneRedraw, initialize
);

  reg [2:0] current_state, next_state;

  localparam
    INACTIVE = 3'd0,
    WAIT_COLOR = 3'd1,
    DRAW = 3'd2,
    NEXT_PIXEL= 3'd3,
    DRAW_CHAR = 3'd4,
    WAIT_CHAR = 3'd5,
    DONE = 3'd6;

  always @(*) begin // state_table
    case(current_state)
      INACTIVE: next_state = go? WAIT_COLOR: INACTIVE;           // Waiting for clear command
      WAIT_COLOR: next_state = DRAW;                // Wait state so we can get the color from ROM
      DRAW: next_state = NEXT_PIXEL;                // Draw the pixel
      NEXT_PIXEL: next_state = done? DRAW_CHAR: WAIT_COLOR;  // Get the next pixel or go to done
      DRAW_CHAR: next_state = WAIT_CHAR;              // Draw the character on the screen
      WAIT_CHAR: next_state = doneChar? DONE: WAIT_CHAR;
      DONE: next_state = go? DONE: INACTIVE;        // Done clearing the screen
      default: next_state = INACTIVE;
    endcase
  end

  always @(*) begin // enable_signals
    draw = 1'b0;
    nextPixel = 1'b0;
    drawChar = 1'b0;
    doneRedraw = 1'b0;
    initialize = 1'b0;

    case(current_state)
      INACTIVE: initialize = 1'b1;
      DRAW: draw = 1'b1;
      NEXT_PIXEL: nextPixel = 1'b1;
      DRAW_CHAR: drawChar = 1'b1;
	    WAIT_CHAR: drawChar = 1'b1;
      DONE: doneRedraw = 1'b1;
      default: begin
        draw = 1'b0;
        nextPixel = 1'b0;
        drawChar = 1'b0;
      end
    endcase
    end

    always @(posedge clock) begin
      if (!go)
        current_state <= INACTIVE;
      else
        current_state <= next_state;
    end
endmodule


module DrawMapDataPath(
  input clock, initialize, draw, nextPixel,
  input [3:0] gameState,
  output reg drawOnVGA, done,
  output reg [8:0] X,
  output reg [7:0] Y,
  output [2:0] color
);
  reg [8:0] xPixel;
  reg [7:0] yPixel;

  // assuming its possible to have multiple accessers to ROM
  getBackgroundPixel bg(.clock(clock), .gameState(gameState), .X(xPixel), .Y(yPixel), .color(color));

  always @(posedge clock) begin
    if (initialize) begin
      xPixel = 9'b0;
      yPixel = 8'b0;
      drawOnVGA = 1'b0;
      done = 1'b0;
    end

    else begin
      if (draw) begin
        X <= xPixel;
        Y <= yPixel;
        drawOnVGA <= 1'b1;
	   end
      else
        drawOnVGA <= 1'b0;

      // get the next pixel
      if (nextPixel) begin
        if (xPixel == 9'd319 && yPixel < 8'd239) begin
          yPixel <= yPixel + 1'b1;
          xPixel <= 9'b0;
        end
        else if (yPixel < 8'd239) begin
          xPixel <= xPixel + 1'b1;
        end
        else
          done <= 1'b1;
      end
    end
  end

endmodule
