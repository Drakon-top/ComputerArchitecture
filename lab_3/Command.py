from convert import convert_to_10_in_list_byte
from math import pow

dictionary_register_risc5 = {
    0: "zero",
    1: "ra",
    2: "sp",
    3: "gp",
    4: "Tp",
    5: "t0",
    6: "t1",
    7: "t2",
    8: "s0", # fp?
    9: "s1",
    10: "a0",
    11: "a1",
    12: "a2",
    13: "a3",
    14: "a4",
    15: "a5",
    16: "a6",
    17: "a7",
    18: "s2",
    19: "s3",
    20: "s4",
    21: "s5",
    22: "s6",
    23: "s7",
    24: "s8",
    25: "s9",
    26: "s10",
    27: "s11",
    28: "t3",
    29: "t4",
    30: "t5",
    31: "t6"
}
dictionary_command_type = {
    "0110111": "U",
    "0010111": "U",
    "1101111": "J",
    "1100111": "I",
    "1100011": "B",
    "0000011": "I",
    "0100011": "S",
    "0010011": "I",
    "0110011": "R",
    "0001111": "F", # Fence?
    "1110011": "I",
}
dictionary_command_I = {
    ("1100111", "000"): "jalr",
    ("0000011", "000"): "lb",
    ("0000011", "001"): "lh",
    ("0000011", "010"): "lw",
    ("0000011", "100"): "lbu",
    ("0000011", "101"): "lhu",
    ("0010011", "000"): "addi",
    ("0010011", "010"): "slti",
    ("0010011", "011"): "sltiu",
    ("0010011", "100"): "xori",
    ("0010011", "110"): "ori",
    ("0010011", "111"): "andi",
    ("1110011", "000"): "ebreak",
    ("0010011", "001"): "slli",
    ("0010011", "101"): "srli",
}
dictionary_command_R = {
    ("0110011", "000", "0000000"): "add",
    ("0110011", "000", "0100000"): "sub",
    ("0110011", "001", "0000000"): "sll",
    ("0110011", "010", "0000000"): "slt",
    ("0110011", "011", "0000000"): "sltu",
    ("0110011", "100", "0000000"): "xor",
    ("0110011", "101", "0000000"): "srl",
    ("0110011", "101", "0100000"): "sra",
    ("0110011", "110", "0000000"): "or",
    ("0110011", "111", "0000000"): "and",
    ("0110011", "000", "0000001"): "mul",
    ("0110011", "001", "0000001"): "mulh",
    ("0110011", "010", "0000001"): "mulhsu",
    ("0110011", "011", "0000001"): "mulhu",
    ("0110011", "100", "0000001"): "div",
    ("0110011", "101", "0000001"): "divu",
    ("0110011", "110", "0000001"): "rem",
    ("0110011", "111", "0000001"): "remu"
}
dictionary_command_S = {
    ("0100011", "000"): "sb",
    ("0100011", "001"): "sh",
    ("0100011", "010"): "sw"
}
dictionary_command_B = {
    ("1100011", "000"): "beq",
    ("1100011", "001"): "bne",
    ("1100011", "100"): "blt",
    ("1100011", "101"): "bge",
    ("1100011", "110"): "bltu",
    ("1100011", "111"): "bgeu",
}
dictionary_command_U = {
    "0110111": "lui",
    "0010111": "auipc"
}
dictionary_command_J = {
    "1101111": "jal"
}


def number_dop(data):
    number = -int(data[0]) * int(pow(2, (len(data) - 1)))
    data = data[1::][::-1]
    for i in range(len(data)):
        number += int(data[i]) * int(pow(2, i))
    return number


class CommandTypeI:
    def __init__(self, addr, data):
        self.addr = addr
        self.value = int(data, 2)
        self.opcode = data[-7:]
        self.funct3 = data[-15:-12]
        self.name = dictionary_command_I[(self.opcode, self.funct3)]
        if self.name == "ebreak":
            if int(data[-32:-20], 2) == 0:
                self.name = "ecall"
        self.rd = dictionary_register_risc5[int(data[-12:-7], 2)]
        self.rs1 = dictionary_register_risc5[int(data[-20:-15], 2)]
        if self.name in ["srli", "slli"]:
            self.imm = int(data[-25:-20])
            if int(data[-32:-25]) != 0 and self.name == "slli":
                self.name = "srai"
        else:
            self.imm = number_dop(data[-32] * 21 + data[-31:-20])

    def __str__(self):
        text = ""
        if self.name in ["lh", "lw", "lbu", "lhu", "lb", "jalr"]:
            args = (self.addr, self.value, self.name, self.rd, self.imm, self.rs1)
            text = "   %05x:\t%08x\t%7s\t%s, %s(%s)" % args
        elif self.name in ["ebreak", "ecall"]:
            args = (self.addr, self.value, self.name)
            text = "   %05x:\t%08x\t%7s" % args
        else:
            args = (self.addr, self.value, self.name, self.rd, self.rs1, self.imm)
            text = "   %05x:\t%08x\t%7s\t%s, %s, %s" % args
        return text


