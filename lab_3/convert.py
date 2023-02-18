def convert_to_10_in_list_byte(_list, index, size):
    num = ""
    vector = _list[index: index + size][::-1]  # little endian
    for i in vector:
        now = hex(i)[2:]
        now = (2 - len(now)) * "0" + now
        num += now
    return int(num, 16)