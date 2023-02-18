`include "CPU.sv"
`include "Cache.sv"
`include "MemCTR.sv"

module testbench # (
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
    parameter CTR2_BUS_SIZE = 2
);
    reg clk = 1;

    wire[ADDR1_BUS_SIZE - 1:0] A1;
    wire[DATA1_BUS_SIZE - 1:0] D1;
    wire[CTR1_BUS_SIZE - 1:0] C1;
    
    wire[ADDR2_BUS_SIZE - 1:0] A2;
    wire[DATA2_BUS_SIZE - 1:0] D2;
    wire[CTR2_BUS_SIZE - 1:0] C2;

    wire reset = 0;
    wire C_DUMP = 0;
    wire M_DUMP = 0;

    reg _c_dump;
    reg _m_dump;

    assign C_DUMP = _c_dump;
    assign M_DUMP = _m_dump;

    CPU _cpu(
        .A1(A1),
        .D1(D1),
        .C1(C1),
        .clk(clk),
        .reset(reset)
        );

    Cache _cache (
        .A2(A2),
        .D1(D1),
        .C1(C1),
        .D2(D2),
        .C2(C2),
        .A1(A1),
        .clk(clk),
        .reset(reset),
        .C_DUMP(C_DUMP)
    );

    MemCTR _memctr(
        .D2(D2),
        .C2(C2),
        .A2(A2),
        .clk(clk),
        .reset(reset),
        .M_DUMP(M_DUMP)
    );



    initial begin
        _c_dump = 'dz;
        #15394112
        _c_dump = 1;
        #10
        $finish;
    end
    
    always #1 begin
        clk = ~clk;
    end

endmodule