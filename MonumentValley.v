// This the top level module to be instantiated in the FPGA module for our game, Monument Valley

module MonumentValley(
  input clock, resetn, drawMap, move,
  input [2:0] dir,
  output reg plot,      // Connects to vga adapter telling to draw pixel X, Y with color
  output reg [2:0] color,
  output reg [8:0] X,   // Coordinates for the vga adapater to draw at
  output reg [7:0] Y
);

wire drawOnVGA_Sprite;
wire drawOnVGA_Map;			// Maybe connect this to map later
always @(*) begin
  if (drawMap)
    plot = drawOnVGA_Map;
  else if (move)
    plot = drawOnVGA_Sprite;
  else
    plot = 1'b0;
end

wire [8:0] X_Map;
wire [7:0] Y_Map;
wire [8:0] X_sprite;
wire [7:0] Y_sprite;

always @(*) begin
  if (drawMap) begin
    X = X_Map;
    Y = Y_Map;
  end
  else begin
    X = X_sprite;
    Y = Y_sprite;
  end
end

wire [2:0] color_sprite;
wire [2:0] color_Map;
always @(*) begin
  if (move)
    color = color_sprite;
  else
    color = color_Map;
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

  wire doneRedraw;
DrawMapFSM MapDrawer(
    .clock(clock),
    .drawMap(drawMap),     // not sure if resetn is needed
	 .resetn(resetn),
    .drawOnVGA(drawOnVGA_Map),
	 .gameState(4'b000),
    .color(color_Map),
    .X(X_Map),
    .Y(Y_Map),
	 .doneRedraw(doneRedraw)
  );

endmodule
