// Code by Claude Garrett V, 11-24-2019.

module InstructionMemory(bus, importAddress, read, enable, reset);

	inout [261:0]bus;

	input importAddress, read, enable, reset;

	reg [261:0]instructions [127:0];
	reg [6:0]address;
	
	assign bus = (enable && read) ? {6'b_0, instructions[address]} : 262'b_z;

	always @ (posedge reset) begin
		$readmemh("instructions.txt", instructions);
		address = 8'b_0;
	end
		
	always @ (posedge importAddress) if(enable) address = bus[6:0];

endmodule

module MatrixMemory(bus, write, importAddress, read, enable, reset, overflow, clock);

	inout [261:0]bus;

	input write, importAddress, read, enable, reset, overflow, clock;

	reg [261:0]instructions [127:0];
	reg [6:0]address;
	
	assign bus = (enable && read) ? {6'b_0, instructions[address]} : 262'b_z;

	always @ (posedge reset) begin
		$readmemh("matrices.txt", instructions);
		address = 8'b_0;
	end
		
	always @ (posedge importAddress) if(enable) address[6:0] = bus[6:0];
	
	always @ (posedge clock) begin
		if(enable && !overflow && write) instructions[address] = bus;
		if(enable && overflow && write) instructions[address + 1] = bus;
	end
	

endmodule

module Registers(bus, write, importAddress, read, enable, reset, overflow, clock);

	inout [261:0]bus;

	input write, importAddress, read, enable, reset, overflow, clock;

	reg [261:0]instructions [127:0];
	reg [6:0]address;
	
	assign bus = (enable && read) ? {6'b_0, instructions[address]} : 262'b_z;

	integer i;

	always @ (posedge reset) begin
		for(i = 0; i < 128; i = i + 1) begin
			instructions[i] = 262'b_0;
		end
		address = 8'b_0;
	end
		
	always @ (posedge importAddress) if(enable) address[6:0] = bus[6:0];
	
	always @ (posedge clock) begin
		if(enable && !overflow && write) instructions[address] = bus;
		if(enable && overflow && write) instructions[address + 1] = bus;
	end
	

endmodule