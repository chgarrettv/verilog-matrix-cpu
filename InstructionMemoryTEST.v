// Code by Claude Garrett V, 11-24-2019.

module InstructionMemoryTEST();

	parameter IN = 2;
	parameter OUT = 1;
	parameter ENABLE = 0;

	reg reset, clock;
	reg [2:0]memCon;
	
	tri [261:0] bus;

	//   InstructionMemory(bus, in,         out,         enable,         reset, clock);
	InstructionMemory inst(bus, memCon[IN], memCon[OUT], memCon[ENABLE], reset, clock);
	
	assign bus = memCon[IN] ? 262'b_0 : 262'b_z;
	
	initial
		begin
			clock = 1'b_0;
			reset = 1'b_0;
			
			//Control Signals:
			memCon = 3'b_0;
			
			$monitor(clock, reset, memCon[IN], memCon[OUT], memCon[ENABLE]);
			
			#50
			
			// Reset the system.
			reset = 1'b_1;
			#10
			reset = 1'b_0;
			
			clock = 1'b_0;
			
			#20;
			
			// Begin testing.
			
			memCon[ENABLE] = 1'b_1;
			memCon[IN] = 1'b_1;
			
			#10;
			
			memCon[IN] = 1'b_0;
			memCon[OUT] = 1'b_1;
			
			#30
			
			memCon[ENABLE] = 1'b_0;
			memCon[OUT] = 1'b_0;
			
			
		end
		
	always @(clock) #10 clock <= !clock;

endmodule