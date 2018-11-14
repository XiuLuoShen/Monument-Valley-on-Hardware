// Rate Divider Module
module rateDivider(clock, speed, resetn, enableOut);
  input clock, resetn;
  input [1:0] speed;
  output enableOut;
  reg [25:0] R; 		// Use to hold load for parallelLoadn
  wire [25:0] BCD; 	// Holds the value of 26 bit counter

  always @(posedge clock)
    case (speed)
      0:  // use full speed (50 Mhz)
        R = 1'b0;
      1:  // use 20 Hz
        R = 26'd2500000;
      2:  // use 4 Hz
        R = 26'd12499999;
      3:  // use 8 Hz
        R = 26'd6749999;
      default:  // use
        R = 26'd49999999;
    endcase

    assign enableOut = (|BCD == 1'b0)?1'b1:1'b0;

    counterdown #(.n(26)) c1(
      .clock(clock),
      .resetn(resetn),
      .En(1'b1),
      .Loadn(enableOut | (BCD > R)),
      .R(R),
      .Q(BCD)
    );
endmodule


module counterdown(clock, resetn, En, Loadn, R, Q);
  parameter n = 26;
  input clock, resetn, En, Loadn;
  input [25:0] R;
  output reg [25:0] Q;

  always @(negedge resetn, posedge clock) begin
    if (resetn == 0)
      Q <= 1'b1;
    else if (Loadn == 1'b1)
      Q <= R;
    else if (&Q == 1'b1)
      Q <= 0;
    else if (En)
      Q <= Q-1'b1;
  end
endmodule
