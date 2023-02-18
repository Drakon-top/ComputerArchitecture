module Cache #(
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
    output wire [ADDR2_BUS_SIZE - 1:0] A2,
    inout wire [DATA1_BUS_SIZE - 1:0] D1,
    inout wire [CTR1_BUS_SIZE - 1:0] C1,
    inout wire [DATA2_BUS_SIZE - 1:0] D2,
    inout wire [CTR2_BUS_SIZE - 1:0] C2,

    input wire [ADDR1_BUS_SIZE - 1:0] A1,
    input clk,
    input reset,
    input C_DUMP
    
);

    reg[ADDR2_BUS_SIZE - 1:0] _A2;
    reg[DATA2_BUS_SIZE - 1:0] _D2;
    reg[CTR2_BUS_SIZE - 1:0] _C2;
    
    reg[ADDR1_BUS_SIZE - 1:0] _A1;
    reg[DATA1_BUS_SIZE - 1:0] _D1;
    reg[CTR1_BUS_SIZE - 1:0] _C1;

    reg[7:0] cache_data[0:CACHE_LINE_COUNT - 1] [0:CACHE_LINE_SIZE - 1];
    reg[CACHE_TAG_SIZE + 3 - 1:0] cache_info[0:CACHE_LINE_COUNT - 1]; // valid 1 dirty 1 tag 11 lru 1

    assign D1 = _D1;
    assign C1 = _C1;
    assign A2 = _A2;
    assign D2 = _D2;
    assign C2 = _C2;
    


    reg[7:0] line[0:CACHE_LINE_SIZE - 1];
    integer iter = 0;
    integer j = 0;
    integer i = 0;
    integer dm = 0;
    integer bt = 0;
    integer cl = 0;

    reg[CACHE_TAG_SIZE - 1:0] tag;
    reg[CACHE_SET_SIZE - 1:0] set;
    reg[CACHE_OFFSET_SIZE - 1:0] offset;

    reg[7:0] line1[0:CACHE_LINE_SIZE - 1];
    reg[7:0] line2[0:CACHE_LINE_SIZE - 1];
    reg[CACHE_TAG_SIZE + 3 - 1:0] line_info1;
    reg[CACHE_TAG_SIZE + 3 - 1:0] line_info2;
    reg[7:0] data8;
    reg[15:0] data16;
    reg[31:0] data32;

    reg index = 0;
    int count = 0;
    int miss = 0;
    int hits = 0;

    initial begin
        _D1 = 'bz;
        _C1 = 'bz;
        _A2 = 'bz;
        _D2 = 'bz;
        _C2 = 'bz;
        
        // for (iter = 0; iter < CACHE_LINE_COUNT; iter += 1) begin
        //     for (i = 0; i < CACHE_LINE_SIZE; i += 1) begin
        //         cache_data[iter][i] = 0;
        //     end
        // end

        // for (iter = 0; iter < CACHE_LINE_COUNT; iter += 1) begin 
        //     cache_info[iter] = 0;
        // end
        reser_cache();
    end

    task wait_cnt(int cnt);
        for (j = 0; j < cnt; j += 1) begin
            @(posedge clk);
        end
    endtask


    always @(posedge clk) begin
        if (C1 == 1) begin
            tag = A1[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE];
            set = A1[CACHE_SET_SIZE - 1:0];
            wait_cnt(1);
            offset = A1[CACHE_OFFSET_SIZE - 1:0];
            wait_cnt(1);
            search_cache_line(tag, set, index);
            _C1 = 7;
            _D1[15:8] = cache_data[set * CACHE_WAY + index][offset];
            wait_cnt(1);
            _C1 = 'dz;
            _D1 = 'dz;
        end

        else if (C1 == 2) begin
            tag = A1[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE];
            set = A1[CACHE_SET_SIZE - 1:0];
            wait_cnt(1);
            offset = A1[CACHE_OFFSET_SIZE - 1:0];
            wait_cnt(1);
            search_cache_line(tag, set, index);
            _C1 = 7;
            _D1[15:8] = cache_data[set * CACHE_WAY + index][offset];
            _D1[7:0] = cache_data[set * CACHE_WAY + index][offset + 1];
            wait_cnt(1);
            _C1 = 'dz;
            _D1 = 'dz;
        end     

        else if (C1 == 3) begin
            tag = A1[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE];
            set = A1[CACHE_SET_SIZE - 1:0];
            wait_cnt(1);
            offset = A1[CACHE_OFFSET_SIZE - 1:0];
            wait_cnt(1);
            search_cache_line(tag, set, index);
            _C1 = 7;
            _D1[15:8] = cache_data[set * CACHE_WAY + index][offset];
            _D1[7:0] = cache_data[set * CACHE_WAY + index][offset + 1];
            wait_cnt(1);
            _D1[15:8] = cache_data[set * CACHE_WAY + index][offset + 2];
            _D1[7:0] = cache_data[set * CACHE_WAY + index][offset + 3];
            wait_cnt(1);
            _C1 = 'dz;
            _D1 = 'dz;
        end   

        else if (C1 == 4) begin
            tag = A1[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE];
            set = A1[CACHE_SET_SIZE - 1:0];
            wait_cnt(1);
            offset = A1[CACHE_OFFSET_SIZE - 1:0];
            wait_cnt(1);
            invalid_cache_line(tag, set);
            _C1 = 7;
            wait_cnt(1);
            _C1 = 'dz;
        end

        else if (C1 == 5) begin
            tag = A1[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE];
            set = A1[CACHE_SET_SIZE - 1:0];
            data8[7:0] = D1[15:8];
            wait_cnt(1);
            offset = A1[CACHE_OFFSET_SIZE - 1:0];
            wait_cnt(1);
            search_cache_line(tag, set, index);
            cache_info[set * CACHE_WAY + index][CACHE_TAG_SIZE + 2 - 1] = 1;
            cache_data[set * CACHE_WAY + index][offset] = data8;
            _C1 = 7;
            wait_cnt(1);
            _C1 = 'dz;
        end

        else if (C1 == 6) begin
            tag = A1[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE];
            set = A1[CACHE_SET_SIZE - 1:0];
            data16[7:0] = D1[15:8];
            data16[15:8] = D1[7:0];
            wait_cnt(1);
            offset = A1[CACHE_OFFSET_SIZE - 1:0];
            wait_cnt(1);
            search_cache_line(tag, set, index);
            cache_info[set * CACHE_WAY + index][CACHE_TAG_SIZE + 2 - 1] = 1;
            cache_data[set * CACHE_WAY + index][offset] = data16[7:0];
            cache_data[set * CACHE_WAY + index][offset + 1] = data16[15:8];
            _C1 = 7;
            wait_cnt(1);
            _C1 = 'dz;
        end

        else if (C1 == 7) begin
            tag = A1[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE];
            set = A1[CACHE_SET_SIZE - 1:0];
            data32[7:0] = D1[15:8];
            data32[15:8] = D1[7:0];
            wait_cnt(1);
            offset = A1[CACHE_OFFSET_SIZE - 1:0];
            data32[23:16] = D1[15:8];
            data32[31:24] = D1[7:0];
            wait_cnt(1);
            search_cache_line(tag, set, index);
            cache_info[set * CACHE_WAY + index][CACHE_TAG_SIZE + 2 - 1] = 1;
            cache_data[set * CACHE_WAY + index][offset] = data32[7:0];
            cache_data[set * CACHE_WAY + index][offset + 1] = data32[15:8];
            cache_data[set * CACHE_WAY + index][offset + 2] = data32[23:16];
            cache_data[set * CACHE_WAY + index][offset + 3] = data32[31:24];
            _C1 = 7;
            wait_cnt(1);
            _C1 = 'dz;
        end
    end

    task search_cache_line(input reg[CACHE_TAG_SIZE - 1:0] _tag, input reg[CACHE_SET_SIZE - 1:0] _set, output reg index);
        line_info1 = cache_info[_set * CACHE_WAY];
        line_info2 = cache_info[_set * CACHE_WAY + 1];
        count += 1;
        if (line_info1[CACHE_TAG_SIZE + 3 - 1] == 1 && line_info1[CACHE_TAG_SIZE:1] == _tag) begin
            wait_cnt(5); // add 6
            hits += 1;
            index = 0;
        end 
        else if (line_info2[CACHE_TAG_SIZE + 3 - 1] == 1 && line_info2[CACHE_TAG_SIZE:1] == _tag) begin
            wait_cnt(5); // add 6
            index = 1;
            hits += 1;
        end 
        else begin
            miss += 1;
            wait_cnt(3);
            // read mem
            if (line_info2[0] == 1) begin
                index = 0;
            end else begin
                index = 1;
            end
            
            if (cache_info[_set * CACHE_WAY + index][CACHE_TAG_SIZE + 3 - 1] == 1 
                && cache_info[_set * CACHE_WAY + index][CACHE_TAG_SIZE + 2 - 1] == 1) begin
                write_line_in_mem(cache_info[_set * CACHE_WAY + index][CACHE_TAG_SIZE:1], _set, index);
            end
    
            wait_cnt(1);
            read_line_in_mem(_tag, _set, index);
            cache_info[_set * CACHE_WAY + index][CACHE_TAG_SIZE + 3 - 1] = 1;
            cache_info[_set * CACHE_WAY + index][CACHE_TAG_SIZE + 2 - 1] = 0;
            cache_info[_set * CACHE_WAY + index][CACHE_TAG_SIZE:1] = _tag;
        end 
        if (index == 0) begin
            cache_info[_set * CACHE_WAY][0] = 1;
            cache_info[_set * CACHE_WAY + 1][0] = 0;
        end else begin
            cache_info[_set * CACHE_WAY][0] = 0;
            cache_info[_set * CACHE_WAY + 1][0] = 1;
        end

    endtask

    task read_line_in_mem(input reg[CACHE_TAG_SIZE - 1:0] _tag, input reg[CACHE_SET_SIZE - 1:0] _set, input reg index);
        _C2 = 2;
        _A2[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE] = _tag;
        _A2[CACHE_SET_SIZE - 1:0] = _set;
        wait_cnt(1);
        _C2 = 'dz;
        wait(C2 == 1);
        for (iter = 0; iter < CACHE_LINE_SIZE - 1; iter += 2) begin
            cache_data[_set * CACHE_WAY + index][CACHE_LINE_SIZE - iter - 1] = D2[15:8];
            cache_data[_set * CACHE_WAY + index][CACHE_LINE_SIZE - iter - 2] = D2[7:0];
            wait_cnt(1);
        end
    endtask

    task write_line_in_mem(input reg[CACHE_TAG_SIZE - 1:0] _tag, input reg[CACHE_SET_SIZE - 1:0] _set, input reg index);
        _C2 = 3;
        _A2[CACHE_TAG_SIZE + CACHE_SET_SIZE - 1:CACHE_SET_SIZE] = _tag;
        _A2[CACHE_SET_SIZE - 1:0] = _set;
        for (iter = 0; iter < CACHE_LINE_SIZE - 1; iter += 2) begin
            _D2[15:8] = cache_data[_set * CACHE_WAY + index][CACHE_LINE_SIZE - iter - 1];
            _D2[7:0] = cache_data[_set * CACHE_WAY + index][CACHE_LINE_SIZE - iter - 2];
            wait_cnt(1);
        end
        _C2 = 'dz;
        _D2 = 'dz;
        wait (C2 == 1);
    endtask

    task invalid_cache_line(input reg[CACHE_TAG_SIZE - 1:0] _tag, input reg[CACHE_SET_SIZE - 1:0] _set);
        line_info1 = cache_info[_set * CACHE_WAY];
        line_info2 = cache_info[_set * CACHE_WAY + 1];
        if (line_info1[CACHE_TAG_SIZE + 3 - 1] == 1 && line_info1[CACHE_TAG_SIZE:1] == tag) begin
            if (line_info1[CACHE_TAG_SIZE + 3 - 2] == 1) begin
                write_line_in_mem(_tag, _set, 0);
            end
            cache_info[_set * CACHE_WAY][CACHE_TAG_SIZE + 3 - 1] = 0;
            cache_info[_set * CACHE_WAY][0] = 0;
            cache_info[_set * CACHE_WAY][0] = 1;
        end 
        else if (line_info2[CACHE_TAG_SIZE + 3 - 1] == 1 && line_info2[CACHE_TAG_SIZE:1] == tag) begin
            if (line_info2[CACHE_TAG_SIZE + 3 - 2] == 1) begin
                write_line_in_mem(_tag, _set, 1);
            end
            cache_info[_set * CACHE_WAY + 1][CACHE_TAG_SIZE + 3 - 1] = 0;
            cache_info[_set * CACHE_WAY][0] = 1;
            cache_info[_set * CACHE_WAY + 1][0] = 0;
        end 
    endtask

    always @(posedge C_DUMP) begin
        $display((count - miss) * 100 / count);
        $display("Count - %d, Miss - %d, Hits - %d", count, miss, hits);
        // for (dm = 0; dm < CACHE_LINE_COUNT; dm+=1) begin
        //     $display("Cache info number %d - %b", dm, cache_info[dm]);
        //     $display("Data line");
        //     for (bt = 0; bt < CACHE_LINE_SIZE; bt += 1) begin
        //         $display("%d - %b", bt, cache_data[dm][bt]);
        //     end
        //     $display("--------");
        // end
    end

    always @(posedge reset) begin
        reser_cache();
    end

    task reser_cache;
        for (cl = 0; cl < CACHE_LINE_COUNT; cl += 1) begin
            cache_info[cl] = 0;
        end
    endtask

endmodule