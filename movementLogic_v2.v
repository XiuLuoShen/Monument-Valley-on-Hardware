// These modules are for the FSM that work with movement
// Modified movementLogic that should work with only 1 button now

module moveSprite(
  input move, resetn, clock, doneChar, doneBG,
  input [1:0] dir,
  output [8:0] xCoordinate, // For 320x240 res...
  output [7:0] yCoordinate,
  output drawChar, drawBG         // THESE ARE SIGNALS SENT TO THE SPRITE DRAWER FSM TELLING IT TO DRAW THE BG OR CHAR
);
	wire enable;

  // 8 Hz enable signal, see rateDivider.v for other speeds
	rateDivider r1(
		.clock(clock),
		.speed(2'b11),
		.resetn(resetn),
		.enableOut(enable)
	);

  wire validMove;
  wire wait1, checkMove, update_pos;
  wire [8:0] X; // X location of character
  wire [7:0] Y; // Y location of character

  moveSpriteControl C(
	 .enable(enable),
    .clock(clock),
    .resetn(resetn),
    .move(move),
    .validMove(validMove),
    .doneChar(doneChar),
    .doneBG(doneBG),
    .wait1(wait1),
    .checkMove(checkMove),
    .drawChar(drawChar),
    .drawBG(drawBG),
    .update_pos(update_pos)
  );

  moveSpriteDataPath D(
    .clock(clock),
    .resetn(resetn),
    .wait1(wait1),
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
  input move, resetn, clock, validMove, doneChar, doneBG, enable,
  output reg wait1, checkMove, drawChar, drawBG, update_pos
);

  reg [3:0] currentState, nextState;
  localparam
    WAIT1 = 4'd0,
    CHECK_MOVE = 4'd1,
    REDRAW_BG = 4'd2,
    WAIT_BG = 4'd3,
    UPDATE_LOC = 4'd4,
    DRAW_CHAR = 4'd5,
    WAIT_CHAR = 4'd6;

  always @(*) begin // state table
    case (currentState)
      WAIT1:         nextState = (move & enable) ? CHECK_MOVE : WAIT1;    // Wait to be told to move
      CHECK_MOVE:   nextState = (validMove) ? REDRAW_BG : WAIT1;        // Check the move
      REDRAW_BG:    nextState = WAIT_BG;                                // Draw the BG over the currentSprite
      WAIT_BG:      nextState = doneBG ? UPDATE_LOC : WAIT_BG;          // Wait for BG to be done drawing
      UPDATE_LOC:   nextState = DRAW_CHAR;                              // Update the location of the character
      DRAW_CHAR:    nextState = WAIT_CHAR;                              // Draw the character
      WAIT_CHAR:    nextState = doneChar? WAIT1: WAIT_CHAR;             // Wait for character to be done drawing before going back to WAIT
      default:      nextState = WAIT1;
    endcase
  end

  always @(*) begin // enable signals
    wait1 = 1'b0;
    checkMove = 1'b0;
    drawChar = 1'b0;
    drawBG = 1'b0;
    update_pos = 1'b0;

    case (currentState)
      WAIT1: begin wait1 = 1'b1; checkMove = 1'b1; end
      CHECK_MOVE: checkMove = 1'b1;
      REDRAW_BG:  drawBG = 1'b1;
	    WAIT_BG:		drawBG = 1'b1;
      UPDATE_LOC: update_pos = 1'b1;
      DRAW_CHAR:  drawChar = 1'b1;
	    WAIT_CHAR:	drawChar = 1'b1;
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
  input clock, resetn, wait1, checkMove, drawChar, drawBG, update_pos,
  input [1:0] dir,
  output reg validMove,
  output reg [8:0] X,
  output reg [7:0] Y
);
  reg [8:0] newX;
  reg [7:0] newY;
  reg teleport;

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
<<<<<<< HEAD
      X <= 8'd95;  // initial sprite location
      Y <= 9'd221;
=======
      X <= 9'd96;  // initial sprite location
      Y <= 8'd222;
>>>>>>> 58dc487accfa9123c65c8ecaec3a8a91ccd75bb7
      validMove <= 1'b0;
		teleport <= 1'b0;
    end

    else  begin
      if (checkMove) begin
        if (newX <= 1'b0 || newY <= 1'b0)
          validMove = 1'b0; // ensures the square does not go off screen

