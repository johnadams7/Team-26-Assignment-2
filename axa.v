`define OPERATION_BITS [5:0]
`define REGSIZE	[15:0]
`define OPadd	6'b000010
`define OPsub	6'b000011
`define OPxor	6'b000100
`define OPex	6'b000101
`define OProl	6'b000110
`define OPbzjz	6'b001000
`define OPbnzjnz 6'b001001
`define OPbnjn	6'b001010
`define OPbnnjnn 6'b001011
`define OPjerr	6'b001110
`define OPfail	6'b001111
`define OPshr	6'b010001
`define OPor	6'b010010
`define OPand	6'b010011
`define OPdup	6'b010100
`define OPxhi	6'b100000
`define OPxlo	6'b101000
`define OPlhi	6'b110000
`define OPllo	6'b111000
module ALU(out, in1, in2, op);
parameter BITS 16;
output [BITS-1:0] out;
input `REGSIZE in1, in2;
input `OPERATION_BITS op;  
reg `REGSIZE a;
always @(in1, in2, op) #1
	case op:
		`OPadd : a <= in1 + in2;
		`OPsub : a <= in1 - in2;
		`OPxor : a <= in1 ^ in2;
		'OProl : a <= {in1[in2:0], in1
