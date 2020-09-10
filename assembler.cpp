// Written 11/22/2019 by Claude Garrett V.

#include <iostream>
#include <fstream>
#include <string>
#include <iomanip>
#include <sstream>

#define NUM_INSTRUCTION_LINES 128
#define INST_PER_LINE 8
#define NUM_MATRICES 128

#define COMMENT "//"

using namespace std;

int destSourceDec(string loc) {

    switch(loc[0]) {
        case 'm': // Memory Address.
            return (2 * (int)stol(loc.substr(1,loc.size()), nullptr, 16));
            break;
        case 'r': // Register.
            return 0x80 +  (2 * (int)stol(loc.substr(1,loc.size()), nullptr, 16));
            break;
        case 'i':
            return (int)stol(loc.substr(1,loc.size()), nullptr, 16);
            break;
        default:
            throw "ERROR: Invalid source/destination/immediate encountered. Line ";
            break;
            return 0;
    }
}

string matrixTrimmer(string mat) {
    for(int i = 0; i < mat.size(); i++) {
        if(mat[i] == ';') {
            mat.erase(i);
            return mat;
        }
        if(mat[i] == ' ' || mat[i] == '{' || mat[i] == '}') {
            mat.erase(i, 1);
            i--;
        } else if(mat[i] == ',') mat[i] = ' ';
    }
    return mat;
}