<<<<<<< HEAD
		  else if (newX == 8'd120 && newY == 8'd196) begin
				teleport = 1'b1;
				validMove = 1'b1;
			end

        // starting point to first door
        else if (newY == 9'd316 - newX) begin // diagonal BL to TR
          if (newX <= 8'd120 && newX >= 8'd95)
=======
        // starting point to first door
        else if (newY == 9'd318 - newX) // diagonal BL to TR
          if (newX <= 9'd122 && newX >= 9'd96)
>>>>>>> 58dc487accfa9123c65c8ecaec3a8a91ccd75bb7
            validMove = 1'b1;
			end

        //
        else if (newX == 8'd122 && newY == 8'd196)
          newX <= 9'd127;
          newY <= 8'd69;
          validMove <= 1'b0;

        // door to first corner
<<<<<<< HEAD
        else if (newY == newX - 8'd58) begin // diagonal TL to BR
          if (newX >= 8'd126 && newX <= 8'd170)
=======
        else if (newY == newX - 8'd31) // diagonal TL to BR
          if (newX >= 9'd127 && newX <= 9'd181)
>>>>>>> 58dc487accfa9123c65c8ecaec3a8a91ccd75bb7
            validMove = 1'b1;
			end

        // first corner to first button
<<<<<<< HEAD
        else if (newY == 8'd282 - newX)	begin
          if (newX >= 8'd124 && newX <= 8'd170)
=======
        else if (newY == 8'd238 - newX)
          if (newX >= 9'd125 && newX <= 9'd181)
>>>>>>> 58dc487accfa9123c65c8ecaec3a8a91ccd75bb7
            validMove = 1'b1;
			end

        // first button to moving platform
<<<<<<< HEAD
        else if (newY == 9'd282 - newX)	begin
          if (newX >= 8'd124 && newX <= 8'd160)
=======
        else if (newY == 8'd284 - newX)
          if (newX >= 9'd125 && newX <= 9'd161)
>>>>>>> 58dc487accfa9123c65c8ecaec3a8a91ccd75bb7
            validMove = 1'b1;
			end

        // moving platform to island
<<<<<<< HEAD
        else if (newY == newX - 8'd38)	begin
          if (newX >= 8'd160 & newX <= 8'd216)
=======
        else if (newY == newX - 8'd38)
          if (newX >= 9'd161 && newX <= 9'd216)
>>>>>>> 58dc487accfa9123c65c8ecaec3a8a91ccd75bb7
            validMove = 1'b1;
			end

        // island
<<<<<<< HEAD
        else if (newY == 9'd392 - newX) begin
          if (newX >= 8'd179 && newX <= 8'd215)
=======
        else if (newY == 8'd394 - newX)
          if (newX >= 9'd180 && newX <= 9'd216)
>>>>>>> 58dc487accfa9123c65c8ecaec3a8a91ccd75bb7
            validMove = 1'b1;
			end

        // island to first button again
<<<<<<< HEAD
        else if (newY == newX - 8'd89)	begin
          if (newX >= 8'd124 && newX <= 8'd179)
=======
        else if (newY == newX - 8'd89)
          if (newX >= 9'd125 && newX <= 9'd180)
>>>>>>> 58dc487accfa9123c65c8ecaec3a8a91ccd75bb7
            validMove = 1'b1;
			end

        // top of platform to end
<<<<<<< HEAD
        else if (newY == 8'd210 - newX)	begin
          if (newX >= 8'd158 && newX <= 8'd124)
=======
        else if (newY == 8'd212 - newX)
          if (newX >= 9'd159 && newX <= 9'd125)
>>>>>>> 58dc487accfa9123c65c8ecaec3a8a91ccd75bb7
            validMove = 1'b1;
			end

        else validMove = 1'b0;
      end

      if (update_pos) begin
		if (teleport) begin
			X <= 9'd126;
			Y <= 8'd68;
		end
		else begin
        X <= newX;
        Y <= newY;
	  end
		  validMove <= 1'b0;
		  teleport <= 1'b0;
        end
    end

  end

endmodule
