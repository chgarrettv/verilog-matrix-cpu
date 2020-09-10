// Code by Claude Garrett V, 12/10/2019.

module EngineTest();

	reg reset, clock;

	ExecutionEngine exe(clock, reset);
	
	initial begin
		reset = 1;
		#40
		reset = 0;
		
		clock = 0;
	end

	always @(clock) #10 clock <= !clock;

endmodule