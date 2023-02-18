module MemCTR #(
    parameter MEM_SIZE = (1 << 20),
    parameter CACHE_SIZE = (1 << 10),
    parameter CACHE_LINE_SIZE = 32,
    parameter CACHE_LINE_COUNT = 32,
    parameter CACHE_WAY = 2,
    parameter CACHE_SETS_COUNT = 16,
    parameter CACHE_TAG_SIZE = 11,
    parameter CACHE_SET_SIZE = 4,
    parameter CACHE_OFFSET_SIZE = 5, 
    parameter CACHE_ADDR_SIZE = 20,
    parameter ADDR1_BUS_SIZE = 15,
    parameter ADDR2_BUS_SIZE = 15,
    parameter DATA1_BUS_SIZE = 16,
    parameter DATA2_BUS_SIZE = 16,
    parameter CTR1_BUS_SIZE = 3,
    parameter CTR2_BUS_SIZE = 2,
    parameter _SEED = 225526
)
(
    inout wire [DATA2_BUS_SIZE - 1:0] D2,
    inout wire [CTR2_BUS_SIZE - 1:0] C2,

    input wire [ADDR2_BUS_SIZE - 1:0] A2,
    input clk,
    input reset,
    input M_DUMP
);
    reg[ADDR2_BUS_SIZE - 1:0] _A2;
    reg[DATA2_BUS_SIZE - 1:0] _D2;
    reg[CTR2_BUS_SIZE - 1:0] _C2;

    assign D2 = _D2;
    assign C2 = _C2;

    // initial memory
    reg[CACHE_TAG_SIZE - 1:0] tag;
    reg[CACHE_SET_SIZE - 1:0] set;
    reg[7:0] line [0:CACHE_LINE_SIZE - 1];
    reg[CACHE_ADDR_SIZE:0] addr = 0;
    reg[CACHE_ADDR_SIZE:0] addrend = 0;
    integer i = 0;
    integer j = 0;
    integer m = 0;

    integer SEED = _SEED;
    reg[7:0] mem[0:MEM_SIZE - 1];
    initial begin    
        _D2 = 'bz;
        _C2 = 'bz;
        initila_memory();
        $display("Initial memory");
    end


    always @(posedge reset) begin
        initila_memory();
    end

    task initila_memory;
        for (i = 0; i < MEM_SIZE; i += 1) begin
            mem[i] = $random(SEED)>>16;  
        end
    endtask

    task wait_cnt(int cnt);
        for (j = 0; j < cnt; j += 1) begin
            @(posedge clk);
        end
    endtask


    always @(posedge clk) begin
        if (C2 === 2) begin
            tag = A2[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE];
            set = A2[CACHE_SET_SIZE - 1:0];
            wait_cnt(100); ///<100>
            _C2 = 1;
            addr[CACHE_ADDR_SIZE - 1:CACHE_OFFSET_SIZE] = A2;
            addr[CACHE_OFFSET_SIZE - 1:0] = (1 << CACHE_OFFSET_SIZE) - 1;
            for (i = 0; i < CACHE_LINE_SIZE; i+= 2) begin
                _D2[15:8] =  mem[addr - i];
                _D2[7:0] =  mem[addr - i - 1];
                wait_cnt(1);
            end
            _D2 = 'dz;
            _C2 = 'dz;     
        end

        else if (C2 === 3) begin
            tag = A2[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE];
            set = A2[CACHE_SET_SIZE - 1:0];
            addr[CACHE_ADDR_SIZE - 1:CACHE_OFFSET_SIZE] = A2;
            addr[CACHE_OFFSET_SIZE - 1:0] = (1 << CACHE_OFFSET_SIZE) - 1;
            for (i = 0; i < CACHE_LINE_SIZE; i+= 2) begin
                mem[addr - i] = D2[15:8];
                mem[addr - i - 1] = D2[7:0];
                wait_cnt(1);
            end
            wait_cnt(100); ///<100>
            _C2 = 1;
            wait_cnt(1);
            _C2 = 'dz;  
        end
    end

    always @(posedge M_DUMP) begin
        for (m = 0; m < MEM_SIZE; m+=1) begin
            $display("Mem %d - %b", m, mem[m]);
        end
    end


endmodule
