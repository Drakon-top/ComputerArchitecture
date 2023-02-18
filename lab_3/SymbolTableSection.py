from convert import convert_to_10_in_list_byte

dictionary_type_symtab = {
    0: "NOTYPE",
    1: "OBJECT",
    2: "FUNC",
    3: "SECTION",
    4: "FILE",
    5: "COMMON",
    6: "TLS",
    10: "LOOS",
    12: "HIOS",
    13: "LOPROC",
    14: "SPARC_REGISTER",
    15: "HIPROC"
}
dictionary_bind_symtab = {
    0: "LOCAL",
    1: "GLOBAL",
    2: "WEAK",
    10: "LOOS",
    12: "HIOS",
    13: "LOPROC",
    15: "HIPROC"
}
dictionary_vis_symtab = {
    0: "DEFAULT",
    1: "INTERNAL",
    2: "HIDDEN",
    3: "PROTECTED",
    4: "EXPORTED",
    5: "SINGLETON",
    6: "ELIMINATE"
}
dictionary_index_symtab = {
    0: "UNDEF",
    0xff00: "LOPROC",
    0xff1f: "HIPROC",
    0xfff1: "ABS",
    0xfff2: "COMMON",
    0xffff: "HIRESERVE"
}


class SymbolTableSection:
    def __init__(self, data):
        self.name = convert_to_10_in_list_byte(data, 0, 4)
        self.value = convert_to_10_in_list_byte(data, 4, 4)
        self.size = convert_to_10_in_list_byte(data, 8, 4)
        self.info = convert_to_10_in_list_byte(data, 12, 1)
        self.other = convert_to_10_in_list_byte(data, 13, 1)
        self.shndx = convert_to_10_in_list_byte(data, 14, 2)
        self.type = self.info & 15
        self.bind = self.info >> 4
        self.vis = self.other & 3

    def get_value(self):
        return self.value

    def get_size(self):
        return self.size

    def get_type(self):
        return dictionary_type_symtab[self.type]

    def get_bind(self):
        return dictionary_bind_symtab[self.bind]

    def get_index(self):
        return dictionary_index_symtab[self.shndx] if self.shndx in dictionary_index_symtab else self.shndx

    def get_vis(self):
        return dictionary_vis_symtab[self.vis]

    def get_name(self):
        return self.name

