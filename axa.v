// Basic bit definitions
`define DATA						[15:0]
`define ADDRESS					[15:0]
`define SIZE						[65535:0]
`define INSTRUCTION			[15:0]
`define OP							[15:10]
`define SRCTYPE					[9:8]
`define DESTREG					[7:4]
`define SRCREG					[3:0]
`define IMMED						[11:4]
`define STATE						[5:0]
`define REGS						[15:0]
`define OPERATION_BITS 	[5:0]
`define REGSIZE					[15:0]

//Op values
`define OPsys						6'b000000
`define OPcom						6'b000001
`define OPadd						6'b000010
`define OPsub						6'b000011
`define OPxor						6'b000100
`define OPex						6'b000101
`define OProl						6'b000110
`define OPbzjz					6'b001000
`define OPbnzjnz 				6'b001001
`define OPbnjn					6'b001010
`define OPbnnjnn 				6'b001011
`define OPjerr					6'b001110
`define OPfail					6'b001111
`define OPland					6'b010000
`define OPshr						6'b010001
`define OPor						6'b010010
`define OPand						6'b010011
`define OPdup						6'b010100
`define OPxhi						6'b100000
`define OPxlo						6'b101000
`define OPlhi						6'b110000
`define OPllo						6'b111000

//State values
`define Start						6'b111111
`define Decode					6'b111110
`define Done						6'b111101

module ALU(out, in1, in2, op);
parameter BITS = 16;
output [BITS-1:0] out;
input `REGSIZE in1, in2;
input `OPERATION_BITS op;
reg `REGSIZE a;
reg `REGSIZE temp;
always @(in1 or in2 or op) begin #1
	case(op)
		`OPadd: begin a <= in1 + in2; end
		`OPsub: begin a <= in1 - in2; end
		`OPxor: begin a <= in1 ^ in2; end
		`OProl: begin	a <= {in1 << in2, in1 >> (BITS - in2)}; end
        endcase
end

endmodule

module processor(halt, reset, clk);
output reg halt;
input reset, clk;

reg `DATA reglist `REGSIZE;
reg `DATA datamem `SIZE;
reg `INSTRUCTION instrmem `SIZE;
reg `DATA pc = 0;
reg `INSTRUCTION ir;
reg `STATE s;
reg `DATA passreg;

always @(reset) begin
	halt <= 0;
	pc <= 0;
	s <= `Start;
//Setting initial values
	$readmemh0(reglist); //Registers
	$readmemh1(datamem); //Data
	$readmemh2(instrmem); //Instructions
end

always @(posedge clk) begin
	case(s)
		`Start: begin
			ir <= instrmem[pc];
			s <= `Decode;
			end
		`Decode: begin
			pc <= pc + 1;
			s <= `Done;
                        end
		default: begin
			halt <= 1;
			end
		endcase
end

endmodule

module testbench;
reg reset = 0;
reg clk = 0;
wire halt;

processor PE(halt, reset, clk);
initial begin
	$dumpfile;
	$dumpvars(0, PE);
	#10 reset = 1;
	#10 reset = 0;
	while (!halt) begin
		#10 clk = 1;
		#10 clk = 0;
	end
	$finish;
end
endmodule
