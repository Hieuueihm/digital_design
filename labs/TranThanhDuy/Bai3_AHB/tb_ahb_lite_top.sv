`timescale 1ns/1ps

module tb_ahb_lite_top;

    logic HCLK;
    logic HRESETn;
    logic HSEL;
    logic [31:0] HADDR;
    logic [1:0] HTRANS;
    logic HWRITE;
    logic [2:0] HSIZE;
    logic [31:0] HWDATA;
    logic HREADY;

    logic [31:0] HRDATA;
    logic HREADYOUT;
    logic HRESP;

    logic [31:0] data;
    integer errors;

    localparam IDLE  = 2'b00;
    localparam BUSY  = 2'b01;
    localparam NONSEQ = 2'b10;
    localparam WORD  = 3'b010;

    ahb_lite_top dut (
        .HCLK(HCLK),
        .HRESETn(HRESETn),
        .HSEL(HSEL),
        .HADDR(HADDR),
        .HTRANS(HTRANS),
        .HWRITE(HWRITE),
        .HSIZE(HSIZE),
        .HWDATA(HWDATA),
        .HREADY(HREADY),
        .HRDATA(HRDATA),
        .HREADYOUT(HREADYOUT),
        .HRESP(HRESP)
    );

    initial begin
        HCLK = 0;
        forever #5 HCLK = ~HCLK;
    end

    task check_value(input logic [31:0] actual,
                     input logic [31:0] expected,
                     input string message);
        begin
            if (actual !== expected) begin
                $display("FAIL: %s | Actual = %h | Expected = %h",
                         message, actual, expected);
                errors = errors + 1;
            end
            else begin
                $display("PASS: %s", message);
            end
        end
    endtask

    task write_reg(input logic [31:0] address,
                   input logic [31:0] value);
        begin
            @(negedge HCLK);
            HSEL   = 1;
            HTRANS = NONSEQ;
            HWRITE = 1;
            HSIZE  = WORD;
            HADDR  = address;

            @(negedge HCLK);
            HSEL   = 0;
            HTRANS = IDLE;
            HWRITE = 0;
            HWDATA = value;

            @(posedge HCLK);
            #1;
        end
    endtask

    task read_reg(input logic [31:0] address,
                  input logic [31:0] expected);
        begin
            @(negedge HCLK);
            HSEL   = 1;
            HTRANS = NONSEQ;
            HWRITE = 0;
            HSIZE  = WORD;
            HADDR  = address;

            @(posedge HCLK);
            #1;
            check_value(HRDATA, expected, "Read register");

            @(negedge HCLK);
            HSEL   = 0;
            HTRANS = IDLE;
        end
    endtask

    initial begin
        HRESETn = 0;
        HSEL    = 0;
        HADDR   = 0;
        HTRANS  = IDLE;
        HWRITE  = 0;
        HSIZE   = WORD;
        HWDATA  = 0;
        HREADY  = 1;
        errors  = 0;

        repeat (2) @(posedge HCLK);
        #1;
        HRESETn = 1;

        $display("\nTEST 1: RESET");

        read_reg(32'h0, 32'h0);
        read_reg(32'h4, 32'h0);
        read_reg(32'h8, 32'h0);
        read_reg(32'hC, 32'h0);

        $display("\nTEST 2: WRITE REG0 AND READ BACK");

        write_reg(32'h0, 32'h12345678);
        read_reg(32'h0, 32'h12345678);

        $display("\nTEST 3: TWO CONSECUTIVE ADDRESS PHASES");

        @(negedge HCLK);
        HSEL   = 1;
        HTRANS = NONSEQ;
        HWRITE = 1;
        HSIZE  = WORD;
        HADDR  = 32'h0;

        @(negedge HCLK);
        HADDR  = 32'h4;
        HWDATA = 32'hAAAAAAAA;

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = IDLE;
        HWRITE = 0;
        HWDATA = 32'hBBBBBBBB;

        @(posedge HCLK);
        #1;

        read_reg(32'h0, 32'hAAAAAAAA);
        read_reg(32'h4, 32'hBBBBBBBB);

        $display("\nTEST 4: IDLE, BUSY AND HSEL");

        @(negedge HCLK);
        HSEL   = 1;
        HTRANS = IDLE;
        HWRITE = 1;
        HADDR  = 32'h8;

        @(negedge HCLK);
        HTRANS = BUSY;
        HWDATA = 32'hFFFFFFFF;

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = NONSEQ;
        HWDATA = 32'hEEEEEEEE;

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = IDLE;
        HWRITE = 0;

        read_reg(32'h8, 32'h0);

        $display("\nTEST 5: HREADY LOW AT ADDRESS PHASE");

        @(negedge HCLK);
        HREADY = 0;
        HSEL   = 1;
        HTRANS = NONSEQ;
        HWRITE = 1;
        HSIZE  = WORD;
        HADDR  = 32'h8;

        @(posedge HCLK);
        #1;

        @(negedge HCLK);
        HREADY = 1;

        @(posedge HCLK);
        #1;

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = IDLE;
        HWRITE = 0;
        HWDATA = 32'h88888888;

        @(posedge HCLK);
        #1;

        read_reg(32'h8, 32'h88888888);

        $display("\nTEST 6: HREADY LOW AT DATA PHASE");

        @(negedge HCLK);
        HSEL   = 1;
        HTRANS = NONSEQ;
        HWRITE = 1;
        HSIZE  = WORD;
        HADDR  = 32'h8;
        HREADY = 1;

        @(posedge HCLK);
        #1;

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = IDLE;
        HWRITE = 0;
        HREADY = 0;
        HWDATA = 32'h99999999;

        @(posedge HCLK);
        #1;
        check_value(dut.reg_file[2], 32'h88888888,
                    "No write when HREADY is low");

        @(negedge HCLK);
        HREADY = 1;

        @(posedge HCLK);
        #1;

        read_reg(32'h8, 32'h99999999);

        $display("\nTEST 7: INVALID HSIZE");

        @(negedge HCLK);
        HSEL   = 1;
        HTRANS = NONSEQ;
        HWRITE = 1;
        HSIZE  = 3'b001;
        HADDR  = 32'h0;

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = IDLE;
        HWRITE = 0;
        HSIZE  = WORD;
        HWDATA = 32'hFFFFFFFF;

        @(posedge HCLK);
        #1;

        read_reg(32'h0, 32'h12345678);

        $display("\nTEST 8: MISALIGNED ADDRESS");

        @(negedge HCLK);
        HSEL   = 1;
        HTRANS = NONSEQ;
        HWRITE = 1;
        HSIZE  = WORD;
        HADDR  = 32'h1;

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = IDLE;
        HWRITE = 0;
        HWDATA = 32'hFFFFFFFF;

        @(posedge HCLK);
        #1;

        read_reg(32'h0, 32'h12345678);

        $display("\nTEST 9: ADDRESS OUTSIDE REGISTER MAP");

        @(negedge HCLK);
        HSEL   = 1;
        HTRANS = NONSEQ;
        HWRITE = 1;
        HSIZE  = WORD;
        HADDR  = 32'h10;

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = IDLE;
        HWRITE = 0;
        HWDATA = 32'hFFFFFFFF;

        @(posedge HCLK);
        #1;

        read_reg(32'h0, 32'h12345678);
        read_reg(32'h4, 32'hAAAAAAAA);
        read_reg(32'h8, 32'h99999999);
        read_reg(32'hC, 32'h0);

        $display("\nTEST 10: INVALID READ");

        @(negedge HCLK);
        HSEL   = 1;
        HTRANS = NONSEQ;
        HWRITE = 0;
        HSIZE  = 3'b001;
        HADDR  = 32'h0;

        @(posedge HCLK);
        #1;
        check_value(HRDATA, 32'h0, "Invalid size read returns zero");

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = IDLE;
        HSIZE  = WORD;

        @(negedge HCLK);
        HSEL   = 1;
        HTRANS = NONSEQ;
        HWRITE = 0;
        HADDR  = 32'h1;

        @(posedge HCLK);
        #1;
        check_value(HRDATA, 32'h0, "Misaligned read returns zero");

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = IDLE;

        @(negedge HCLK);
        HSEL   = 1;
        HTRANS = NONSEQ;
        HADDR  = 32'h10;

        @(posedge HCLK);
        #1;
        check_value(HRDATA, 32'h0, "Out-of-map read returns zero");

        @(negedge HCLK);
        HSEL   = 0;
        HTRANS = IDLE;

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED: %0d errors", errors);

        $finish;
    end

endmodule