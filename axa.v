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
`define SRCREGMSB 	[7]
`define SRC8		[11:4]
`define SRC8MSB 	[11]
`define STATE		[6:0]
`define REGS		[15:0]
`define OPERATION_BITS 	[6:0]
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
`define OPxhi					6'b100000
`define OPxlo					6'b101000
`define OPlhi					6'b110000
`define OPllo					6'b111000



// Checks
// 	8-bit
`define OPxhiCheck				4'b1000
`define OPxloCheck				4'b1010
`define OPlhiCheck				4'b1100
`define OPlloCheck				4'b1110

//	SrcType
`define SrcTypeRegister				2'b00
`define SrcTypeI4				2'b01
`define SrcTypeMem				2'b10

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
`define OPex2					7'b1010000
`define OPex3					7'b1010001
`define Done					6'b111101
`define ALUOUT					7'b1010010
`define OPxhi2					7'b1011000
`define OPxhi3					7'b1011001

module ALU(out, in1, in2, op);
parameter BITS = 16;
output reg [BITS-1:0] out;
input `REGSIZE in1, in2;
input `OPERATION_BITS op;
reg `REGSIZE a;
reg `REGSIZE temp;
always @(in1 or in2 or op) begin #1
	case(op)
		`OPadd: begin out <= in1 + in2; end
		`OPsub: begin out <= in1 - in2; end
		`OPxor: begin out <= in1 ^ in2; end
		`OProl: begin out <= {in1 << in2, in1 >> (BITS - in2)}; end
		`OPshr: begin out <= in1 >> in2; end
		`OPor:  begin out <= in1 | in2; end
		`OPand: begin out <= in1 & in2; end
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
wire `DATA aluout;

//Module instantiations
ALU opalu(aluout, reglist[ir `DESTREG], passreg, sLA);

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
			// Change to if statement to combine states?
			//$display( "%d || %b || %d", reglist[ir `DESTREG], ir, pc);
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
					`SrcTypeRegister: s <= `SrcRegister;
					`SrcTypeI4:  s <= `SrcI4;
					`SrcTypeMem: s <= `SrcMem;
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
					`OPxhiCheck: sLA <= `OPxhi;
					`OPxloCheck: sLA <= `OPxlo;
					`OPlhiCheck: sLA <= `OPlhi;
					`OPlloCheck: sLA <= `OPllo;
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
			passreg <= {{12{ir `SRCREGMSB}}, ir `SRCREG};
			s <= sLA;
			end
		`SrcI8: begin
			passreg <=  {{8{ir `SRC8MSB}}, ir `SRC8};
			s <= sLA;
			end
		`SrcMem: begin
			// Too much in one cycle??
			passreg <= datamem[reglist[ir `SRCREG]];
			s <= sLA;
			end


		// Begin OPCODE States

    	`OPxlo: begin reglist[ir  `DESTREG] <= reglist[ir `DESTREG]; s <= `OPxor; end
		`OPxhi: begin reglist[12] <= passreg << 8; s <= `OPxhi2; end
		`OPxhi2: begin passreg <= reglist[12]; s <= `OPxor; end
		//`OPxhi3: begin  <= reglist[ir `DESTREG]; s <= `OPxor; end
		//`ALUOUT: begin reglist[ir `DESTREG] <= aluout; s <= `Start; end
		`OPllo: begin reglist[ir `DESTREG] <= {{8{passreg[7]}}, passreg}; s <=`Start; end
		`OPlhi: begin reglist[ir `DESTREG] <= {passreg, 8'b0}; s <=`Start; end
		`OPand: begin reglist[ir `DESTREG] <= aluout; s <=`Start; end
		`OPor:	begin reglist[ir `DESTREG] <= aluout; s <=`Start; end
		`OPxor: begin reglist[ir `DESTREG] <= aluout; s <=`Start; end
		`OPadd: begin reglist[ir `DESTREG] <= aluout; s <=`Start; end
		`OPsub: begin reglist[ir `DESTREG] <= aluout; s <=`Start; end
		`OProl: begin reglist[ir `DESTREG] <= aluout; s <=`Start; end
		`OPshr: begin reglist[ir `DESTREG] <= aluout; s <=`Start; end
	`OPbzjz: begin if(reglist[ir `DESTREG]==0)
		begin
			if(ir `SRCTYPE == 2'b01)
			begin

				pc <= pc+passreg-1;
			end
			else
			begin
				pc <= passreg;
			end

		end
		s <= `Start;
		end

		`OPbnzjnz: begin if(reglist[ir `DESTREG]!=0)
		begin
			if(ir `SRCTYPE == 2'b01)
			begin
				pc <= pc+passreg-1;
			end
			else
			begin
				pc <= passreg;
			end

		end
		s <= `Start;
		end

		`OPbnjn: begin if(reglist[ir `DESTREG][15]==1)
		begin
			if(ir `SRCTYPE == 2'b01)
			begin
				pc <= pc+passreg-1;
			end
			else
			begin
				pc <= passreg;
			end

		end
		s <= `Start;
		end

		`OPbnnjnn: if(reglist[ir `DESTREG]>=0)
		begin
			if(ir `SRCTYPE == 2'b01)
			begin
				pc <= pc+passreg-1;
			end
			else
			begin
				pc <= passreg;
			end

		end
		s <= `Start;
		end

		`Nop: s <= `Start;
		`OPdup: begin reglist[ir `DESTREG] <= passreg; s <= `Start; end
		`OPex: begin reglist[12] <= reglist[ir `DESTREG]; s <= `OPex2; end
		`OPex2: begin reglist[ir `DESTREG] <= datamem[reglist[ir `SRCREG]]; s <= `OPex3; end
		`OPex3: begin datamem[reglist[ir `SRCREG]] <= reglist[12]; s <= `Start; end
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
