// These modules are for the FSM that work with movement

module moveSprite(
  input move, resetn, clock, ld_dir, doneChar, doneBG,
  input [1:0] dir,
  output [8:0] xCoordinate, // For 320x240 res...
  output [7:0] yCoordinate,
  output drawChar, drawBG
);

  wire validMove;
  wire wait1, waitGo, checkMove, update_pos;
  wire [8:0] X; // X location of character
  wire [7:0] Y; // Y location of character

  moveSpriteControl C(
    .clock(clock),
    .resetn(resetn),
    .move(move),
    .ld_dir(ld_dir),
    .validMove(validMove),
    .doneChar(doneChar),
    .doneBG(doneBG),
    .wait1(wait1),
    .waitGo(waitGo),
    .checkMove(checkMove),
    .drawChar(drawChar),
    .drawBG(drawBG),
    .update_pos(update_pos)
  );

  moveSpriteDataPath D(
    .clock(clock),
    .resetn(resetn),
    .wait1(wait1),
    .waitGo(waitGo),
    .checkMove(checkMove),
    .drawChar(drawChar),
    .drawBG(drawBG),
    .validMove(validMove),
    .update_pos(update_pos),
    .dir(dir),
    .X(xCoordinate),
    .Y(yCoordinate)
  );
endmodule


module moveSpriteControl(
  input move, resetn, clock, ld_dir, validMove, doneChar, doneBG,
  output reg wait1, waitGo, checkMove, drawChar, drawBG, update_pos
);

  reg [3:0] currentState, nextState;
  localparam
    WAIT1 = 4'd0,
    WAITGO = 4'd1,
    CHECK_MOVE = 4'd2,
    REDRAW_BG = 4'd3,
    WAIT_BG = 4'd4,
    UPDATE_LOC = 4'd5,
    DRAW_CHAR = 4'd6,
    WAIT_CHAR = 4'd7;

  always @(*) begin // state table
    case (currentState)
      WAIT1:         nextState = (ld_dir) ? WAITGO : WAIT1;
      WAITGO:       nextState = (move) ? CHECK_MOVE: WAITGO;
      CHECK_MOVE:   nextState = (validMove) ? REDRAW_BG : WAIT1;
      REDRAW_BG:    nextState = WAIT_BG;
      WAIT_BG:      nextState = doneBG ? UPDATE_LOC : WAIT_BG;
      UPDATE_LOC:   nextState = DRAW_CHAR;
      DRAW_CHAR:    nextState = WAIT_CHAR;
      WAIT_CHAR:    nextState = doneChar? WAIT1: WAIT_CHAR;
      default:      nextState = WAIT1;
    endcase
  end

  always @(*) begin // enable signals
    wait1 = 1'b0;
    waitGo = 1'b0;
    checkMove = 1'b0;
    drawChar = 1'b0;
    drawBG = 1'b0;
    update_pos = 1'b0;
    case (currentState)
      WAIT1: wait1 = 1'b1;
      WAITGO: begin waitGo = 1'b1; checkMove = 1'b1;  end
      CHECK_MOVE: checkMove = 1'b1;
      REDRAW_BG:  drawBG = 1'b1;
      UPDATE_LOC: update_pos = 1'b1;
      DRAW_CHAR:  drawChar = 1'b1;
    endcase
  end

  always @(posedge clock) begin
    if (!resetn)
      currentState <= WAIT1;
    else
      currentState <= nextState;
  end
endmodule

module moveSpriteDataPath(
  input clock, resetn, wait1, waitGo, checkMove, drawChar, drawBG, update_pos,
  input [1:0] dir,
  output reg validMove,
  output reg [8:0] X,
  output reg [7:0] Y
);
  reg [8:0] newX;
  reg [7:0] newY;

  always @(posedge clock) begin
    case (dir)
      0: begin  // down left
        newX = X + 1'b1;
        newY = Y + 1'b1;
        end
      1: begin  // down right
         newX = X - 1'b1;
         newY = Y + 1'b1;
        end
      2:begin   // up left
        newX = X + 1'b1;
        newY = Y - 1'b1;
        end
      3:begin // up right
        newX = X - 1'b1;
        newY = Y - 1'b1;
        end
    endcase
  end

  always @(posedge clock) begin
    if (!resetn) begin
      X <= 9'd1;  // initial sprite location
      Y <= 8'd16;
      validMove <= 1'b0;
    end

    else  begin
      if (checkMove) begin
        if (newX <= 1'b0 || newY <= 1'b0)
          validMove = 1'b0; // ensures the square does not go off screen

      	// starting point to first door
        else if (newY == 9'd222 - newX) // diagonal BL to TR
          if (newX <= 8'd122 && newX >= 8'd96)
            validMove = 1'b1;

        // door to first corner
        else if (newY == 8'd96 + newX) // diagonal TL to BR
          if (newX >= 8'd127 && newX <= 8'd181)
            validMove = 1'b1;

        // first corner to first button
        else if (newY == 9'd113 - newX)
          if (newX >= 8'd125 && newX <= 8'd181) 
            validMove = 1'b1;

        // first button to moving platform
        else if (newY == 9'd159 - newX)
          if (newX >= 8'd125 && newX <= 8'd161)
            validMove = 1'b1;

        // moving platform to island
        else if (newY == 9'd123 + newX)
          if (newX >= 8'd161 && newX <= 8'd216)
            validMove = 1'b1;

        // island
        else if (newY == 9'd178 - newX)
          if (newX >= 8'd180 && newX <= 8'd216)
            validMove = 1'b1;

        // island to first button again
        else if (newY == 9'd214 + newX)
          if (newX >= 8'd125 && newX <= 8'd180)
            validMove = 1'b1;

        // top of platform to end
        else if (newY == 9'd187 - newX)
          if (newX >= 8'd159 && newX <= 8'd127)
            validMove = 1'b1;

        else validMove = 1'b0;
      end

      if (update_pos) begin
        X <= newX;
        Y <= newY;
        end
    end

  end

endmodule
