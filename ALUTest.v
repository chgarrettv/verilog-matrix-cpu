// Code by Claude Garrett V, 12/10/2019

module ALUTB();

	reg clock, reset, enable, in1, in2, out, over, compute;
	reg [6:0] operation;
	tri [261:0] bus;
	wire done;
	
	reg [261:0] source1;
	reg [261:0] source2;
	
	
	//  ALU(reset, bus, enable, in1, in2, out, over, compute, operation, done);
	ALU alu(reset, bus, enable, in1, in2, out, over, compute, operation, done);
	
	assign bus = (in1 && enable) ? source1 : 262'h_z;
	assign bus = (in2 && enable) ? source2 : 262'h_z;

	initial begin // Make everything 0 to avoid the zs.
		clock = 0;
		source1 = 0;
		source2 = 0;
		
		operation = 0;
		reset = 0;
		enable = 0;
		in1 = 0;
		in2 = 0;
		out = 0;
		over = 0;
		compute = 0;
		
	end
	
	initial begin // The real testing part of the test bench.
		$monitor("Source 1 = %h Source 2 = %h\nbus = %h", source1, source2, bus);
		
		reset = 1;
		#40
		reset = 0;
		
		#20
		
		operation = 7'h_4;
		source1 = 262'h_ff;
		source2 = 262'h_02;
		
		#20
		
		enable = 1;
		in1 = 1;
		
		#20
		
		in1 = 0;
		in2 = 1;
		
		#20
		
		in2 = 0;
		compute = 1;
		
		#40
		
		out = 1;
		
		#20
		
		out = 0;
		
	end
	
	always @(clock) #10 clock <= !clock;

endmodule