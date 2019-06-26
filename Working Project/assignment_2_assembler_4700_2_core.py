# Assembler ELEC3720
# Joshua Beverley & Radhika Feron

def main():
    print ("hello world")
    machine1 = open("C:\\ELEC4700\\machine_code_cpu0.txt", "r")
    output1 = open("C:\\ELEC4700\\machine_output_cpu0.txt", "w")
    contents1 = machine1.readlines()
    machine2 = open("C:\\ELEC4700\\machine_code_cpu1.txt", "r")
    output2 = open("C:\\ELEC4700\\machine_output_cpu1.txt", "w")
    contents2 = machine2.readlines()
    core(contents1, output1)
    core(contents2, output2)

def core(contents, output):
    for line in contents:
        line = line.replace("\r","")
        line = line.replace("\n","")
        instruction = line.split(' ', 1)
        try: 
            register_string = divide(instruction[0], instruction[1])
        except IndexError:
            register_string = "ERROR: not enough arguments"
        error_check = register_string.split(":")
        if (error_check[0] == "ERROR"):
            print (register_string + ". Input instruction was: " + line)
        else:# (success == 1):
            add_opcode = instruction_dictionary[instruction[0]] + "" + register_string
            output.write(add_opcode + "\n")
               
def divide(instruction, registers):
    if ((instruction == "add") or (instruction == "addu") or (instruction == "sub") or (instruction == "subu") or (instruction == "and") or (instruction == "or")
    or (instruction == "xor") or (instruction == "nor") or (instruction == "slt") or (instruction == "sltu")):
        # ALL instructions with $rd, $rs, $rt
        values = registers.split(' ')
        if (len(values) != 3):
            return ("ERROR: incorrect length ALU")
        else:
            values[0] = values[0].replace("$", "")
            values[0] = values[0].replace(",", "")
            values[1] = values[1].replace("$", "")
            values[1] = values[1].replace(",", "")
            values[2] = values[2].replace("$", "")
            try:
                if ((int(values[0]) > 31) or (int(values[0]) < 0) or (int(values[1]) > 31) or (int(values[1]) < 0) or (int(values[2]) > 31) or (int(values[2]) < 0)):
                    return "ERROR: register number entered out of range"
                return str(bindigits(int(values[1]), 5) + bindigits(int(values[2]), 5) + bindigits(int(values[0]), 5) + "0000000000")
            except ValueError:
                return "ERROR: incorrect syntax ALU"
    elif ((instruction == "sll") or (instruction == "srl") or (instruction == "sra")):
        # ALL instructions with $rd, $rt, $rs
        values = registers.split(' ')
        if (len(values) != 3):
            return ("ERROR: incorrect length shifter with $rs")
        else:
            values[0] = values[0].replace("$", "")
            values[0] = values[0].replace(",", "")
            values[1] = values[1].replace("$", "")
            values[1] = values[1].replace(",", "")
            values[2] = values[2].replace("$", "")
            try:
                if ((int(values[0]) > 31) or (int(values[0]) < 0) or (int(values[1]) > 31) or (int(values[1]) < 0) or (int(values[2]) > 31) or (int(values[2]) < 0)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[2]), 5) + bindigits(int(values[1]), 5) + bindigits(int(values[0]), 5) + "0000000000")
            except ValueError:
                return "ERROR: incorrect syntax shifter with $rs"
    elif ((instruction == "sllv") or (instruction == "srlv") or (instruction == "srav")):
        # ALL instructions with $rd, $rt, constant in instruction[8:11]
        values = registers.split(' ')
        if (len(values) != 3):
            return ("ERROR: incorrect length shifter with shamt")
        else:
            values[0] = values[0].replace("$", "")
            values[0] = values[0].replace(",", "")
            values[1] = values[1].replace("$", "")
            values[1] = values[1].replace(",", "")
            try: 
                if ((int(values[0]) > 31) or (int(values[0]) < 0) or (int(values[1]) > 31) or (int(values[1]) < 0) or (int(values[2]) > 31) or (int(values[2]) < 0)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[2]), 5) + bindigits(int(values[1]), 5) + bindigits(int(values[0]), 5) + "0000000000")
            except ValueError:
                return "ERROR: incorrect syntax shifter with shamt"
    elif ((instruction == "mfhi") or (instruction == "mflo")):
        # ALL instructions with $rd, output 8'b0 + $rd
        if " " in registers:
            return ("ERROR: incorrect length MUL/DIV")
        else:
            values = registers.replace("$", "")
            try: 
                if ((int(values) > 31) or (int(values) < 0)):
                    return "ERROR: register number entered out of range" 
                return str("0000000000" + bindigits(int(values), 5) + "0000000000")
            except ValueError:
                return "ERROR: incorrect syntax MUL/DIV"
    elif ((instruction == "mthi") or (instruction == "mtlo") or (instruction == "jr") or (instruction == "jalr")):
        # ALL instructions with $rs, $rs + output 8'b0
        if " " in registers:
            return ("ERROR: incorrect length MUL/DIV/R-type jump")
        else:
            values = registers.replace("$", "")
            try:
                if ((int(values) > 31) or (int(values) < 0)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values), 5) + "00000000000000000000")
            except ValueError:
                return "ERROR: incorrect syntax MUL/DIV/R-type jump"
    elif ((instruction == "mult") or (instruction == "div")):
        # ALL instructions with $rs, $rt
        values = registers.split(' ')
        if (len(values) != 2):
            return ("ERROR: incorrect length MUL/DIV")
        else:
            values[0] = values[0].replace("$", "")
            values[0] = values[0].replace(",", "")
            values[1] = values[1].replace("$", "")
            try:
                if ((int(values[0]) > 31) or (int(values[0]) < 0) or (int(values[1]) > 31) or (int(values[1]) < 0)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[0]), 5) + bindigits(int(values[1]), 5) + "000000000000000")
            except ValueError:
                return "ERROR: incorrect syntax MUL/DIV"
    elif ((instruction == "blez") or (instruction == "bgtz") or (instruction == "bgez") or (instruction == "bltz")):
        # ALL instructions with $rs, constant in instruction [0:7]
        values = registers.split(' ')
        if (len(values) != 2):
            return ("ERROR: incorrect length branch <>")
        else:
            values[0] = values[0].replace("$", "")
            values[0] = values[0].replace(",", "")
            try:
                if ((int(values[0]) > 31) or (int(values[0]) < 0) or (int(values[1]) > 16383) or (int(values[1]) < -16384)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[0]), 5) + "00000" + bindigits(int(values[1]), 15))
            except ValueError:
                return "ERROR: incorrect syntax branch <>"
    elif ((instruction == "j") or (instruction == "jal")):
        # ALL instructions with constant in instruction [0:11]
        if " " in registers:
            return ("ERROR: incorrect length jump")
        else:
            try:
                if ((int(registers) > 32767) or (int(registers) < 0)):
                    return "ERROR: register number entered out of range" 
                return str("0000000000" + bindigits(int(registers), 15))
            except ValueError:
                return "ERROR: incorrect syntax branch jump"   
    elif ((instruction == "addiu") or (instruction == "sltiu") or (instruction == "andi") or (instruction == "ori") or (instruction == "xori") or (instruction == "lui")):
        # ALL instructions with $rd, $rs, $rt
        values = registers.split(' ')
        if (len(values) != 3):
            return ("ERROR: incorrect length memory/immediate ==/!=")
        else:
            values[0] = values[0].replace("$", "")
            values[0] = values[0].replace(",", "")
            values[1] = values[1].replace("$", "")
            values[1] = values[1].replace(",", "")
            try:
                if ((int(values[0]) > 31) or (int(values[0]) < 0) or (int(values[1]) > 31) or (int(values[1]) < 0) or (int(values[2]) > 32767) or (int(values[2]) < 0)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[1]), 5) + bindigits(int(values[0]), 5) + bindigits(int(values[2]), 15))
            except ValueError:
                return "ERROR: incorrect syntax memory/immediate ==/!="     
    elif ((instruction == "lb") or (instruction == "lh") or (instruction == "lw") or (instruction == "lbu") or (instruction == "lhu") or (instruction == "sb") 
    or (instruction == "sh") or (instruction == "sw") or (instruction == "addi") or (instruction == "slti")):
        # ALL instructions with $rd, $rs, $rt
        values = registers.split(' ')
        if (len(values) != 3):
            return ("ERROR: incorrect length memory/immediate ==/!=")
        else:
            values[0] = values[0].replace("$", "")
            values[0] = values[0].replace(",", "")
            values[1] = values[1].replace("$", "")
            values[1] = values[1].replace(",", "")
            try:
                if ((int(values[0]) > 31) or (int(values[0]) < 0) or (int(values[1]) > 31) or (int(values[1]) < 0) or (int(values[2]) > 16383) or (int(values[2]) < -16384)):
                    return "ERROR: register number entered out of range (negatives)" 
                return str(bindigits(int(values[1]), 5) + bindigits(int(values[0]), 5) + bindigits(int(values[2]), 15))
            except ValueError:
                return "ERROR: incorrect syntax memory/immediate ==/!="  
    elif ((instruction == "beq") or (instruction == "bne")):
        # ALL instructions with $rd, $rs, $rt
        values = registers.split(' ')
        if (len(values) != 3):
            return ("ERROR: incorrect length branch ==/!=")
        else:
            values[0] = values[0].replace("$", "")
            values[0] = values[0].replace(",", "")
            values[1] = values[1].replace("$", "")
            values[1] = values[1].replace(",", "")
            try:
                if ((int(values[0]) > 31) or (int(values[0]) < 0) or (int(values[1]) > 31) or (int(values[1]) < 0) or (int(values[2]) > 16383) or (int(values[2]) < -16384)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[0]), 5) + bindigits(int(values[1]), 5) + bindigits(int(values[2]), 15))
            except ValueError:
                return "ERROR: incorrect syntax branch ==/!=" 
    elif((instruction == "return") or (instruction == "blank")):
        return "0000000000000000000000000"
    else:
        return "ERROR: argument does not exist!"
 
