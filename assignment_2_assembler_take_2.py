# Assembler ELEC3720
# Joshua Beverley & Radhika Feron

def main():
    print ("hello world")
    machine = open("C:\\ELEC4700\\machine_code.txt", "r")
    output = open("C:\\ELEC4700\\machine_output.txt", "w")
    contents = machine.readlines()
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
                if ((int(values[0]) > 15) or (int(values[0]) < 0) or (int(values[1]) > 15) or (int(values[1]) < 0) or (int(values[2]) > 15) or (int(values[2]) < 0)):
                    return "ERROR: register number entered out of range"
                return str(bindigits(int(values[1]), 4) + bindigits(int(values[2]), 4) + bindigits(int(values[0]), 4))
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
                if ((int(values[0]) > 15) or (int(values[0]) < 0) or (int(values[1]) > 15) or (int(values[1]) < 0) or (int(values[2]) > 15) or (int(values[2]) < 0)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[2]), 4) + bindigits(int(values[1]), 4) + bindigits(int(values[0]), 4))
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
                if ((int(values[0]) > 15) or (int(values[0]) < 0) or (int(values[1]) > 15) or (int(values[1]) < 0) or (int(values[2]) > 15) or (int(values[2]) < 0)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[2]), 4) + bindigits(int(values[1]), 4) + bindigits(int(values[0]), 4))
            except ValueError:
                return "ERROR: incorrect syntax shifter with shamt"
    elif ((instruction == "mfhi") or (instruction == "mflo")):
        # ALL instructions with $rd, output 8'b0 + $rd
        if " " in registers:
            return ("ERROR: incorrect length MUL/DIV")
        else:
            values = registers.replace("$", "")
            try: 
                if ((int(values) > 15) or (int(values) < 0)):
                    return "ERROR: register number entered out of range" 
                return str("00000000" + bindigits(int(values), 4))
            except ValueError:
                return "ERROR: incorrect syntax MUL/DIV"
    elif ((instruction == "mthi") or (instruction == "mtlo") or (instruction == "jr") or (instruction == "jalr")):
        # ALL instructions with $rs, $rs + output 8'b0
        if " " in registers:
            return ("ERROR: incorrect length MUL/DIV/R-type jump")
        else:
            values = registers.replace("$", "")
            try:
                if ((int(values) > 15) or (int(values) < 0)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values), 4) + "00000000")
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
                if ((int(values[0]) > 15) or (int(values[0]) < 0) or (int(values[1]) > 15) or (int(values[1]) < 0)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[0]), 4) + bindigits(int(values[1]), 4) + "0000")
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
                if ((int(values[0]) > 15) or (int(values[0]) < 0) or (int(values[1]) > 127) or (int(values[1]) < -128)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[0]), 4) + bindigits(int(values[1]), 8))
            except ValueError:
                return "ERROR: incorrect syntax branch <>"
    elif ((instruction == "j") or (instruction == "jal")):
        # ALL instructions with constant in instruction [0:11]
        if (instruction == "jal" and registers == "jta"):
            return "0100000000000"
        else:
            addition = "1"
            if (instruction == "j"):
                addition = "10"
            elif (instruction == "jal"):
                addition = "11"
            if " " in registers:
                return ("ERROR: incorrect length jump")
            else:
                try:
                    if ((int(registers) > 2047) or (int(registers) < 0)):
                        return "ERROR: register number entered out of range" 
                    return str(addition + str(bindigits(int(registers), 11)))
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
                if ((int(values[0]) > 15) or (int(values[0]) < 0) or (int(values[1]) > 15) or (int(values[1]) < 0) or (int(values[2]) > 15) or (int(values[2]) < 0)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[1]), 4) + bindigits(int(values[0]), 4) + bindigits(int(values[2]), 4))
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
                if ((int(values[0]) > 15) or (int(values[0]) < 0) or (int(values[1]) > 15) or (int(values[1]) < 0) or (int(values[2]) > 7) or (int(values[2]) < -8)):
                    return "ERROR: register number entered out of range (negatives)" 
                return str(bindigits(int(values[1]), 4) + bindigits(int(values[0]), 4) + bindigits(int(values[2]), 4))
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
                if ((int(values[0]) > 15) or (int(values[0]) < 0) or (int(values[1]) > 15) or (int(values[1]) < 0) or (int(values[2]) > 7) or (int(values[2]) < -8)):
                    return "ERROR: register number entered out of range" 
                return str(bindigits(int(values[0]), 4) + bindigits(int(values[1]), 4) + bindigits(int(values[2]), 4))
            except ValueError:
                return "ERROR: incorrect syntax branch ==/!=" 
    elif(instruction == "blank"):
        return "000000000000"
    else:
        return "ERROR: argument does not exist!"
 
def bindigits(n, bits):
    s = bin(n & int("1"*bits, 2))[2:]
    return ("{0:0>%s}" % (bits)).format(s)

instruction_dictionary = {
    "add": "110000",    #signed addition
    "addu": "110001",    #unsigned addition
    "sub": "110010",     
    "subu": "110011", 
    "and": "110100", 
    "or": "110101", 
    "xor": "110110",
    "nor": "110111", 
    "slt": "111010", 
    "sltu": "111011", 
    "sll": "101000",     #left shift with shamt
    "srl": "101001",     #right shift with shamt
    "sra": "101011",     #arithmetic right shift with shamt
    "sllv": "101100",     #left shift with register rs
    "srlv": "101101",     #right shift with register rs
    "srav": "101111",     #arithmetic right shift with register rs
    "mfhi": "100100",     #mul/div
    "mflo": "100101", 
    "mult": "100110", 
    "div": "100111", 
    "mthi": "100010",     #output a
    "mtlo": "100011", 
    "jr": "100000",   #jump r-type
    "jalr": "100001", 
    "lb": "010000",   #memory
    "lh": "010001", 
    "lw": "010011",  
    "lbu": "010100", 
    "lhu": "010101", 
    "sb": "011000", 
    "sh": "011001", 
    "sw": "011011", 
    "addi": "001000",    #immediate
    "addiu": "001001", 
    "slti": "001010", 
    "sltiu": "001011", 
    "andi": "001100", 
    "ori": "001101", 
    "xori": "001110", 
    "lui": "001111", 
    "blez": "000100",    #branch <=
    "bgtz": "000101",    #branch <
    "bgez": "000110",    #branch >=
    "bltz": "000111",    #branch >
    "beq": "000010",     #branch ==
    "bne": "000011",     #branch !=
    "j": "00000",    #jump
    "jal": "00000",     #jump
    "blank": "000000"
    #"return": return_function  #return jump
}

if __name__ == "__main__":
    main()