int main()
{
    uint32_t memory[NUM_INSTRUCTION_LINES * INST_PER_LINE];
    string matrixmem[NUM_MATRICES / 2];

    ifstream prog; prog.open("program.txt"); // The file written by the user for the computer to execute.
    ofstream instructions; instructions.open("instructions.txt"); // Storage of all instructions.
    ofstream matrices; matrices.open("matrices.txt"); // Where the matrices are stored.

    // Fill memory and matrixmem with zeroes.
    for(int i = 0; i < NUM_INSTRUCTION_LINES * INST_PER_LINE; i++) {
        memory[i] = 0;
    }

    for(int i = 0; i < NUM_MATRICES / 2; i++) {
        matrixmem[i] = "000000000000000000000000000000000000000000000000000000000000000000";
    }

    string currentLine = "";
    int programNumber = 0; // Used to keep track of the line number for the user-written program.

    int s = 0;
    int e = 0;
    string lineNum = "";
    string instr = "";
    string dest = "";
    string s1 = "";
    string s2 = "";

    int memloc = 0;
    int operation = 0;
    int source1 = 0;
    int source2 = 0;
    int destination = 0;

    int matnum = 0;
    bool matrix = false;

    int rows = 0;
    int columns = 0;

    // First, correct the input to make it into a valid instruction.

    // Takes in instruction and spits out pieces:
    while(getline(prog, currentLine)) {
        cout << currentLine << endl;

        if(currentLine.find(COMMENT) == 0) continue; // Line is only a comment, skip it.
        if(currentLine.find(COMMENT)) { // Removes comments for error avoidance.
            currentLine = currentLine.substr(0, currentLine.find(COMMENT));
        }

        e = currentLine.find(":"); // Indicates a valid instruction. The below decomposes it into pieces for interpretation.
        if(e > 0) {
            if(currentLine[0] != 'm') { // Instruction definition.
                lineNum = currentLine.substr(0, e);
                cout << "\tInstruction Memory Location: " << lineNum << endl;

                s = e + 2;
                e = currentLine.find(" ", s);
                instr = currentLine.substr(s, e - s);
                cout << "\tInstruction: " << instr << endl;

                if(instr != "stop;") {
                    s = e + 1;
                    e = currentLine.find(",", s);
                    dest = currentLine.substr(s, e - s);
                    cout << "\tDestination: " << dest << endl;
                    if(instr != "trans") { // Every other operation has a source 1 and a source 2.
                        s = e + 2;
                        e = currentLine.find(",", s);
                        s1 = currentLine.substr(s, e - s);
                        cout << "\tSource 1: " << s1 << endl;

                        s = e + 2;
                        e = currentLine.find(";", s);
                        s2 = currentLine.substr(s, e - s);
                        cout << "\tSource 2: " << s2 << endl << endl;
                    } else { // Transpose has no source 2.
                        s = e + 2;
                        e = currentLine.find(";", s);
                        s1 = currentLine.substr(s, e - s);
                        cout << "\tSource 1: " << s1 << endl;
                    }
                } else instr = "stop";
            } else { // Matrix or integer definition.
                rows = 0;
                columns = 1;

                matrix = true;

                // Find the matrix number.
                matnum = (int)stol(currentLine.substr(1, currentLine.find(':')), nullptr, 16);

                if(currentLine.find('{') != std::string::npos) { // Matrix

                    // Working matrix[row][column]

                    // Cut down currentLine to only the matrix values.
                    currentLine = currentLine.substr(currentLine.find('{'), (currentLine.find_last_of('}') - currentLine.size()));
                    cout << "\tMatrix Number: " << hex << matnum << endl;
                    if(matnum == 0) cout << "\tMatrix Memory Location: " << hex << matnum << endl;
                    else cout << "\tMatrix Memory Location: " << hex << ((matnum * 2) - 1) << endl;

                    // Count the number of brace pairs.
                    for(int i = 1; i < currentLine.size(); i++) {
                        if(currentLine[i] == '{') {
                            rows++;
                        }
                    }

                    if(rows == 0) rows = 1;

                    for(int i = 1; i < currentLine.size(); i++) {
                        if(currentLine[i] == '}') break;
                        if(currentLine[i] == ',') columns++;
                    }

                    cout << "\tRows: " << rows << "\n\tColumns: " << columns << endl;

                    currentLine = matrixTrimmer(currentLine);

                    cout << "\tTrimmed Matrix: " << currentLine << endl;

                    // Take the trimmed matrix and put it into the array:

                    // Rolling it into a 262 bit string. First 6 indicate size, rest indicate values.
                    std::stringstream matstream;

                    string temp = "";
                    int columncount = 1;

                    matstream << hex << ((rows << 3) + columns);

                    temp = "";
                    int r = 0;
                    int c = 0;

                    for(int i = 0; i < currentLine.size(); i++) {
                        if(currentLine[i] != ' ') {
                            temp += currentLine[i];
                        } else {
                            matstream << setfill('0') << setw(4) << temp;
                            temp = "";
                            c++;
                            if(c == columns) {
                                for(int j = 0; j < 4 - columns; j++) matstream << setfill('0') << setw(4) << 0;
                                c = 0;
                            }
                        }
                    }
                    matstream << setfill('0') << setw(4) << temp;
                    for(int j = 0; j < 4 - columns; j++) matstream << setfill('0') << setw(4) << 0;

                    for(int j = 0; j < 4 - rows; j++) matstream << setfill('0') << setw(16) << 0;

                    matrixmem[matnum] = matstream.str();
                    cout << endl << "\tMatrix Value Saved to Memory: "<< matrixmem[matnum] << endl << endl;

                } else { // Integer.

                    matrix = true;

                    // In the format m#: int;
                    currentLine = currentLine.substr(currentLine.find(' ') + 1, (currentLine.find(';') - (currentLine.find(' ') + 1)));

                    cout << "\tInteger Number: " << hex << matnum << endl;
                    if(matnum == 0) cout << "\tInteger Memory Location: " << hex << matnum << endl;
                    else cout << "\tInteger Memory Location: " << hex << ((matnum * 2) - 1) << endl;

                    std::stringstream intstream;

                    int t = (int)stol(currentLine, nullptr, 10);

                    intstream << hex << t;

                    matrixmem[matnum] = intstream.str();

                    cout << endl << "\tInteger Value Saved to Memory: "<< matrixmem[matnum] << endl << endl;
                }


            }
        }

        // Line is now broken down for use in a switch statement.
        if(!matrix) { // Decode the operation and assemble the instruction.
            try {
                if(instr == "stop") {
                    operation = 0x80000000;
                    destination = 0;
                    source1 = 0;
                    source2 = 0;
                    cout << endl;
                } else if(instr == "addint") { // Int addition.
                    operation = 0x20000000;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "addinti") {
                    operation = 0x20000100;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                    //cout << hex << (destination << 17) << endl << " " << (source1 << 9) << endl << " " << source2 << endl;
                } else if(instr == "addmat") { // Mat addition.
                    operation = 0x60000000;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "subint") { // Int subtraction.
                    operation = 0x10000000;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "subinti") {
                    operation = 0x10000100;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "submat") { // Mat subtraction.
                    operation = 0x50000000;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "multint") { // Int multiplication.
                    operation = 0x08000000;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "multinti") {
                    operation = 0x08000100;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "multmat") { // Mat multiplication.
                    operation = 0x48000000;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "divint") { // Int division.
                    operation = 0x02000000;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "divinti") {
                    operation = 0x02000100;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "scale") { // Mat scaling.
                    operation = 0x44000100;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = destSourceDec(s2);
                } else if(instr == "trans") { // Mat transpose.
                    operation = 0x42000000;
                    destination = destSourceDec(dest);
                    source1 = destSourceDec(s1);
                    source2 = 0; // No source 2 for transpose.
                    cout << endl; // Cause I am a sucker for formatting.
                } else {
                    throw "ERROR: Invalid instruction encountered. Line ";
                }

                memloc = (int)stol(lineNum, nullptr, 16);
                memory[memloc] = operation + (destination << 17) + (source1 << 9) + source2;
                cout << hex << "\tStored: " << memory[memloc] << endl;

            } catch (const char* message) {
                cerr << message << programNumber << endl;
                cerr << "\t Memory Location: " << lineNum << endl;
                cerr << "\t Instruction: " << instr << endl;
                cerr << "\t Destination: " << dest << endl;
                cerr << "\t Source 1: " << s1 << endl;
                cerr << "\t Source 2: " << s2 << endl;
                return 0;
            }
            cout << endl;
        }
        programNumber++;
        matrix = false;
    }

    // Write the data to instructions.txt.

    for(int i = 0; i < NUM_INSTRUCTION_LINES; i++) {
        for(int j = 0; j < INST_PER_LINE; j++) {
            instructions << hex << setfill('0') << setw(8) << memory[(i * INST_PER_LINE) + j];
        }
        instructions << endl;
    }

    // Write matrices to matrices.txt.

    for(int i = 0; i < NUM_MATRICES / 2; i++) {
        matrices << setfill('0') << setw(66) << matrixmem[i] << endl;
        matrices << setfill('0') << setw(66) << 0 << endl;
    }

    // Close everything.
    prog.close();
    instructions.close();
    matrices.close();

    cout << "\n\nFinished compiling.\nProgram can now be terminated.\n";
    cin >> s1;

    return 0;
}