def bindigits(n, bits):
    s = bin(n & int("1"*bits, 2))[2:]
    return ("{0:0>%s}" % (bits)).format(s)

instruction_dictionary = {
    "add": "1100000",    #signed addition
    "addu": "1100010",    #unsigned addition
    "sub": "1100100",     
    "subu": "1100110", 
    "and": "1101000", 
    "or": "1101010", 
    "xor": "1101100",
    "nor": "1101110", 
    "slt": "1110100", 
    "sltu": "1110110", 
    "sll": "1010000",     #left shift with shamt
    "srl": "1010010",     #right shift with shamt
    "sra": "1010110",     #arithmetic right shift with shamt
    "sllv": "1011000",     #left shift with register rs
    "srlv": "1011010",     #right shift with register rs
    "srav": "1011110",     #arithmetic right shift with register rs
    "mfhi": "1001000",     #mul/div
    "mflo": "1001010", 
    "mult": "1001100", 
    "div": "1001110", 
    "mthi": "1000100",     #output a
    "mtlo": "1000110", 
    "jr": "1000000",   #jump r-type 
    "jalr": "1000010", 
    "lb": "0100000",   #memory
    "lh": "0100010", 
    "lw": "0100110",  
    "lbu": "0101000", 
    "lhu": "0101010", 
    "sb": "0110000", 
    "sh": "0110010", 
    "sw": "0110110", 
    "addi": "0010000",    #immediate
    "addiu": "0010010", 
    "slti": "0010100", 
    "sltiu": "0010110", 
    "andi": "0011000", 
    "ori": "0011010", 
    "xori": "0011100", 
    "lui": "0011110", 
    "blez": "0001000",    #branch <=
    "bgtz": "0001010",    #branch <
    "bgez": "0001100",    #branch >=
    "bltz": "0001110",    #branch >
    "beq": "0000100",     #branch ==
    "bne": "0000110",     #branch !=
    "j": "0000010",    #jump
    "jal": "0000011",     #jump
    "blank": "0000000",
    "return": "0000001"
    #"return": return_function  #return jump
}

if __name__ == "__main__":
    main()