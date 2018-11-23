// This module deals with the animation for the rising pillar. Note that the pillar can only rise and will not be able to go down
// Pillar will rise 15 times at a rate of 20Hz

module pillarAnimator(
  input clock, resetn, start,
  input [8:0] char_X,
  input [7:0] char_Y,
  // For the VGA
  output reg drawOnVGA_Animation,
  output reg [8:0] animationX,
  output reg [7:0] animationY,
  output reg [2:0] animationColor,
  // For gameState
  output doneAnimation
  );

  wire [4:0] timesRisen; // Number of times the pillar has risen
  reg [7:0] y_char_risen; // Variable that keeps track of the character's y coordinate while the pillar is rising
  wire drawPillar, drawSprite, doneRise, doneSprite, nextFrame;


  always @(*) begin
    if (!start)
      y_char_risen = char_Y;
    else
      y_char_risen = char_Y - timesRisen * 3'd3;
  end

  // *************** VGA *************************
  wire [8:0] xAnimation, charXAnimation;
  wire [7:0] yAnimation, charYAnimation;
  wire [2:0] colorAnimation, colorSprite;
  wire plotAnimation, plotSprite;

  always @(*) begin
    if (drawSprite) begin
      animationX = charXAnimation;
      animationY = charYAnimation;
      drawOnVGA_Animation = plotSprite;
      animationColor = colorSprite;
    end
    else begin
      animationX = xAnimation;
      animationY = yAnimation;
      drawOnVGA_Animation = plotAnimation;
      animationColor = colorAnimation;
    end
  end

  // *********************************************

  // 8 Hz enable signal, see rateDivider.v for other speeds
	rateDivider r1(
		.clock(clock),
		.speed(2'b11),
		.resetn(resetn),
		.enableOut(nextFrame)
	);

  animationControl control(
    .clock(clock), .resetn(resetn), .start(start),
    .doneSprite(doneSprite), .doneRise(doneRise), .nextFrame(nextFrame),
    .timesRisen(timesRisen), .drawPillar(drawPillar), .drawSprite(drawSprite), .doneAnimation(doneAnimation)
    );
  animationDataPath datapath(
    .clock(clock), .resetn(start), .drawPillar(drawPillar),
    .timesRisen(timesRisen), .xAnimation(xAnimation), .yAnimation(yAnimation), .colorAnimation(colorAnimation),
    .plotAnimation(plotAnimation), .doneRise(doneRise)
    );

  spriteDrawer drawer(
		.clock(clock),
		.data_x(char_X),
		.data_y(y_char_risen),
		.gameState(3'd7),   // gameState will be pillar rising if this module is active
		.resetn(start),
		.drawChar(drawSprite),
		.drawBG(1'b0),
		.xCoordinate(charXAnimation),
		.yCoordinate(charYAnimation),
		.drawOnVGA(plotSprite),
		.colorToDraw(colorSprite),
		.doneDraw(doneSprite)
		);

endmodule

module animationControl(
  input clock, resetn, start,
  input doneSprite, doneRise, nextFrame,
  input [4:0] timesRisen,
  output reg drawPillar, drawSprite, doneAnimation
  );

  reg [2:0] currentState, nextState;

  localparam
    INACTIVE = 3'd0,
    DRAW_PILLAR = 3'd1,
    DRAW_CHAR = 3'd2,
    WAIT_FRAME = 3'd3,
    DONE = 3'd4;

  always @(*) begin //State table
    case(currentState)
      INACTIVE: nextState = start? DRAW_PILLAR: INACTIVE;
      DRAW_PILLAR:  nextState = doneRise? DRAW_CHAR: DRAW_PILLAR;
      DRAW_CHAR:    nextState = doneSprite? WAIT_FRAME: DRAW_CHAR;
      WAIT_FRAME: begin
        if (timesRisen == 5'd25)
          nextState = DONE;
        else
          nextState = nextFrame? DRAW_PILLAR: WAIT_FRAME;
      end
      DONE: nextState = DONE;
      default:
        nextState = INACTIVE;
    endcase
  end

  always @(*) begin //Enable Signals
  drawPillar = 1'b0;
  drawSprite = 1'b0;
  doneAnimation = 1'b0;
    case(currentState)
      DRAW_PILLAR: drawPillar = 1'b1;
      DRAW_CHAR:  drawSprite = 1'b1;
      DONE: doneAnimation = 1'b1;
      default: begin
        drawPillar = 1'b0;
        drawSprite = 1'b0;
        doneAnimation = 1'b0;
      end
    endcase
  end

  always @(posedge clock) begin
    if (!resetn)
      currentState = INACTIVE;
    else
      currentState = nextState;
  end

endmodule

module animationDataPath(
  input clock, resetn, drawPillar,
  output reg [4:0] timesRisen,
  output reg [8:0] xAnimation,
  output reg [7:0] yAnimation,
  output reg [2:0] colorAnimation,
  output reg plotAnimation, doneRise
  );
  reg [4:0] X;
  reg [4:0] Y;
  reg [4:0] counter;

  wire [2:0] background_color;
  getBackgroundPixel bg(.clock(clock), .gameState(4'd0), .X(X + 9'd116), .Y(Y + 8'd152 - timesRisen*3'd3), .color(background_color));
  wire [2:0] colorPillar;
  getPillarPixel pillar(.clock(clock), .X(X), .Y(Y), .color(colorPillar));


  // Determining which color to use, pillar vs the backdrop
  always @(*) begin
    if (Y < 5'd9 && (X > 5'd9+Y || X < 5'd9-Y))
      colorAnimation = background_color;
    else
      colorAnimation = colorPillar;
  end

  always @(posedge clock) begin
    if (!resetn) begin
      timesRisen <= 1'b0;
      X <= 5'b0;   // Beginning X and pixels
      Y <= 5'b0;
      counter <= 1'b0;
      plotAnimation <= 1'b0;
      doneRise <= 1'b0;
    end
    else if (drawPillar) begin
      if (plotAnimation) begin
			plotAnimation <= 1'b0;
				// Not finished drawing the pillar
				if (Y < 5'd22) begin
				  if (X == 5'd19) begin // At the end of the row
					 X <= 5'b0;
					 Y <= Y + 1'd1;
				  end
				  else begin  // Else increment X
					 X <= X + 1'd1;
				  end
				end

				// Finished drawing
				else begin
					X <= 5'd0;
					Y <= 5'd0;
				  doneRise <= 1'b1;
				  counter <= counter + 1'd1;
				end
			end
		else plotAnimation <= 1'b1;

    end

    else begin
      plotAnimation <= 1'b0;
      doneRise <= 1'b0;
      end

    xAnimation <= X + 9'd116;
    yAnimation <= Y - counter*4'd3 + 8'd152;
    timesRisen <= counter;
  end

endmodule
