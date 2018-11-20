// These modules control the state of the game
// States change when the character is on an activation square and presses a key
// Enable signal is required to ensure that states don't change back and forth immediately

module GameState(
  input clock, resetn, spriteDead, doneRedraw,
  input activate,
  input [8:0] charX,
  input [7:0] charY,
  // might need an output that connects to drawMap telling to draw
  output reg [3:0] gameState
);
  reg [3:0] currentState, nextState;

  // States called UPDATE_X refer to when the background is being redrawn to reflect the change
  // Might require wait states between update and formed states
  localparam
<<<<<<< HEAD
    DRAW_INITIAL = 4'd10,
=======
    DRAW_INITIAL = 4'd0,
>>>>>>> aeea77dc1ebf75a5d5b062b5157120fe07828f92
    INITIAL = 4'd0,
    UPDATE_BRIDGE_1 = 4'd1,
    FORMED_BRIDGE_1 = 4'd2,
    UPDATE_BRIDGE_2 = 4'd3,
    FORMED_BRIDGE_2 = 4'd4,
    UPDATE_BRIDGE_3 = 4'd5,
    FORMED_BRIDGE_3 = 4'd6,
    UPDATE_PILLAR = 4'd7,
    PILLAR_RISED = 4'd8,
    FINISHED_GAME = 4'd9;


  // state_table
  always @(*) begin
    case(currentState)
      DRAW_INITIAL: begin
        if (doneRedraw)
          nextState = INITIAL;
        else
          nextState = DRAW_INITIAL;
        end

      INITIAL: begin
        if (X == 9'bxxxxxxxxx && Y == 9'bxxxxxxxxx && activate)
          nextState = UPDATE_BRIDGE_1;
        else
          nextState = INITIAL;
        end

      UPDATE_BRIDGE_1: begin
        if (doneRedraw)
          nextState = FORMED_BRIDGE_1;
        else
          nextState = UPDATE_BRIDGE_1;
        end

      FORMED_BRIDGE_1: begin
        if (X == 9'bxxxxxxxxx && Y == 9'bxxxxxxxxx && activate)     // Proceed to next state
          nextState = UPDATE_BRIDGE_2;
        else if (X == 9'bxxxxxxxxx && Y == 9'bxxxxxxxxx && activate)  // Return to previous
          nextState = DRAW_INITIAL;
        else
          nextState = FORMED_BRIDGE_1;
        end

      UPDATE_BRIDGE_2: begin
        if (doneRedraw)
          nextState = FORMED_BRIDGE_2;
        else
          nextState = UPDATE_BRIDGE_2;
        end

      FORMED_BRIDGE_2:  begin
        if (X == 9'bxxxxxxxxx && Y == 9'bxxxxxxxxx && activate)     // Proceed to next state
          nextState = UPDATE_BRIDGE_3;
        else if (X == 9'bxxxxxxxxx && Y == 9'bxxxxxxxxx && activate)  // Return to previous
          nextState = UPDATE_BRIDGE_1;
        else
          nextState = FORMED_BRIDGE_2;
        end

      UPDATE_BRIDGE_3: begin
        if (doneRedraw)
          nextState = FORMED_BRIDGE_3;
        else
          nextState = UPDATE_BRIDGE_3;
        end

      FORMED_BRIDGE_3:  begin
        if (X == 9'bxxxxxxxxx && Y == 9'bxxxxxxxxx && activate)     // Proceed to next state
          nextState = UPDATE_PILLAR;
        else if (X == 9'bxxxxxxxxx && Y == 9'bxxxxxxxxx && activate)  // Return to previous
          nextState = UPDATE_BRIDGE_2;
        else
          nextState = FORMED_BRIDGE_3;
        end

      UPDATE_PILLAR: begin
        if (doneRedraw)
          nextState = PILLAR_RISED;
        else
          nextState = UPDATE_PILLAR;
        end

      PILLAR_RISED: begin
        if (X == 9'bxxxxxxxxx && Y == 9'bxxxxxxxxx)
          nextState = FINISHED_GAME;
        else
          nextState = PILLAR_RISED;
        end

      FINISHED_GAME:
        nextState = FINISHED_GAME;
      default:  nextState = DRAW_INITIAL;
    endcase
  end

  // always @(*) begin
  //   case(currentState)
  //     INITIAL:
  //     UPDATE_BRIDGE_1:
  //     FORMED_BRIDGE_1:
  //     UPDATE_BRIDGE_2:
  //     FORMED_BRIDGE_2:
  //     UPDATE_BRIDGE_3:
  //     FORMED_BRIDGE_3:
  //     UPDATE_PILLAR:
  //     PILLAR_RISED:
  //     FINISHED_GAME:
  //     default:  nextState = INITIAL;
  //   endcase
  // end

  always @(posedge clock) begin
    if (!resetn)
      currentState = DRAW_INITIAL;
    else
      currentState = nextState;
  end
endmodule
