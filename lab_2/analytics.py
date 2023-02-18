MEM_SIZE = 2 ** 20  # байт
CACHE_SIZE = 2 ** 10  # байт
CACHE_LINE_SIZE = 2 ** 5 # байт
CACHE_LINE_COUNT = 2 ** 5
CACHE_WAY = 2
CACHE_SETS_COUNT = 16
CACHE_TAG_SIZE = 11
CACHE_SET_SIZE = 4
CACHE_OFFSET_SIZE = 5
CACHE_ADDR_SIZE = 20


cache = []
Hits = 0
Miss = 0
all_cnt = 0
for i in range(CACHE_LINE_SIZE):
    cache.append("0" * (CACHE_TAG_SIZE + 3))


def read(adr):
    global Count
    bin_adr = bin(adr)[2:]
    bin_adr = (20 - len(bin_adr)) * "0" + bin_adr
    tag, _set = bin_adr[:CACHE_TAG_SIZE], bin_adr[CACHE_TAG_SIZE:CACHE_TAG_SIZE + CACHE_SET_SIZE]
    ind = search(tag, _set)
    Count += 2


def write(adr):
    global Count, cache
    bin_adr = bin(adr)[2:]
    bin_adr = (20 - len(bin_adr)) * "0" + bin_adr
    tag, _set = bin_adr[:CACHE_TAG_SIZE], bin_adr[CACHE_TAG_SIZE:CACHE_TAG_SIZE + CACHE_SET_SIZE]
    num = int(_set, 2) * CACHE_WAY
    ind = search(tag, _set)
    new = list(cache[num + ind])
    new[CACHE_TAG_SIZE + 1] = "1"
    cache[num + ind] = "".join(new)
    Count += 2


def search(tag, _set):
    global Count, cache, all_cnt, Hits, Miss
    num = int(_set, 2) * CACHE_WAY
    line1 = cache[num]
    line2 = cache[num + 1]
    index = 0
    all_cnt += 1
    if line1[:CACHE_TAG_SIZE] == tag and line1[CACHE_TAG_SIZE] == "1":
        index = 0
        Count += 6
        Hits += 1
    elif line2[:CACHE_TAG_SIZE] == tag and line2[CACHE_TAG_SIZE] == "1":
        index = 1
        Count += 6
        Hits += 1
    else:
        Miss += 1
        Count += 4
        if line1[-1] == "1":
            index = 1
        else:
            index = 0

        if cache[num + index][CACHE_TAG_SIZE] == "1" and cache[num + index][CACHE_TAG_SIZE + 1] == "1":
            # write
            Count += 108
        # read
        Count += 108
        new = tag + "1" + "0" + "1"
        cache[num + index] = new
    if index == 0:
        new = list(cache[num + 1])
        new[-1] = "0"
        cache[num + 1] = "".join(new)
    else:
        new = list(cache[num])
        new[-1] = "0"
        cache[num] = "".join(new)
    return index


M = 64
N = 60
K = 32
Count = 0
a = 0
b = M * K
c = b + K * N * 2
pa = a
pc = c
for y in range(M):
    for x in range(N):
        pb = b
        s = 0
        Count += 2  # initial pb and s
        for k in range(K):
            #s += read(pa + K) * read(pb + x * 2)
            read(pa + K)
            read(pb + x * 2)
            pb += N * 2
            Count += 5
        write(pc + 4 * x)
        Count += 1
    pa += K
    pc += 4 * N
    Count += 3
Count += 1
print("Tact -", Count)
print("Cnt -", all_cnt)
print("% -", Hits / all_cnt)
print("miss -", Miss)
