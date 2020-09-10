// Code by Claude Garrett V, 12/10/2019.

module ALU(reset, bus, enable, in1, in2, out, over, compute, operation, done);

	input reset;
	inout [261:0] bus;
	input enable, in1, in2, out, over, compute;
	input [6:0] operation;
	
	wire matint;
	assign matint = operation[5];
	
	wire [5:0] op;
	assign op = operation[4:0];
	
	output reg done;

	reg [261:0] source1;
	
	wire [2:0] s1rows;
	assign s1rows = source1[261:259];
	wire [2:0] s1cols;
	assign s1cols = source1[258:256];
	
	reg [261:0] source2;
	
	wire [2:0] s2rows;
	assign s2rows = source2[261:259];
	wire [2:0] s2cols;
	assign s2cols = source2[258:256];
	
	reg [261:0] result;
	reg [261:0] overflow;
	reg [511:0] working;
	
	parameter ADD   = 5'b_10000;
	parameter SUB   = 5'b_01000;
	parameter MULT  = 5'b_00100;
	parameter SCALE = 5'b_00010;
	parameter TRANS = 5'b_00001;
	
	assign bus = (enable && out) ? result : 262'h_z;
	assign bus = (enable && over) ? overflow : 262'h_z;
	
	initial begin
		source1 = 0;
		source2 = 0;
		result = 0;
		overflow = 0;
		done = 0;
		working = 0;
	end
	
	always @ (posedge reset) begin
		source1 = 0;
		source2 = 0;
		result = 0;
		overflow = 0;
		done = 0;
		working = 0;
	end
	
	always @ (posedge done) #80 done = 1'b_0;

	always @ (posedge in1) source1 = bus;
	always @ (posedge in2) source2 = bus;
	
	always @ (posedge compute) begin
	
		if(matint == 0) case(op) // INTEGER
			ADD: begin
				working = {16'h_0, source1} + {16'h_0, source2};
				overflow = working[511:256];
				result = {6'h_0, working[255:0]};
			end SUB: begin
				working = {16'h_0, source1} - {16'h_0, source2};
				overflow = working[511:256];
				result = {6'h_0, working[255:0]};
			end MULT: begin
				working = {16'h_0, source1} * {16'h_0, source2};
				overflow = working[511:256];
				result = {6'h_0, working[255:0]};
			end SCALE: begin
				result = 262'h_0;
			end TRANS: begin
				working = {16'h_0, source1} / {16'h_0, source2};
				overflow = working[511:256];
				result = {6'h_0, working[255:0]};
			end
		endcase else case(op) // MATRIX
			ADD: begin
				
				result[261:256] = source1[261:256]; // Number of rows and columns is the same.
				overflow[261:256] = source1[261:256];
				
				// Summing the matrices including overflow.
				working[511:480] = {16'b_0, source1[255:240]} + {16'b_0, source2[255:240]};
				working[479:448] = {16'b_0, source1[239:224]} + {16'b_0, source2[239:224]};
				working[447:416] = {16'b_0, source1[223:208]} + {16'b_0, source2[223:208]};
				working[415:384] = {16'b_0, source1[207:192]} + {16'b_0, source2[207:192]};
				working[383:352] = {16'b_0, source1[191:176]} + {16'b_0, source2[191:176]};
				working[351:320] = {16'b_0, source1[175:160]} + {16'b_0, source2[175:160]};
				working[319:288] = {16'b_0, source1[159:144]} + {16'b_0, source2[159:144]};
				working[287:256] = {16'b_0, source1[143:128]} + {16'b_0, source2[143:128]};
				working[255:224] = {16'b_0, source1[127:112]} + {16'b_0, source2[127:112]};
				working[223:192] = {16'b_0, source1[111:96]}  + {16'b_0, source2[111:96]};
				working[191:160] = {16'b_0, source1[95:80]}   + {16'b_0, source2[95:80]};
				working[159:128] = {16'b_0, source1[79:64]}   + {16'b_0, source2[79:64]};
				working[127:96]  = {16'b_0, source1[63:48]}   + {16'b_0, source2[63:48]};
				working[95:64]   = {16'b_0, source1[47:32]}   + {16'b_0, source2[47:32]};
				working[63:32]   = {16'b_0, source1[31:16]}   + {16'b_0, source2[31:16]};
				working[31:0]    = {16'b_0, source1[15:0]}    + {16'b_0, source2[15:0]};
				
			end SUB: begin
			
				result[261:256] = source1[261:256];
				overflow[261:256] = source1[261:256];
			
				// Same logic as above for subtraction.
				working[511:480] = {16'b_0, source1[255:240]} - {16'b_0, source2[255:240]};
				working[479:448] = {16'b_0, source1[239:224]} - {16'b_0, source2[239:224]};
				working[447:416] = {16'b_0, source1[223:208]} - {16'b_0, source2[223:208]};
				working[415:384] = {16'b_0, source1[207:192]} - {16'b_0, source2[207:192]};
				working[383:352] = {16'b_0, source1[191:176]} - {16'b_0, source2[191:176]};
				working[351:320] = {16'b_0, source1[175:160]} - {16'b_0, source2[175:160]};
				working[319:288] = {16'b_0, source1[159:144]} - {16'b_0, source2[159:144]};
				working[287:256] = {16'b_0, source1[143:128]} - {16'b_0, source2[143:128]};
				working[255:224] = {16'b_0, source1[127:112]} - {16'b_0, source2[127:112]};
				working[223:192] = {16'b_0, source1[111:96]}  - {16'b_0, source2[111:96]};
				working[191:160] = {16'b_0, source1[95:80]}   - {16'b_0, source2[95:80]};
				working[159:128] = {16'b_0, source1[79:64]}   - {16'b_0, source2[79:64]};
				working[127:96]  = {16'b_0, source1[63:48]}   - {16'b_0, source2[63:48]};
				working[95:64]   = {16'b_0, source1[47:32]}   - {16'b_0, source2[47:32]};
				working[63:32]   = {16'b_0, source1[31:16]}   - {16'b_0, source2[31:16]};
				working[31:0]    = {16'b_0, source1[15:0]}    - {16'b_0, source2[15:0]};
				
			end MULT: begin
			
				// Painful multiplication logic.
				working[511:480] = ({16'b_0, source1[255:240]} * {16'b_0, source2[255:240]}) + ({16'b_0, source1[239:224]} * {16'b_0, source2[191:176]}) + ({16'b_0, source1[223:208]} * {16'b_0, source2[127:112]}) + ({16'b_0, source1[207:192]} * {16'b_0, source2[63:48]});
				working[479:448] = ({16'b_0, source1[255:240]} * {16'b_0, source2[239:224]}) + ({16'b_0, source1[239:224]} * {16'b_0, source2[175:160]}) + ({16'b_0, source1[223:208]} * {16'b_0, source2[111:96]}) + ({16'b_0, source1[207:192]} * {16'b_0, source2[47:32]});
				working[447:416] = ({16'b_0, source1[255:240]} * {16'b_0, source2[223:208]}) + ({16'b_0, source1[239:224]} * {16'b_0, source2[159:144]}) + ({16'b_0, source1[223:208]} * {16'b_0, source2[95:80]}) + ({16'b_0, source1[207:192]} * {16'b_0, source2[31:16]});
				working[415:384] = ({16'b_0, source1[255:240]} * {16'b_0, source2[207:192]}) + ({16'b_0, source1[239:224]} * {16'b_0, source2[143:128]}) + ({16'b_0, source1[223:208]} * {16'b_0, source2[79:64]}) + ({16'b_0, source1[207:192]} * {16'b_0, source2[15:0]});
				
				working[383:352] = ({16'b_0, source1[191:176]} * {16'b_0, source2[255:240]}) + ({16'b_0, source1[175:160]} * {16'b_0, source2[191:176]}) + ({16'b_0, source1[159:144]} * {16'b_0, source2[127:112]}) + ({16'b_0, source1[143:128]} * {16'b_0, source2[63:48]});
				working[351:320] = ({16'b_0, source1[191:176]} * {16'b_0, source2[239:224]}) + ({16'b_0, source1[175:160]} * {16'b_0, source2[175:160]}) + ({16'b_0, source1[159:144]} * {16'b_0, source2[111:96]}) + ({16'b_0, source1[143:128]} * {16'b_0, source2[47:32]});
				working[319:288] = ({16'b_0, source1[191:176]} * {16'b_0, source2[223:208]}) + ({16'b_0, source1[175:160]} * {16'b_0, source2[159:144]}) + ({16'b_0, source1[159:144]} * {16'b_0, source2[95:80]}) + ({16'b_0, source1[143:128]} * {16'b_0, source2[31:16]});
				working[287:256] = ({16'b_0, source1[191:176]} * {16'b_0, source2[207:192]}) + ({16'b_0, source1[175:160]} * {16'b_0, source2[143:128]}) + ({16'b_0, source1[159:144]} * {16'b_0, source2[79:64]}) + ({16'b_0, source1[143:128]} * {16'b_0, source2[15:0]});
				
				working[255:224] = ({16'b_0, source1[127:112]} * {16'b_0, source2[255:240]}) + ({16'b_0, source1[111:96]} * {16'b_0, source2[191:176]}) + ({16'b_0, source1[95:80]} * {16'b_0, source2[127:112]}) + ({16'b_0, source1[79:64]} * {16'b_0, source2[63:48]});
				working[223:192] = ({16'b_0, source1[127:112]} * {16'b_0, source2[239:224]}) + ({16'b_0, source1[111:96]} * {16'b_0, source2[175:160]}) + ({16'b_0, source1[95:80]} * {16'b_0, source2[111:96]}) + ({16'b_0, source1[79:64]} * {16'b_0, source2[47:32]});
				working[191:160] = ({16'b_0, source1[127:112]} * {16'b_0, source2[223:208]}) + ({16'b_0, source1[111:96]} * {16'b_0, source2[159:144]}) + ({16'b_0, source1[95:80]} * {16'b_0, source2[95:80]}) + ({16'b_0, source1[79:64]} * {16'b_0, source2[31:16]});
				working[159:128] = ({16'b_0, source1[127:112]} * {16'b_0, source2[207:192]}) + ({16'b_0, source1[111:96]} * {16'b_0, source2[143:128]}) + ({16'b_0, source1[95:80]} * {16'b_0, source2[79:64]}) + ({16'b_0, source1[79:64]} * {16'b_0, source2[15:0]});
				
				working[127:96]  = ({16'b_0, source1[63:48]} * {16'b_0, source2[255:240]}) + ({16'b_0, source1[47:32]} * {16'b_0, source2[191:176]}) + ({16'b_0, source1[31:16]} * {16'b_0, source2[127:112]}) + ({16'b_0, source1[15:0]}  * {16'b_0, source2[63:48]});
				working[95:64]   = ({16'b_0, source1[63:48]} * {16'b_0, source2[239:224]}) + ({16'b_0, source1[47:32]} * {16'b_0, source2[175:160]}) + ({16'b_0, source1[31:16]} * {16'b_0, source2[111:96]}) + ({16'b_0, source1[15:0]}  * {16'b_0, source2[47:32]});
				working[63:32]   = ({16'b_0, source1[63:48]} * {16'b_0, source2[223:208]}) + ({16'b_0, source1[47:32]} * {16'b_0, source2[159:144]}) + ({16'b_0, source1[31:16]} * {16'b_0, source2[95:80]}) + ({16'b_0, source1[15:0]}  * {16'b_0, source2[31:16]});
				working[31:0]    = ({16'b_0, source1[63:48]} * {16'b_0, source2[207:192]}) + ({16'b_0, source1[47:32]} * {16'b_0, source2[143:128]}) + ({16'b_0, source1[31:16]} * {16'b_0, source2[79:64]}) + ({16'b_0, source1[15:0]}  * {16'b_0, source2[15:0]});
				
				result[261:256] = {source1[261:259], source2[258:256]}; // Setting the matrix sizes. Takes the rows from source 1 and the columns from source 2.
				overflow[261:256] = {source1[261:259], source2[258:256]}; // Same for the overflow.
				
			end SCALE: begin
			
				result[261:256] = source1[261:256];
				overflow[261:256] = source1[261:256];
				
				working[511:480] = {16'b_0, source1[255:240]} * {16'b_0, source2[255:240]};
				working[479:448] = {16'b_0, source1[239:224]} * {16'b_0, source2[239:224]};
				working[447:416] = {16'b_0, source1[223:208]} * {16'b_0, source2[223:208]};
				working[415:384] = {16'b_0, source1[207:192]} * {16'b_0, source2[207:192]};
				working[383:352] = {16'b_0, source1[191:176]} * {16'b_0, source2[191:176]};
				working[351:320] = {16'b_0, source1[175:160]} * {16'b_0, source2[175:160]};
				working[319:288] = {16'b_0, source1[159:144]} * {16'b_0, source2[159:144]};
				working[287:256] = {16'b_0, source1[143:128]} * {16'b_0, source2[143:128]};
				working[255:224] = {16'b_0, source1[127:112]} * {16'b_0, source2[127:112]};
				working[223:192] = {16'b_0, source1[111:96]}  * {16'b_0, source2[111:96]};
				working[191:160] = {16'b_0, source1[95:80]}   * {16'b_0, source2[95:80]};
				working[159:128] = {16'b_0, source1[79:64]}   * {16'b_0, source2[79:64]};
				working[127:96]  = {16'b_0, source1[63:48]}   * {16'b_0, source2[63:48]};
				working[95:64]   = {16'b_0, source1[47:32]}   * {16'b_0, source2[47:32]};
				working[63:32]   = {16'b_0, source1[31:16]}   * {16'b_0, source2[31:16]};
				working[31:0]    = {16'b_0, source1[15:0]}    * {16'b_0, source2[15:0]};
				
			end TRANS: begin
			
				result[261:256] = source1[261:256];
				overflow[261:256] = source1[261:256];
				
				// Just switching things up for transpose.
				working[511:480] = {16'b_0, source1[255:240]}; // Row of all of the first column values.
				working[479:448] = {16'b_0, source1[191:176]};
				working[447:416] = {16'b_0, source1[127:112]};
				working[415:384] = {16'b_0, source1[63:48]};
				
				working[383:352] = {16'b_0, source1[239:224]}; // Row of all of the second column values.
				working[351:320] = {16'b_0, source1[175:160]};
				working[319:288] = {16'b_0, source1[111:96]};
				working[287:256] = {16'b_0, source1[47:32]};
				
				working[255:224] = {16'b_0, source1[223:208]}; // Etc.
				working[223:192] = {16'b_0, source1[159:144]};
				working[191:160] = {16'b_0, source1[95:80]};
				working[159:128] = {16'b_0, source1[31:16]};
				
				working[127:96]  = {16'b_0, source1[207:192]};
				working[95:64]   = {16'b_0, source1[143:128]};
				working[63:32]   = {16'b_0, source1[79:64]};
				working[31:0]    = {16'b_0, source1[15:0]};
				
			end
		endcase
		
		// Seperate result and overflow from the working matrix.
		result[255:240] = working[495:480];
		result[239:224] = working[463:448];
		result[223:208] = working[431:416];
		result[207:192] = working[399:384];
		result[191:176] = working[367:352];
		result[175:160] = working[335:320];
		result[159:144] = working[303:288];
		result[143:128] = working[272:256];
		result[127:112] = working[239:224];
		result[111:96]  = working[207:192];
		result[95:80]   = working[175:160];
		result[79:64]   = working[143:128];
		result[63:48]   = working[111:96];
		result[47:32]   = working[79:64];
		result[31:16]   = working[47:32];
		result[15:0]    = working[15:0];
		
		overflow[255:240] = working[511:496];
		overflow[239:224] = working[479:464];
		overflow[223:208] = working[447:432];
		overflow[207:192] = working[415:400];
		overflow[191:176] = working[383:368];
		overflow[175:160] = working[351:336];
		overflow[159:144] = working[319:304];
		overflow[143:128] = working[287:273];
		overflow[127:112] = working[255:240];
		overflow[111:96]  = working[223:208];
		overflow[95:80]   = working[191:176];
		overflow[79:64]   = working[159:144];
		overflow[63:48]   = working[127:112];
		overflow[47:32]   = working[95:80];
		overflow[31:16]   = working[63:48];
		overflow[15:0]    = working[31:16];
		
		done = 1'b_1;
	end

endmodule