// Code by Claude Garrett V, 12/9/2019

module ExecutionEngine(clock, reset);
	
	// IO:
	input clock, reset;
	
	// States.
	parameter FETCH0 = 1;
	parameter FETCH1 = 2;
	parameter FETCH2 = 3;
	
	parameter DECODE0 = 4;
	parameter DECODE1 = 5;
	parameter DECODE2 = 6;
	parameter DECODE3 = 7;
	parameter DECODE4 = 8;
	parameter DECODE5 = 9;
	parameter DECODE6 = 10;
	
	parameter EXECUTE0 = 11;
	
	parameter WRITEBACK0 = 12;
	parameter WRITEBACK1 = 13;
	parameter WRITEBACK2 = 14;
	parameter WRITEBACK3 = 15;
	parameter WRITEBACK4 = 16;

	// Global Variables:
	tri [261:0] bus; // Main bus.
	
	// Enables:
	reg enableALU;
	reg compute;
	reg exportAddr;
	
	// Execution Variables:
	reg [255:0] packet;
	reg [6:0] counter;
	
	reg [4:0] current;
	reg [4:0] next;
	
	// Instruction breakdown:
	wire [31:0] inst;
	assign inst = packet[255:224];
	
	wire [6:0] source1;
	assign source1 = inst[15:9];
	
	wire rms2;
	assign rms2 = inst[16]; // Register when 1, address when 0.
	
	wire [7:0] source2;
	assign source2 = inst[7:0];
	
	wire imm; // False = immediate used.
	assign imm = inst[8];
	
	wire rms1;
	assign rms1 = inst[7]; // Register when 1, address when 0.
	
	wire [6:0] dest;
	assign dest = inst[23:17];
	
	wire rmdest;
	assign rmdest = inst[24]; // Register when 1, address when 0.
	
	wire [6:0] operation;
	assign operation = inst[31:25];
	
	// ALU:
	reg s1ALU, s2ALU, outALU, outALUOver;
	wire ALUdone;
	
	//  ALU(bus, enable,    in1,   in2,   output, over, compute,    operation, done);
	ALU alu(reset, bus, enableALU, s1ALU, s2ALU, outALU, outALUOver, compute, operation, ALUdone);
	
	// Instruction Memory:
	reg importAddressInstMem, readInstMem, enableInstMem;
	
	//                InstructionMemory(bus, importAddress,        read,    enable,        reset);
	InstructionMemory instructionMemory(bus, importAddressInstMem, readInstMem, enableInstMem, reset);
	
	// Matrix Memory:
	reg writeMatrix, importAddressMatMem, readMatMem, enableMatMem, overMem;
	
	//           MatrixMemory(bus, write,       importAddress,       read,       enable,       reset);
	MatrixMemory matrixMemory(bus, writeMatrix, importAddressMatMem, readMatMem, enableMatMem, reset, overMem, clock);
	
	// Registers:
	reg writeReg, importAddressReg, readReg, enableReg, overReg;
	
	//        Registers(bus, write,    importAddress,    read,    enable,    reset);
	Registers registers(bus, writeReg, importAddressReg, readReg, enableReg, reset, overReg, clock);
	
	// Bus Assignments:
	assign bus = (current == FETCH0 && exportAddr == 1) ? {255'h_0, counter} : 262'h_z;
	assign bus = (current == DECODE1) ? {255'h_0, source1} : 262'h_z;
	assign bus = (current == DECODE4) ? {254'h_0, source2} : 262'h_z;
	assign bus = (current == WRITEBACK0) ? {255'h_0, dest} : 262'h_z;
	assign bus = (current == WRITEBACK2) ? {255'h_0, (dest + 1)} : 262'h_z;
	
	initial begin
		exportAddr = 0;
		enableALU = 0;
		compute = 0;
		s1ALU = 0;
		s2ALU = 0;
		outALU = 0;
		outALUOver = 0;
		
		enableInstMem = 0;
		importAddressInstMem = 0;
		readInstMem = 0;
		
		enableMatMem = 0;
		writeMatrix = 0;
		importAddressMatMem = 0;
		readMatMem = 0;
		overMem = 0;
		
		enableReg = 0;
		writeReg = 0;
		importAddressReg = 0;
		readReg = 0;
		overReg = 0;
		
		packet = 0;
		counter = 0;
		
		current = FETCH0;
		next = FETCH0;
	end
	
	always @ (posedge reset) begin
		exportAddr = 0;
		enableALU = 0;
		compute = 0;
		s1ALU = 0;
		s2ALU = 0;
		outALU = 0;
		outALUOver = 0;
		
		enableInstMem = 0;
		importAddressInstMem = 0;
		readInstMem = 0;
		
		enableMatMem = 0;
		writeMatrix = 0;
		importAddressMatMem = 0;
		readMatMem = 0;
		overMem = 0;
		
		enableReg = 0;
		writeReg = 0;
		importAddressReg = 0;
		readReg = 0;
		overReg = 0;
		
		packet = 0;
		counter = 0;
		
		current = FETCH0;
		next = FETCH0;
		
	end
	
	always @ (posedge clock) begin
		if(inst == 32'h_8000000) $stop();
	
		current = next;
	
		case(current)
			FETCH0: begin
				// If lower three bits of the counter == 7, time for new instruction packet. Follow the FETCH states.
				// Otherwise, simply shift the packet by 32 so that inst is accurate. Go to DECODE0 afterwards.
				if(counter[2:0] == 3'h_7 || counter == 7'b_0) begin // GET THE NEW PACKET
					
					// Memory: Configure to import an address and enable.
					enableInstMem = 1;
					importAddressInstMem = 1;
					
					// Execute: Export counter over the bus and enable.
					exportAddr = 1;
					
					next = FETCH1;
					$display("Gathering new Instruction Packet");
					
				end else begin
					packet = packet << 32;
					next = DECODE0;
					$display("Current Instruction = %h", inst);
					
				end
				
				
				
			end
			FETCH1: begin
				importAddressInstMem = 0;
				exportAddr = 0;
			
				// Memory: Configure to import an address and enable.
				readInstMem = 1;
				
				#5 packet = bus[255:0];
				
				
				next = FETCH2;
			end
			FETCH2: begin
				// Disable IO for Mem and Exe.
				
				// Import instruction packet and enable.
				
				readInstMem = 0;
				enableInstMem = 0;
				
				next = DECODE0;
				$display("Current Instruction = %h", inst);
			end
			DECODE0: begin
				// Interpret next instruction and send signals to the ALU. Mostly automatic in the instruction breakdown.
				next = DECODE1;
				counter = counter + 1;
			end
			DECODE1: begin
				if(rms1 == 0) begin // 0 means memory.
					importAddressMatMem = 1;
					enableMatMem = 1;
				end else begin // 1 means register.
					importAddressReg = 1;
					enableReg = 1;
				end
				
				// Assign bus takes care of the rest.
				next = DECODE2;
			end
			DECODE2: begin
				if(rms1 == 0) begin // 0 means memory.
					importAddressMatMem = 0;
					readMatMem = 1;
				end else begin // 1 means register.
					importAddressReg = 0;
					readReg = 1;
				end
				
				enableALU = 1'b_1;
				s1ALU = 1'b_1;
				
				next = DECODE3;
			end
			DECODE3: begin
				if(rms1 == 0) begin // 0 means memory.
					readMatMem = 0;
					enableMatMem = 0;
				end else begin // 1 means register.
					readReg = 0;
					enableReg = 0;
				end
			
				enableALU = 1'b_0;
				s1ALU = 1'b_0;
				
				next = DECODE4;
			end
			DECODE4: begin
				if(rms2 == 0) begin // 0 means memory.
					importAddressMatMem = 1;
					enableMatMem = 1;
				end else begin // 1 means register.
					importAddressReg = 1;
					enableReg = 1;
				end
				
				next = DECODE5;
			end
			DECODE5: begin
				if(rms2 == 0) begin // 0 means memory.
					importAddressMatMem = 0;
					readMatMem = 1;
				end else begin // 1 means register.
					importAddressReg = 0;
					readReg = 1;
				end
			
				enableALU = 1'b_1;
				s2ALU = 1'b_1;
				
				next = DECODE6;
			end
			DECODE6: begin
				if(rms2 == 0) begin // 0 means memory.
					readMatMem = 0;
					enableMatMem = 0;
				end else begin // 1 means register.
					readReg = 0;
					enableReg = 0;
				end
			
				enableALU = 1'b_0;
				s2ALU = 1'b_0;
				
				next = EXECUTE0;
			end
			EXECUTE0: begin
				compute = 1'b_1;
				if(ALUdone == 1'b_1) next = WRITEBACK0;
			end
			WRITEBACK0: begin
				compute = 1'b_0;
				
				if(rmdest == 1'b_0) begin // rmdest = 0 memory
					enableMatMem = 1;
					importAddressMatMem = 1;
				end else begin
					enableReg = 1;
					importAddressReg = 1;
				end // rmdest = 1 register.
				
				next = WRITEBACK1;
			end
			WRITEBACK1: begin
				enableALU = 1'b_1;
				outALU = 1'b_1;
			
				if(rmdest == 1'b_0) begin // rmdest = 0 memory
					importAddressMatMem = 0;
					writeMatrix = 1;
				end else begin
					importAddressMatMem = 0;
					writeReg = 1;
				end // rmdest = 1 register.
				
				next = WRITEBACK3;
			end
			WRITEBACK2: begin // UNUSED.
				enableALU = 1'b_0;
				outALU = 1'b_0;
			
				if(rmdest == 1'b_0) begin // rmdest = 0 memory
					writeMatrix = 0;
					importAddressMatMem = 1;
				end else begin
					writeReg = 0;
					importAddressReg = 1;
				end // rmdest = 1 register.
				
				next = WRITEBACK3;
			end
			WRITEBACK3: begin
				outALU = 1'b_0;
				outALUOver = 1'b_1;
				if(rmdest == 1'b_0) begin // rmdest = 0 memory
					overMem = 1;
				end else begin
					overReg = 1;
				end // rmdest = 1 register.
				
				next = WRITEBACK4;
			end
			WRITEBACK4: begin
				enableALU = 1'b_0;
				outALUOver = 1'b_0;
				if(rmdest == 1'b_0) begin // rmdest = 0 memory
					writeMatrix = 0;
					enableInstMem = 0;
					overMem = 0;
				end else begin
					writeReg = 0;
					enableReg = 0;
					overReg = 0;
				end // rmdest = 1 register.
				
				next = FETCH0;
			end
		endcase
		
	end
	


endmodule

