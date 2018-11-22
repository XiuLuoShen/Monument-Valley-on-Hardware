// This the top level module to be instantiated in the FPGA module for our game, Monument Valley

module MonumentValley(
  input clock, resetn, activate, move,
  input [2:0] dir,
  output reg plot,      // Connects to vga adapter telling to draw pixel X, Y with color
  output reg [2:0] color,
  output reg [8:0] X,   // Coordinates for the vga adapater to draw at
  output reg [7:0] Y
);


// Wires containing information about the game
wire [8:0] x_pos;			// Outputs from SpriteFSM regarding the character's location
wire [7:0] y_pos;
wire [3:0] gameState;	// Output from module GameState
wire drawMap;	// Output from module GameState



// *********************** Wires for plotting to VGA *******************
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
// *************************************************************


spriteFSM sprite(
  .clock(clock),
  .resetn(resetn),
  .move(move),
  .dir(dir),
  .gameState(gameState),
  .plot(drawOnVGA_Sprite),
  .color(color_sprite),
  .x_pos(x_pos),
  .y_pos(y_pos),
  .xCoord(X_sprite),
  .yCoord(Y_sprite)
  );

  wire doneRedraw;
  
DrawMapFSM MapDrawer(
    .clock(clock),
	 .gameState(gameState),
	 .x_pos(x_pos),
	 .y_pos(y_pos),
    .drawMap(drawMap),
    .drawOnVGA(drawOnVGA_Map),
    .color(color_Map),
    .X(X_Map),
    .Y(Y_Map),
	 .doneRedraw(doneRedraw)
  );

  
GameState GAME(
	.clock(clock),
	.resetn(resetn),
	.spriteDead(1'b0),	// Haven't implemented this yet
	.doneRedraw(doneRedraw),
	.X(x_pos),
	.Y(y_pos),
	.activate(activate),
	.drawMap(drawMap),
	.gameState(gameState)
 );
endmodule
