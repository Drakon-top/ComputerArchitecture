module CPU #(
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
)

(
    output wire [ADDR1_BUS_SIZE - 1:0] A1,
    inout wire [DATA1_BUS_SIZE - 1:0] D1,
    inout wire [CTR1_BUS_SIZE - 1:0] C1,

    input clk,
    input reset
);
    reg[ADDR1_BUS_SIZE - 1:0] _A1;
    reg[DATA1_BUS_SIZE - 1:0] _D1;
    reg[CTR1_BUS_SIZE - 1:0] _C1;

    reg[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:0] test;
    reg[CACHE_OFFSET_SIZE - 1:0] test2;
    reg[31:0] now;
    reg[7:0] dtest;
    reg[15:0] dtest16;
    integer j = 0;

    assign A1 = _A1;
    assign D1 = _D1;
    assign C1 = _C1;
   
    // const
    reg[6:0] M = 64;
    reg[5:0] N = 60;
    reg[5:0] K = 32;
    // адреса массивов
    reg[CACHE_ADDR_SIZE - 1:0] addr_a = 0;
    reg[CACHE_ADDR_SIZE - 1:0] addr_b;
    reg[CACHE_ADDR_SIZE - 1:0] addr_c;

    reg[CACHE_ADDR_SIZE - 1:0] addr_b_now;

    int y = 0;
    int k = 0;
    int x = 0;
    int s;
    
    reg[7:0] pa;
    reg[15:0] pb;
    reg[31:0] pc;

    reg[7:0] testnew;

    initial begin
        _C1 = 'bz;
        _D1 = 'bz;
        _A1 = 'bz;

        #10
        mmul();
    end

    task read_8(input reg[CACHE_ADDR_SIZE - 1:0] addr, output reg[7:0] data);
        _C1 = 1;
        _A1 = addr[CACHE_ADDR_SIZE - CACHE_OFFSET_SIZE - 1:CACHE_OFFSET_SIZE]; // tag+set
        wait_cnt(1);
        _A1 = addr[CACHE_OFFSET_SIZE - 1:0]; // offset
        wait_cnt(1);
        _C1 = 'bz;
        wait(C1 === 7);
        data = D1[15:8];
        wait_cnt(1);
    endtask

    task read_16(input reg[CACHE_ADDR_SIZE - 1:0] addr, output reg[15:0] data);
        _C1 = 2;
        _A1 = addr[CACHE_ADDR_SIZE - CACHE_OFFSET_SIZE - 1:CACHE_OFFSET_SIZE]; // tag+set
        wait_cnt(1);
        _A1 = addr[CACHE_OFFSET_SIZE - 1:0]; // offset
        wait_cnt(1);
        _C1 = 'bz;
        wait(C1 === 7);
        data[7:0] = D1[15:8];
        data[15:8] = D1[7:0];
        //$display("Data rez %d", data);
        wait_cnt(1);
    endtask

    task read_32(input reg[CACHE_ADDR_SIZE - 1:0] addr, output reg[31:0] data);
        _C1 = 3;
        _A1 = addr[CACHE_ADDR_SIZE - CACHE_OFFSET_SIZE - 1:CACHE_OFFSET_SIZE]; // tag+set
        wait_cnt(1);
        _A1 = addr[CACHE_OFFSET_SIZE - 1:0]; // offset
        wait_cnt(1);
        _C1 = 'bz;
        wait(C1 === 7);
        data[7:0] = D1[15:8];
        data[15:8] = D1[7:0];
        wait_cnt(1);
        data[23:16] = D1[15:8];
        data[31:24] = D1[7:0];
        wait_cnt(1);
    endtask

    task invalidate_line(input reg[CACHE_ADDR_SIZE - 1:0] addr);
        _C1 = 4;
        _A1 = addr[CACHE_ADDR_SIZE - CACHE_OFFSET_SIZE - 1:CACHE_OFFSET_SIZE]; // tag+set
        wait_cnt(1);
        _A1 = addr[CACHE_OFFSET_SIZE - 1:0]; // offset
        wait_cnt(1);
        _C1 = 'bz;
        wait(C1 == 7);
        wait_cnt(1);
    endtask

    task write_8(input reg[CACHE_ADDR_SIZE - 1:0] addr, input reg[7:0] data);
        _C1 = 5;
        _A1 = addr[CACHE_ADDR_SIZE - CACHE_OFFSET_SIZE - 1:CACHE_OFFSET_SIZE]; // tag+set
        _D1[15:8] = data;
        wait_cnt(1);
        _A1 = addr[CACHE_OFFSET_SIZE - 1:0]; // offset
        wait_cnt(1);
        _C1 = 'bz;
        _D1 = 'bz;
        wait(C1 == 7);
        wait_cnt(1);
    endtask

    task write_16(input reg[CACHE_ADDR_SIZE - 1:0] addr, input reg[15:0] data);
        _C1 = 6;
        _A1 = addr[CACHE_ADDR_SIZE - CACHE_OFFSET_SIZE - 1:CACHE_OFFSET_SIZE]; // tag+set
        _D1[15:8] = data[7:0];
        _D1[7:0] = data[15:8];
        wait_cnt(1);
        _A1 = addr[CACHE_OFFSET_SIZE - 1:0]; // offset
        wait_cnt(1);
        _C1 = 'bz;
        _D1 = 'bz;
        wait(C1 == 7);
        wait_cnt(1);
    endtask

    task write_32(input reg[CACHE_ADDR_SIZE - 1:0] addr, input reg[31:0] data);
        _C1 = 7;
        _A1 = addr[CACHE_ADDR_SIZE - CACHE_OFFSET_SIZE - 1:CACHE_OFFSET_SIZE]; // tag+set
        _D1[15:8] = data[7:0];
        _D1[7:0] = data[15:8];
        wait_cnt(1);
        _A1 = addr[CACHE_OFFSET_SIZE - 1:0]; // offset
        _D1[15:8] = data[23:16];
        _D1[7:0] = data[31:24];
        wait_cnt(1);
        _C1 = 'bz;
        _D1 = 'bz;
        wait(C1 == 7);
        wait_cnt(1);
    endtask
    
    task wait_cnt(int cnt);
        for (j = 0; j < cnt; j += 1) begin
            @(posedge clk);
        end
    endtask


    task mmul;
        addr_a = 0;
        addr_b = M * K;
        addr_c = addr_b + K * N * 2; // b[x] - 2 bytes
        $display("Start - %t", $time);
        for (y = 0; y < M; y += 1) begin
            for (x = 0; x < N; x+=1) begin 
                addr_b_now = addr_b;
                s = 0;
                wait_cnt(1);
                for (k = 0; k < K; k+=1) begin
                    read_8(addr_a + k, pa);
                    read_16(addr_b_now + x * 2, pb);
                    s += pa * pb;
                    wait_cnt(5 + 1); // * - 5, + - 1;
                    addr_b_now += 2 * N;
                    wait_cnt(1);
                end
                write_32(addr_c + x * 4, s);
                wait_cnt(1);
            end
            addr_a += K;
            wait_cnt(1);
            addr_c += N * 4;
            wait_cnt(1);

            wait_cnt(1);
        end
        wait_cnt(1);
        $display("End - %t", $time);
        //$finish;
    endtask

endmodule