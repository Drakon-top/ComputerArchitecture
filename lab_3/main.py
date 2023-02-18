import sys
from SymbolTableSection import SymbolTableSection
from convert import convert_to_10_in_list_byte
from Command import dictionary_command_type, CommandTypeI, CommandTypeR, CommandTypeS, CommandTypeB, CommandTypeU, CommandTypeJ


def search_index_text_symtab_strtab(_list, index_start_header, index_header_names, size_section_header=40):
    index_shstrndx_data = convert_to_10_in_list_byte(_list, index_header_names + 16, 4)
    symtab = 0
    strtab = 0
    text = 0
    i = 0
    while not symtab or not strtab or not text:
        name = ""
        index_now = index_shstrndx_data + convert_to_10_in_list_byte(_list, index_start_header + i * size_section_header, 4)
        while _list[index_now] != 0:
            name += chr(_list[index_now])
            index_now += 1
        if name == ".text":
            text = index_start_header + i * size_section_header
        elif name == ".symtab":
            symtab = index_start_header + i * size_section_header
        elif name == ".strtab":
            strtab = index_start_header + i * size_section_header
        i += 1
    return text, symtab, strtab


def disassembler(input, output):
    with open(input, 'rb') as file_input:
        _list = []
        lines = file_input.readlines()
        for i in lines:
            _list.extend(list(i))
        ELF = chr(_list[1]) + chr(_list[2]) + chr(_list[3])
        if ELF != "ELF":
            raise TypeError("Type Error")
        e_shoff = convert_to_10_in_list_byte(_list, 32, 4) # index start header
        e_shstrndx = 40 * convert_to_10_in_list_byte(_list, 50, 2) + e_shoff  # index header names
        size_section_header = 40
        index_text_header, index_symtab_header, index_strtab_header = search_index_text_symtab_strtab(_list, e_shoff, e_shstrndx, size_section_header)

        size_data_symtab = convert_to_10_in_list_byte(_list, index_symtab_header + 20, 4)
        index_data_symtab = convert_to_10_in_list_byte(_list, index_symtab_header + 16, 4)
        index_data_strtab = convert_to_10_in_list_byte(_list, index_strtab_header + 16, 4)

        dictionary_index_mark = {}
        list_item_symtab = []
        for i in range(size_data_symtab // 16):
            list_item_symtab.append(SymbolTableSection(_list[index_data_symtab + i * 16:index_data_symtab + (i + 1) * 16]))
        symtab_out = ["Symbol Value              Size Type 	Bind 	 Vis   	   Index Name\n"]
        for i in range(size_data_symtab // 16):
            now = list_item_symtab[i]
            index_name = index_data_strtab + now.get_name()
            name = ""
            while _list[index_name] != 0:
                name += chr(_list[index_name])
                index_name += 1
            symtab_out.append("[%4i] 0x%-15X %5i %-8s %-8s %-8s %6s %s\n" % (
                   i, now.get_value(), now.get_size(), now.get_type(), now.get_bind(), now.get_vis(), now.get_index(), name))
            if now.get_type() == "FUNC":
                dictionary_index_mark[now.get_value()] = name

        # text
        virtual_addr_text = convert_to_10_in_list_byte(_list, index_text_header + 12, 4)
        index_data_text = convert_to_10_in_list_byte(_list, index_text_header + 16, 4)
        size_data_text = convert_to_10_in_list_byte(_list, index_text_header + 20, 4)
        count_url = 0
        list_commands = []
        for i in range(size_data_text // 4):
            command_bin = bin(convert_to_10_in_list_byte(_list, index_data_text + i * 4, 4))[2:]
            command_bin = (32 - len(command_bin)) * "0" + command_bin
            opcode = command_bin[-7:]
            type_command = dictionary_command_type[opcode]
            try:
                if type_command == "R":
                    command = CommandTypeR(virtual_addr_text + i * 4, command_bin)
                elif type_command == "I":
                    command = CommandTypeI(virtual_addr_text + i * 4, command_bin)
                elif type_command == "S":
                    command = CommandTypeS(virtual_addr_text + i * 4, command_bin)
                elif type_command == "B":
                    command = CommandTypeB(virtual_addr_text + i * 4, command_bin)
                    if command.addr_url not in dictionary_index_mark:
                        dictionary_index_mark[command.addr_url] = "L" + str(count_url)
                        count_url += 1
                    command.set_name_url(dictionary_index_mark[command.addr_url])
                elif type_command == "U":
                    command = CommandTypeU(virtual_addr_text + i * 4, command_bin)
                elif type_command == "J":
                    command = CommandTypeJ(virtual_addr_text + i * 4, command_bin)
                    if command.addr_url not in dictionary_index_mark:
                        dictionary_index_mark[command.addr_url] = "L" + str(count_url)
                        count_url += 1
                    command.set_name_url(dictionary_index_mark[command.addr_url])
                else:
                    command = "unknown_instruction"
            except:
                command = "unknown_instruction"
            list_commands.append(command)

        with open(output, "w") as file_output:
            file_output.write(".text\n")
            for i in range(size_data_text // 4):
                if virtual_addr_text + i * 4 in dictionary_index_mark:
                    file_output.write("\n")
                    file_output.write("%08x   <%s>:\n" % (virtual_addr_text + i * 4, dictionary_index_mark[virtual_addr_text + i * 4]))
                file_output.write(list_commands[i].__str__() + "\n")
            file_output.write("\n")
            file_output.write(".symtab\n")
            for i in symtab_out:
                file_output.write(i)


if __name__ == "__main__":
    if len(sys.argv) == 3:
        try:
            disassembler(sys.argv[1], sys.argv[2])
            print("Complete!")
        except TypeError as error:
            print("Error, does not match the ELF file ", error)
        except Exception as error:
            print("Error", error)
    else:
        print("Error! Expect 2 argument, actual: ", len(sys.argv) - 1)
