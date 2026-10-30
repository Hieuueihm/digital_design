
`timescale 1ns/1ps

module tb_fifo_1_top;

    logic clk;
    logic rst_n;
    logic wr_en;
    logic [7:0] wr_data;
    logic rd_en;
    logic [7:0] rd_data;
    logic rd_valid;
    logic full;
    logic empty;
    logic [3:0] count;

    fifo_1_top dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .wr_en    (wr_en),
        .wr_data  (wr_data),
        .rd_en    (rd_en),
        .rd_data  (rd_data),
        .rd_valid (rd_valid),
        .full     (full),
        .empty    (empty),
        .count    (count)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic fifo_cycle(
        input logic       wr,
        input logic [7:0] data,
        input logic       rd
    );
        begin
            @(negedge clk);
            wr_en   = wr;
            wr_data = data;
            rd_en   = rd;

            @(posedge clk);
            #1;
        end
    endtask

    initial begin
        rst_n   = 1'b0;
        wr_en   = 1'b0;
        wr_data = 8'h00;
        rd_en   = 1'b0;

        #1;
        assert (
            count === 4'd0 &&
            empty === 1'b1 &&
            full === 1'b0 &&
            rd_valid === 1'b0 &&
            rd_data === 8'h00
        )
        else $fatal(1, "TEST 1 FAIL: Reset");

        rst_n = 1'b1;

        fifo_cycle(1'b1, 8'h11, 1'b0);

        assert (
            count === 4'd1 &&
            empty === 1'b0 &&
            full === 1'b0
        )
        else $fatal(1, "TEST 1 FAIL: Write 0x11");

        fifo_cycle(1'b0, 8'h00, 1'b1);

        assert (
            count === 4'd0 &&
            empty === 1'b1 &&
            full === 1'b0 &&
            rd_valid === 1'b1 &&
            rd_data === 8'h11
        )
        else $fatal(1, "TEST 1 FAIL: Read 0x11");

        fifo_cycle(1'b0, 8'h00, 1'b0);

        assert (
            rd_valid === 1'b0 &&
            rd_data === 8'h11
        )
        else $fatal(1, "TEST 1 FAIL: rd_valid/rd_data hold");

        $display("TEST 1 PASS");

        for (int i = 0; i < 8; i++) begin
            fifo_cycle(1'b1, 8'(i), 1'b0);
        end

        assert (
            count === 4'd8 &&
            full === 1'b1 &&
            empty === 1'b0
        )
        else $fatal(1, "TEST 2 FAIL: FIFO should be full");

        fifo_cycle(1'b1, 8'h22, 1'b0);

        assert (
            count === 4'd8 &&
            full === 1'b1
        )
        else $fatal(1, "TEST 2 FAIL: Overflow");

        $display("TEST 2 PASS");

        for (int i = 0; i < 8; i++) begin
            fifo_cycle(1'b0, 8'h00, 1'b1);

            assert (
                rd_valid === 1'b1 &&
                rd_data === 8'(i)
            )
            else $fatal(1, "TEST 3 FAIL: Read index %0d", i);
        end

        assert (
            count === 4'd0 &&
            empty === 1'b1 &&
            full === 1'b0
        )
        else $fatal(1, "TEST 3 FAIL: FIFO should be empty");

        fifo_cycle(1'b0, 8'h00, 1'b1);

        assert (
            rd_valid === 1'b0 &&
            rd_data === 8'd7 &&
            count === 4'd0 &&
            empty === 1'b1
        )
        else $fatal(1, "TEST 3 FAIL: Underflow");

        $display("TEST 3 PASS");

        fifo_cycle(1'b1, 8'h11, 1'b0);
        fifo_cycle(1'b1, 8'h22, 1'b0);

        fifo_cycle(1'b1, 8'h33, 1'b1);

        assert (
            rd_valid === 1'b1 &&
            rd_data === 8'h11 &&
            count === 4'd2
        )
        else $fatal(1, "TEST 4 FAIL: Simultaneous read/write");

        fifo_cycle(1'b0, 8'h00, 1'b1);

        assert (
            rd_valid === 1'b1 &&
            rd_data === 8'h22 &&
            count === 4'd1
        )
        else $fatal(1, "TEST 4 FAIL: Read 0x22");

        fifo_cycle(1'b0, 8'h00, 1'b1);

        assert (
            rd_valid === 1'b1 &&
            rd_data === 8'h33 &&
            count === 4'd0 &&
            empty === 1'b1
        )
        else $fatal(1, "TEST 4 FAIL: Read 0x33");

        $display("TEST 4 PASS");

        fifo_cycle(1'b1, 8'h44, 1'b1);

        assert (
            rd_valid === 1'b0 &&
            count === 4'd1 &&
            empty === 1'b0
        )
        else $fatal(1, "TEST 5A FAIL: Empty + read/write");

        fifo_cycle(1'b0, 8'h00, 1'b1);

        assert (
            rd_valid === 1'b1 &&
            rd_data === 8'h44 &&
            count === 4'd0 &&
            empty === 1'b1
        )
        else $fatal(1, "TEST 5A FAIL: Read 0x44");

        $display("TEST 5A PASS");

        for (int i = 0; i < 8; i++) begin
            fifo_cycle(1'b1, 8'hA0 + i, 1'b0);
        end

        assert (
            count === 4'd8 &&
            full === 1'b1
        )
        else $fatal(1, "TEST 5B FAIL: FIFO should be full");

        fifo_cycle(1'b1, 8'h99, 1'b1);

        assert (
            rd_valid === 1'b1 &&
            rd_data === 8'hA0 &&
            count === 4'd7 &&
            full === 1'b0
        )
        else $fatal(1, "TEST 5B FAIL: Full + read/write");

        // Doc tiep A1 den A7
        for (int i = 1; i < 8; i++) begin
            fifo_cycle(1'b0, 8'h00, 1'b1);

            assert (
                rd_valid === 1'b1 &&
                rd_data === 8'hA0 + i
            )
            else $fatal(1, "TEST 5B FAIL: Read index %0d", i);
        end

        assert (
            count === 4'd0 &&
            empty === 1'b1
        )
        else $fatal(1, "TEST 5B FAIL: FIFO should be empty");

        $display("TEST 5B PASS");

        for (int i = 0; i < 20; i++) begin

            // Ghi 3 ban sao cua mot gia tri
            for (int k = 0; k < 3; k++) begin
                fifo_cycle(1'b1, 8'hB0 + i, 1'b0);
            end

            assert (
                count === 4'd3 &&
                full === 1'b0 &&
                empty === 1'b0
            )
            else $fatal(1, "TEST 6 FAIL: Write group %0d", i);

            for (int k = 0; k < 3; k++) begin
                fifo_cycle(1'b0, 8'h00, 1'b1);

                assert (
                    rd_valid === 1'b1 &&
                    rd_data === 8'hB0 + i
                )
                else $fatal(
                    1,
                    "TEST 6 FAIL: Group %0d, item %0d",
                    i, k
                );
            end

            assert (
                count === 4'd0 &&
                empty === 1'b1
            )
            else $fatal(1, "TEST 6 FAIL: End group %0d", i);
        end

        $display("TEST 6 PASS");

        wr_en = 1'b0;
        rd_en = 1'b0;

        $display("ALL FIFO TESTS PASSED");

        $finish;
    end

endmodule