class CommandTypeR:
    def __init__(self, addr, data):
        self.addr = addr
        self.value = int(data, 2)
        self.opcode = data[-7:]
        self.funct3 = data[-15:-12]
        self.funct7 = data[-32:-25]
        self.name = dictionary_command_R[(self.opcode, self.funct3, self.funct7)]
        self.rd = dictionary_register_risc5[int(data[-12:-7], 2)]
        self.rs1 = dictionary_register_risc5[int(data[-20:-15], 2)]
        self.rs2 = dictionary_register_risc5[int(data[-25:-20], 2)]

    def __str__(self):
        args = (self.addr, self.value, self.name, self.rd, self.rs1, self.rs2)
        text = "   %05x:\t%08x\t%7s\t%s, %s, %s" % args
        return text


class CommandTypeS:
    def __init__(self, addr, data):
        self.addr = addr
        self.value = int(data, 2)
        self.opcode = data[-7:]
        self.funct3 = data[-15:-12]
        self.name = dictionary_command_S[(self.opcode, self.funct3)]
        self.rs1 = dictionary_register_risc5[int(data[-20:-15], 2)]
        self.rs2 = dictionary_register_risc5[int(data[-25:-20], 2)]
        self.imm = number_dop(data[-32] * 21 + data[-31:-25] + data[-12:-7])

    def __str__(self):
        args = (self.addr, self.value, self.name, self.rs2, self.imm, self.rs1)
        text = "   %05x:\t%08x\t%7s\t%s, %s(%s)" % args
        return text


class CommandTypeB:
    def __init__(self, addr, data):
        self.addr = addr
        self.value = int(data, 2)
        self.opcode = data[-7:]
        self.funct3 = data[-15:-12]
        self.name = dictionary_command_B[(self.opcode, self.funct3)]
        self.rs1 = dictionary_register_risc5[int(data[-20:-15], 2)]
        self.rs2 = dictionary_register_risc5[int(data[-25:-20], 2)]
        self.imm = number_dop(data[-32] * 20 + data[-8] + data[-31:-25] + data[-12:-8] + "0")
        self.addr_url = self.imm + addr
        self.name_url = ""

    def __str__(self):
        args = (self.addr, self.value, self.name, self.rs1, self.rs2, self.addr_url, self.name_url)
        text = "   %05x:\t%08x\t%7s\t%s, %s, %x <%s>" % args
        return text

    def set_name_url(self, name):
        self.name_url = name


class CommandTypeU:
    def __init__(self, addr, data):
        self.addr = addr
        self.value = int(data, 2)
        self.opcode = data[-7:]
        self.rd = dictionary_register_risc5[int(data[-12:-7], 2)]
        self.name = dictionary_command_U[self.opcode]
        self.imm = number_dop(data[-32:-12])

    def __str__(self):
        args = (self.addr, self.value, self.name, self.rd, self.imm)
        text = "   %05x:\t%08x\t%7s\t%s, 0x%x" % args
        return text


class CommandTypeJ:
    def __init__(self, addr, data):
        self.addr = addr
        self.value = int(data, 2)
        self.opcode = data[-7:]
        self.rd = dictionary_register_risc5[int(data[-12:-7], 2)]
        self.name = dictionary_command_J[self.opcode]
        self.imm = number_dop(data[-32] * 12 + data[-20:-12] + data[-20] + data[-31:-25] + data[-25:-21] + "0")
        self.addr_url = addr + self.imm
        self.name_url = ""

    def __str__(self):
        args = (self.addr, self.value, self.name, self.rd, self.imm, self.name_url)
        text = "   %05x:\t%08x\t%7s\t%s, %s <%s>" % args
        return text

    def set_name_url(self, name_url):
        self.name_url = name_url

