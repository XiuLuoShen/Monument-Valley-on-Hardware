// This file contains the modules needed to clear the screen to its original state.

module clearScreenFSM(
  input clock, clear,     // not sure if resetn is needed
  output drawOnVGA,
  output [2:0] color,
  output [8:0] X,
  output [7:0] Y
);

  wire done, draw, nextPixel;
//  assign X = xPixel;
//  assign Y = yPixel;

  clearScreenControl  csControl(
    .clock(clock),
    .go(clear),
    .done(done),
    .nextPixel(nextPixel),
    .draw(draw)
  );

  clearScreenDataPath csDP(
    .clock(clock),
    .go(clear),
    .draw(draw),
    .nextPixel(nextPixel),
    .drawOnVGA(drawOnVGA),
    .done(done),
    .X(X),
    .Y(Y),
    .color(color)
  );

endmodule

module clearScreenControl(
  input clock, go, done,
  output reg nextPixel, draw
);

  reg [2:0] current_state, next_state;

  localparam
    INACTIVE = 3'd0,
    WAIT_COLOR = 3'd1,
    DRAW = 3'd2,
    NEXT_PIXEL= 3'd3,
    DONE = 3'd4;

  always @(*) begin // state_table
    case(current_state)
      INACTIVE: next_state = go? WAIT_COLOR: INACTIVE;           // Waiting for clear command
      WAIT_COLOR: next_state = DRAW;                // Wait state so we can get the color from ROM
      DRAW: next_state = NEXT_PIXEL;                // Draw the pixel
      NEXT_PIXEL: next_state = done? DONE: WAIT_COLOR;  // Get the next pixel or go to done
      DONE: next_state = go? DONE: INACTIVE;        // Done clearing the screen
      default: next_state = INACTIVE;
    endcase
  end

  always @(*) begin // enable_signals
    draw = 1'b0;
    nextPixel = 1'b0;

    case(current_state)
      DRAW: draw = 1'b1;
      NEXT_PIXEL: nextPixel = 1'b1;
      default: begin
        draw = 1'b0;
        nextPixel = 1'b0;
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


module clearScreenDataPath(
  input clock, draw, nextPixel, go,
  output reg drawOnVGA, done,
  output reg [8:0] X,
  output reg [7:0] Y,
  output [2:0] color
);
  reg [8:0] xPixel;
  reg [7:0] yPixel;

  // assuming its possible to have multiple accessers to ROM
  getBackgroundPixel bg(.clock(clock), .X(xPixel), .Y(yPixel), .color(color));

  always @(posedge clock) begin
    if (!go) begin
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
