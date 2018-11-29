// These modules are for the FSM that work with movement
// Modified movementLogic that should work with only 1 button now

module moveSprite(
  input move, resetn, clock, doneChar, doneBG, doneAnimation,
  input [2:0] dir,
  input [3:0] gameState,
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
    .gameState(gameState),
    .checkMove(checkMove),
    .drawChar(drawChar),
    .drawBG(drawBG),
    .update_pos(update_pos),
    .doneAnimation(doneAnimation),    // Signal indicating that the position of the sprite has moved up with the pillar
    .validMove(validMove),
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
  input clock, resetn, wait1, checkMove, drawChar, drawBG, update_pos, doneAnimation,
  input [3:0] gameState,
  input [2:0] dir,
  output reg validMove,
  output reg [8:0] X,
  output reg [7:0] Y
);
  reg [8:0] newX;
  reg [7:0] newY;
  reg teleport;
  reg pillarRaised; // Register to make sure the sprite rises due to the pillar only once
  
  /* 

  Keyboard make codes

  UP: 2  E0,75
  LEFT: 0  E0,6B
  DOWN: 1  E0,72
  RIGHT: 3 E0,74

  */
  
  localparam
    DRAW_INITIAL = 4'd12,
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

  always @(posedge clock) begin
    case (dir)
		3'b100: begin
			newX <= X+1'b1;
			newY <= Y+1'b1;
		end
		3'b101: begin
			newX <= X-1'b1;
			newY <= Y+1'b1;
		end
		3'b110: begin
			newX <= X+1'b1;
			newY <= Y-1'b1;
		end
		3'b111: begin
			newX <= X-1'b1;
			newY <= Y-1'b1;
		end
		default: begin
			newX <= X;
			newY <= Y;
		end
		
		
    endcase
  end

  always @(posedge clock) begin
    if (!resetn) begin
      X <= 9'd95;  // initial sprite location
      Y <= 8'd221;
      validMove <= 1'b0;
	   teleport <= 1'b0;
      pillarRaised <= 1'b0;
    end

    else  begin
      if (checkMove) begin
        if (newX <= 1'b0 || newY <= 1'b0 || newX >= 9'd320 || newY >= 8'd240)
          validMove = 1'b0; // ensures the square does not go off screen

  		  else if (newX == 8'd121 && (newY >= 8'd193 && newY <= 8'd198)) begin
  				teleport = 1'b1;
  				validMove = 1'b1;
  			end

        // starting point to first door
        else if (newY >= 9'd314 - newX && newY <= 9'd319 - newX && newX >= 8'd90 && newX <= 8'd123) begin // diagonal BL to TR
          if (newY > 8'd226)
            validMove = 1'b0;
          else validMove = 1'b1;
	       end

        // door to first corner
        else if (newY <= newX - 8'd52 && newY >= newX - 8'd63 && newX >= 8'd126 && newX <= 8'd177) begin // diagonal TL to BR
          if (newY >= 9'd289 - newX && newX <= 8'd176)
            validMove = 1'b0;
          else validMove = 1'b1;
	       end

        // first corner to first button
        else if (newY <= 9'd288 - newX && newY >= 9'd277 - newX && newX >= 8'd116 && newX <= 8'd180)	begin // [bottom diagonal] && [top diagonal]
          if (newY <= newX - 8'd63 && newX >= 8'd170) // for right side corner
            validMove = 1'b0;
          else if (newY >= newX + 8'd41 && newX < 8'd124) // for left side corner
            validMove = 1'b0;
			 else if (gameState == FORMED_BRIDGE_2 || gameState == FORMED_BRIDGE_3) begin // accounts for the path break
            if (newY <= newX - 8'd26 && newX >= 8'd150)
              validMove = 1'b0;
				else
					validMove = 1'b1;
          end
          else validMove = 1'b1;
        end

        // bridge to platform
        else if (newY <= newX - 8'd30 && newY >= newX - 8'd44 && newX >= 9'd152 && newX <= 9'd227)	begin

          if (gameState == FORMED_BRIDGE_1) begin           // first bridge is activated
            if (newY <= 9'd276 - newX && newX <= 8'd161)
              validMove = 1'b0;
            else if (newY >= 9'd353 - newX && newX >= 8'd192)
              validMove = 1'b0;
            else validMove = 1'b1;
          end

          else if (gameState == FORMED_BRIDGE_2 || gameState == FORMED_BRIDGE_3) begin  // second bridge is activated
            if (newY <= 9'd336 - newX && newX <= 8'd191)
              validMove = 1'b0;
            else if (newY >= 9'd401 - newX && newX >= 8'd224)
              validMove = 1'b0;
            else validMove = 1'b1;
          end

          else
            validMove = 1'b0;
	       end

        // island
        else if (newY >= 9'd387 - newX && newY <= 9'd400 - newX && newX >= 8'd171 && newX <= 9'd227) begin
          if (newY <= newX - 8'd47 && newX >= 8'd217)
            validMove = 1'b0;
          else if (newY >= newX + 42 && newX <= 8'd179)
            validMove = 1'b0;
          else validMove = 1'b1;
			end

        // island to first button again
        else if (newY <= newX + 8'd42 && newY >= newX + 8'd30 && newX >= 8'd116 && newX <= 8'd190)	begin
          if (newY <= 9'd274 - newX && newX >= 8'd124)
            validMove = 1'b0;
          else if (newY <= 9'd275 - newX && newX <= 8'd124)
            validMove = 1'b0;
			 else if (gameState == FORMED_BRIDGE_3)
				validMove = 1'b1;
          else validMove = 1'b0;
			end

        // top of platform to original path
        else if (newY <= 8'd217 - newX && newY >= 8'd203 - newX && newX >= 8'd108 && newX <= 8'd136)	begin
          if (newY <= newX - 8'd32 && newX <= 8'd120)
            validMove = 1'b0;
          else if (gameState == FORMED_BRIDGE_3 || gameState == PILLAR_RISED)
				validMove = 1'b1;
			 else validMove = 1'b0;
			end

       // original path to end
        else if (newY <= 8'd215 - newX && newY >= 8'd208 - newX && newX >= 8'd129 && newX <= 8'd166) begin
            if (gameState == PILLAR_RISED)
					validMove = 1'b1;
				else validMove = 1'b0;
        end
			else
				validMove = 1'b0;
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

      if (doneAnimation && !pillarRaised) begin  // If the animation has finished then decrease Y by 74 pixels (height of the pillar)
        pillarRaised <= 1'b1;
        X <= X;
        Y <= Y - 8'd74;
      end
		if (gameState == FINISHED_GAME) begin
			X <= 9'd320;
			Y <= 8'd240;
		end
    end

  end

endmodule
