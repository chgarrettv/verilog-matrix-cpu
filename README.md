	INTRODUCTION:
This is a custom CPU simulation created written in Verilog, by Claude Garrett V, based upon guidelines provided in a verilog and computer architecture course. 
The system is capable of operating upon matrices and integers, with support of matrices that are up to 4x4 with elements that are 16 bits in length. 
Alternatively, one can use integers that are up to 256 bits in length. 

Included is an external assembler that will take custom assembly language that is easier to read/
manipulate and correctly translate it into the hexidecimal code (machine language) that the
system can read. A program will be split by the assembler into two files:
matrices.txt and instructions.txt. The matrices file contains all variables
that the user defines in their program in their proper locations. The
instructions file contains all of the instructions that the user has
declared in their program. Note that the instructions are in packets of 8 (32 bits each),
so reading them is not as straight forward as with the matrices/integers.

To write a program, refer to "HOW TO WRITE A PROGRAM" below and follow the custom code formats.
Write your program in program.txt and run Assembler.exe to assemble the program.
The assembler has some basic errors it will throw such as for unrecognized
commands, but it is mostly up to the user to use it correctly.
The source code for the assembler has also been
included for those that would prefer to generate the .exe themselves.

Please be sure that the assembler has correctly processed the input before
running the program on the computer. A note will display at the bottom
noting completion, as well as notes for each individual command processed.

The computer will run on a testbench inside of EngineTest.v
Elaboration on the ISA can be found below in the "THE ISA EXPLAINED" section.

Matrices are in the following format: 
3 bits of row size, 3 bits of column size, then 256 bits of data.
The 256 bits start with 16 bits of R1C1, R1C2, ... R4C4.

Notes for future development: Matrix operations seem to be occuring and the results are properly stored
in memory. Working on validating the individual operations.



	HOW TO WRITE A PROGRAM: (Explaination of the custom assembly language)
First, the assembler.exe will look for program.txt, so be certain to name your program file accordingly.

 #: defines an instruction at a memory location, where # is an address in hexidecimal.
 Order does not matter, but it is recommended to keep operations in order.
 "//" Indicates a comment. Only valid at the end of an operation or on its own line.

	Instructions:
 stop;			// Stops all operations.
 addint/i DEST, S1, S2;	// Add two integers. (immediate form also available)
 addmat DEST, S1, S2;		// Add two matrices.
 subint/i DEST, S1, S2;	// Subtract two integers. (S1 - S2) (immediate form also available)
 submat DEST, S1, S2;		// Subtract two matrices.
 multint/i DEST, S1, S2;	// Multiply two integers. (immediate form also available)
 multmat DEST, S1, S2;	// Multiply two matrices. (S1 * S2)
 div/i DEST, S1, S2; 		// INTEGERS ONLY. // Uses TRANS Opcode. (S1 / S2) (immediate form also available)
 scale DEST, S1, IMM; 	// MATRICES ONLY. MUST HAVE IMMEDIATE. Linearly scales the matrix.
 trans DEST, S1; 		// MATRICES ONLY. Transposes the matrix.

	****/i  in the above instructions means immediates can replace S2 for that instruction. Specify by adding
	'i' to the end of the instruction, such as in "addinti".

	Alternate Sources and Destinations:
 S1, S2, or DEST can be in the following forms
 Registers: 			r#, # in hex.
 Matrix Memory Address: 	m#, # in hex.
 For immediates, use 		i#, where # is the immediate in hex. For S2 only.

	Defining a Matrix:

 Start by indicating the memory location of the matrix:
 m##: where ## is the memory location in hexidecimal. the 'm' tells the assembler you are defining a matrix.

 Similar to defining arrays in other languages, define a row/vector like this:
m#: {##, ##, ##, ##} // Where ## is a hexidecimal number.

 A matrix will just be a set of rows/vectors, like this:
m#: {{##, ##, ##, ##}, {##, ##, ##, ##}, {##, ##, ##, ##}, {##, ##, ##, ##}}

 The above would define a 4x4 matrix. Note that all values MUST fit into 16 bits. The size of the matrix will be calculated automatically.

	Defining an Integer:

 Start the same way you would with a matrix but only define a single number. Here is an example:

m0: 48;

 The above would place the number 48 into the first data memory location. The 'm' is retained as matrix and integer memory is combined.


	Example Code:
	
md: {{18}, {19}, {27}, {4}}; // A 1x4 matrix.
m0: {{4, 12, 4, 34}, {7, 6, 11, 9}, {9, 2, 8, 13}, {2, 15, 16, 3}}; // A 4x4 matrix, max for the computer to operate on.

5: submat m5, m3, r16; // Subtract matrix in reg 16 from m3, and save the result to memory location 5.
8: addinti r6, m5, iff; // Add 0xff to memory location 5, save it to register 6.

Sample validation program:

m0: {{4, 12, 4, 34}, {7, 6, 11, 9}, {9, 2, 8, 13}, {2, 15, 16, 3}}; // Matrix 1.
m1: {{23, 45, 31, 22}, {7, 6, 4, 1}, {18, 12, 13, 12}, {13, 5, 7, 19}}; // Matrix 2.
0: addmat m2, m0, m1; 	// Sums the two defined matrices.
1: submat m3, m2, m0; 	// Subtracts matrix 1 from the sum.
2: trans m4, m2; 	// Transposes the sum matrix.
3: scale r0, m4, i4; 	// Scales the transposed matrix by 4.
4: multmat m5, r0, m4; 	// Multiplies the scaled matrix by the transposed matrix.
5: stop; 		// Terminates the program.



	THE ISA EXPLAINED: (Explaination of the custom machine language)
Instructions in machine language will be 32 bits in length, and will follow this format:

XXXX_XXX_ADDD_DDDD_ARRR_RRRR_A_IIII_IIII

XXXXXXX: Opcode, 7 bits in length.


X6: 0 = Normal, 1 = STOP.
 X5: 0 = ALU in Integer Mode, 1 = ALU in Matrix Mode
  X4: 1 = ADD
   X3: 1 = SUB
    X2: 1 = MULT
     X1: 1 = SCALE
      X0: 1 = TRANS

ADDDDDDD: Destination Selection, 8 bits in length.

A: 0 = Memory Address, 1 = Register
 DDDDDDD: Memory/Register value

ARRRRRRR: Source 1 Selection, 8 bits in length.

A: 0 = Memory Address, 1 = Register
 RRRRRRR: Memory/Register value

AIIIIIIII: Source 2 Selection, 9 bits in length, for an 8 bit long immediate.

A: 0 = Immediate, 1 = Register
 IIIIIIII: Immediate/Register value
