// ELEC3720 Programmable Logic Design 
// Joshua Beverley & Radhika Feron
// Modules for execute stage

//***ALU***// 
module ALU #(parameter n = 3) (
  input logic [n-1:0] A, B, input logic [3:0] F,
  output logic [n-1:0] Y, output logic cout, OV);
  
  //Intermediate logic
  logic [n-1:0] B_temp, SLT, sum,logical_op,AUout;
  logic OVs, OVu, OV_SLT, s0, s1, s2, s3;
  assign s0 = F[0]; 
  assign s1 = F[1];
  assign s2 = F[3];
  assign s3 = F[2];
  //Select 2's complement of B or just B for subtracting or adding
  assign B_temp = s1? ~B:B;
  //Calculate the result of the addition/subtraction
  assign {cout, sum} = A + B_temp + F[1];
  
  //Finds the overflow (if any) of the unsigned/signed operation
  assign OVu = s1 ^ cout;
  assign OVs = (sum[n-1] ^ A[n-1]) & ~(A[n-1] ^ B_temp[n-1]);
  
  //Selects the overflow value for signed or unsigned
  assign OV = s0? OVu:OVs;
    
  //Calculates the SLT (if A<B)
  assign OV_SLT = OVs? cout:sum[n-1];
  
  //Select SLT to be ~cout or SLT chosen by previous multiplexer (with a zero extension)
  assign SLT = s0? {{(n-1) {1'b0}}, ~cout}:{{(n-1) {1'b0}}, OV_SLT};
  
  //Selects the output of the entire arithmetic unit depending on the F control signal
  assign AUout = s2 ? SLT:sum;
  
  //Logic operations using 4-1 multiplexer
  mux4to1 #(n) logical_choice (A, B, F[1:0], logical_op);
  
  //Select final output to be a logical operation, or arithmetic operation depending on F control signal
  assign Y = s3 ? logical_op:AUout;
  
endmodule

//***MUL/DIV***//
module multiply_divide #(parameter n = 32) (
  input logic clk, input logic [2:0] F, input logic [n-1:0] a, b,
  output logic [n-1:0] y, hi2, low2);
  
  //intermediate logic
  logic [n-1:0] hi, lo;
  logic [n-1:0] R, Q;   //remainder and quotient from division operation
  logic [n-1:0] H, L;   //high and low bytes of the multiplication operation
  
  //Division and multiplication operations
  assign Q = a/b;
  assign R = a%b;
  assign {H,L} = a * b;
  
  logic s0,s1,s2,En1,En2;   //control/enable signals derived from the F input signal
  assign s0 = F[0];
  assign s1 = ~F[2];
  assign s2 = F[0];
  assign En1 = F[1] & ~(F[2] & F[0]);
  assign En2 = F[1] & ~(F[2] & ~F[0]);

  //Intermediate logic
  logic [n-1:0] operation_hi, operation_lo, ff_input_hi, ff_input_lo;
  
  //Select one of the multiplication/division outputs
  always_comb begin
    if (s0)
    begin
      operation_hi = R;
      operation_lo = Q;
    end
    else
    begin
      operation_hi = H;
      operation_lo = L;
    end
  end
  //select the operation output or a constant value
  always_comb begin
    if (s1)
    begin
      ff_input_hi = operation_hi;
      ff_input_lo = operation_lo;
    end
    else
    begin
      ff_input_hi = a;
      ff_input_lo = a;
    end
  end
  //if at the positive edge of the clk, and the register is enabled, pass output of above module to the output of the register
  always_ff @(posedge clk) begin
    if (En1) hi <= ff_input_hi;
	 if (En2) lo <= ff_input_lo;
  end
  
  //multiplexer to choose hi or lo as the final output
  always_comb begin
    if (s2)
      y = lo;
    else
      y = hi;
  end
  
  //used simply to display result
  assign hi2=hi;
  assign low2 = lo;
  
endmodule

//***Shifter***//
module Shifter (
  input logic [2:0] F,
  input logic [3:0] c,
  input logic [31:0] a,b,
  output logic [31:0] y);
  
  logic [3:0] var_choice;     //intermediate variables
  
  assign var_choice = F[2]? c:b[3:0];
  
  CoreShifter shiftc(var_choice, F[1:0], a, y);    //shift A by required amount
  
endmodule

module CoreShifter (
  input logic [3:0] Sh,
  input logic [1:0] F,
  input logic [31:0] A,
  output logic [31:0] Y);
  
  logic [31:0] yls, yrs, yars, ym;
  assign yls = A << Sh;
  assign yrs = A >> Sh;
  assign yars = $signed(A) >>> Sh;
  
  assign ym = F[0]? yrs:yls;
  assign Y = F[1]? yars:ym;

endmodule

//***Miscellaneous***//
module mux4to1 #(parameter W = 3) (
  input logic [W-1:0] A,B, input logic [1:0] F,
  output logic [W-1:0] Y);
  
  //Intermediate logic
  logic [W-1:0] lo, hi, d0, d1, d2, d3;
  
  //logical relations
  assign d0 = A & B;
  assign d1 = A | B;
  assign d2 = A ^ B;
  assign d3 = ~(A | B);
  
  //forms 4-1 mux using 2-1 muxes
  assign lo = F[0]? d1:d0;      //if F[0] = 1, lo = d1
  assign hi = F[0]? d3:d2;      //if F[0] = 1, hi = d3
  assign Y = F[1]? hi:lo;       //if F[1] = 1, Y = hi
  
endmodule

