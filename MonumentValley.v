// This the top level module to be instantiated in the FPGA module for our game, Monument Valley

module MonumentValley(
  input clock, resetn, clear, move,
  input [2:0] dir,
  output reg plot,      // Connects to vga adapter telling to draw pixel X, Y with color
  output reg [2:0] color,
  output reg [8:0] X,   // Coordinates for the vga adapater to draw at
  output reg [7:0] Y,
);

wire drawOnVGA_Sprite;
wire drawOnVGA_clear;			// Maybe connect this to map later
always @(*) begin
  if (clear)
    plot = drawOnVGA_clear;
  else if (move)
    plot = drawOnVGA_Sprite;
  else
    plot = 1'b0;
end

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

wire [2:0] color_sprite;
wire [2:0] color_clear;
always @(*) begin
  if (move)
    color = color_sprite;
  else
    color = color_clear;
end

spriteFSM sprite(
  .clock(clock),
  .resetn(resetn),
  .move(move),
  .dir(dir),
  .plot(drawOnVGA_Sprite),
  .color(color_sprite),
  .xCoord(X_sprite),
  .yCoord(Y_sprite)
  );

clearScreenFSM clearScreen(
    .clock(clock),
    .clear(clear),     // not sure if resetn is needed
    .drawOnVGA(drawOnVGA_clear),
    .color(color_clear),
    .X(X_clear),
    .Y(Y_clear)
  );

endmodule
