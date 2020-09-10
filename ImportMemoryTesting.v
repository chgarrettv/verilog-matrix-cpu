// Code by Claude Garrett V, 11-21-2019

module importMemoryTesting();
	
	reg [255:0]instrMem[255:0];
	
	reg reset;

	initial 
		begin
			$monitor("instrMem[0] = %h", instrMem[0]);
			$monitor(instrMem);
			reset = 1'b_0;
			#100 reset = 1'b_1;
		end
		
	always @ (posedge reset) $readmemh("instructions.txt", instrMem);


endmodule