// Basic bit definitions
`define DATA		[15:0]
`define ADDRESS		[15:0]
`define SIZE		[65535:0]
`define INSTRUCTION	[15:0]
`define OP		[15:10]
`define OP8		[15:12]
`define OPPUSH		[14]
`define OP8IMM		[15]
`define SRCTYPE		[9:8]
`define DESTREG		[3:0]
`define SRCREG		[7:4]
`define SRC8		[11:4]
`define STATE		[6:0]
`define REGS		[15:0]
`define OPERATION_BITS 	[5:0]
`define REGSIZE		[15:0]

//Op values
`define OPsys					6'b000000
`define OPcom					6'b000001
`define OPadd					6'b000010
`define OPsub					6'b000011
`define OPxor					6'b000100
`define OPex					6'b000101
`define OProl					6'b000110
`define OPbzjz					6'b001000
`define OPbnzjnz 				6'b001001
`define OPbnjn					6'b001010
`define OPbnnjnn 				6'b001011
`define OPjerr					6'b001110
`define OPfail					6'b001111
`define OPland					6'b010000
`define OPshr					6'b010001
`define OPor					6'b010010
`define OPand					6'b010011
`define OPdup					6'b010100
// 8-bit immediate 
`define OPxhi					4'b1000
`define OPxlo					4'b1010
`define OPlhi					4'b1100
`define OPllo					4'b1110

//State values
`define Start					7'b1000000
`define Decode					7'b1100000
`define Decode2 				7'b1100001
`define DecodeI8 				7'b1100010
`define Nop					7'b1000010
`define SrcType					7'b1001000
`define SrcRegister				7'b1001001
`define SrcI4					7'b1001010
`define SrcI8 					7'b1001011
`define SrcMem					7'b1001100
`define Done					6'b111101

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
reg `STATE s, sLA;
reg `DATA passreg;

always @(reset) begin
	halt <= 0;
	pc <= 0;
	s <= `Start;
//Setting initial values
	
	$readmemh0(reglist); //Registers
	$readmemh1(datamem); //Data
	$readmemh2(instrmem); //Instructions
	
        /*
	$readmemh( "vmem0.txt" ,reglist);
       	$readmemh( "vmem1.txt" ,datamem);
       	$readmemh( "vmem2.txt", instrmem);
	*/
end

always @(posedge clk) begin
	case(s)
		`Start: begin
			ir <= instrmem[pc];
			s <= `Decode;
			end

		`Decode: begin
			// Change to if statement to combine states?
			if (ir `OP8IMM)
				s <= `DecodeI8;
			else
				s <= `Decode2;

			pc <= pc + 1; 
			end
	
		
		// Regular Instruction	
		`Decode2: begin
			// Grab the next state
			case (ir `OP)
				`OPland: s <= `Nop;
				`OPcom: s <= `Nop;
				`OPjerr: s <= `Nop;
				`OPfail: s <= `Done;
				`OPsys: s <= `Done;
				default case (ir `SRCTYPE)
					`SrcRegister: s <= `SrcRegister;
					`SrcI4:  s <= `SrcI4;
					`SrcMem: s <= `SrcMem;
					default: s <= `Start;
				endcase
			endcase

			sLA <= ir `OP;
			end

		// I8 instruction
		`DecodeI8: begin
			if ( ir `OP8IMM)
			begin
				case (ir `OP8)
					`OPxhi: sLA <= `OPxhi;
					`OPxlo: sLA <= `OPxlo;
					`OPlhi: sLA <= `OPlhi;
					`OPllo: sLA <= `OPllo;
					default: halt <= 1;
				endcase
			end
			
			s <= `SrcI8;
			end
		
		// Begin Src States
		
		`SrcRegister: begin
			passreg <= reglist[ir `SRCREG];
			s <= sLA;
			end

		`SrcI4: begin
			passreg <= ir `SRCREG;
			s <= sLA;
			end
		`SrcI8: begin
			passreg <= ir `SRC8;
			s <= sLA;
			end
		`SrcMem: begin
			// Too much in one cycle??
			passreg <= datamem[reglist[ir `SRCREG]];
			s <= sLA;
			end
		
			
		// Begin OPCODE States
		
		`Nop: s <= `Start;

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
	//$dumpfile("test.out");
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
