// These modules control the state of the game
// States change when the character is on an activation square and presses a key
// Enable signal is required to ensure that states don't change back and forth immediately

module GameState(
  input clock, resetn, spriteDead, doneRedraw, doneAnimation,
  input activate,
  // Position of the sprite
  input [8:0] X,
  input [7:0] Y,

  output reg drawMap, startAnimation,
  output [3:0] gameState
);
  reg [3:0] currentState, nextState;
  assign gameState = currentState;

  // States called UPDATE_X refer to when the background is being redrawn to reflect the change
  // Might require wait states between update and formed states
  localparam
    DRAW_INITIAL = 4'd0,
    INITIAL = 4'd1,
    UPDATE_BRIDGE_1 = 4'd2,
    FORMED_BRIDGE_1 = 4'd3,
    UPDATE_BRIDGE_2 = 4'd4,
    FORMED_BRIDGE_2 = 4'd5,
    UPDATE_BRIDGE_3 = 4'd6,
    FORMED_BRIDGE_3 = 4'd7,
    ANIMATE_PILLAR = 4'd8,
    UPDATE_PILLAR = 4'd9,
    PILLAR_RISED = 4'd10,
    FINISHED_GAME = 4'd11;


  // state_table
  always @(*) begin
    case(currentState)
      DRAW_INITIAL: begin
        if (doneRedraw && !activate)
          nextState = INITIAL;
        else
          nextState = DRAW_INITIAL;
        end

      INITIAL: begin
        if (X >= 9'd120 && X <= 9'd125 && Y >= 9'd156 && Y <= 9'd161 && activate)
          nextState = UPDATE_BRIDGE_1;
        else
          nextState = INITIAL;
        end

      UPDATE_BRIDGE_1: begin
        if (doneRedraw && !activate)
          nextState = FORMED_BRIDGE_1;
        else
          nextState = UPDATE_BRIDGE_1;
        end

      FORMED_BRIDGE_1: begin
        if (X >= 9'd189 && X <= 9'd194 && Y >= 9'd151 && Y <= 9'd156 && activate)     // Proceed to next state
          nextState = UPDATE_BRIDGE_2;
        else if (X >= 9'd120 && X <= 9'd125 && Y >= 9'd156 && Y <= 9'd161 && activate)  // Return to previous
          nextState = DRAW_INITIAL;
        else
          nextState = FORMED_BRIDGE_1;
        end

      UPDATE_BRIDGE_2: begin
        if (doneRedraw && !activate)
          nextState = FORMED_BRIDGE_2;
        else
          nextState = UPDATE_BRIDGE_2;
        end

      FORMED_BRIDGE_2:  begin
        if (X >= 9'd177 && X <= 9'd182 && Y >= 9'd213 && Y <= 9'd218 && activate)     // Proceed to next state
          nextState = UPDATE_BRIDGE_3;
        else if (X >= 9'd189 && X <= 9'd194 && Y >= 9'd151 && Y <= 9'd156 && activate)  // Return to previous
          nextState = UPDATE_BRIDGE_1;
        else
          nextState = FORMED_BRIDGE_2;
        end

      UPDATE_BRIDGE_3: begin
        if (doneRedraw && !activate)
          nextState = FORMED_BRIDGE_3;
        else
          nextState = UPDATE_BRIDGE_3;
        end

      FORMED_BRIDGE_3:  begin
        if (X == 9'd124 && Y == 9'd158 && activate)     // Proceed to next state
          nextState = ANIMATE_PILLAR;
        else if (X == 9'd180 && Y == 8'd214 && activate)  // Return to previous
          nextState = UPDATE_BRIDGE_2;
        else
          nextState = FORMED_BRIDGE_3;
        end
      ANIMATE_PILLAR : begin
        if (doneAnimation)
          nextState = UPDATE_PILLAR;
        else
          nextState = ANIMATE_PILLAR;
      end
      UPDATE_PILLAR: begin
        if (doneAnimation && !activate)
          nextState = PILLAR_RISED;
        else
          nextState = UPDATE_PILLAR;
        end

      PILLAR_RISED: begin
        if (X >= 9'd156 && (Y <= 9'd55))
          nextState = FINISHED_GAME;
        else
          nextState = PILLAR_RISED;
        end

      FINISHED_GAME:
        nextState = FINISHED_GAME;
      default:  nextState = DRAW_INITIAL;
    endcase
  end


  // TELL THE MAPDRAWER TO DRAW THE MAP AT THESE STATES
  always @(*) begin
    if (currentState == DRAW_INITIAL || currentState == UPDATE_BRIDGE_1 || currentState ==  UPDATE_BRIDGE_2 || currentState == UPDATE_BRIDGE_3 ||
        currentState == ANIMATE_PILLAR || currentState == FINISHED_GAME) begin
        drawMap = 1'b1;
      end
    else
      drawMap = 1'b0;
    
    if (currentState == ANIMATE_PILLAR)
      startAnimation = 1'b1;
    else
      startAnimation = 1'b0;

  end


  always @(posedge clock) begin
    if (!resetn)
      currentState = DRAW_INITIAL;
    else
      currentState = nextState;
  end
endmodule
