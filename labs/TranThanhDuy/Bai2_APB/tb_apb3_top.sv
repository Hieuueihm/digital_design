module tb_apb3_top;
    logic PCLK;
    logic PRESETn;
    logic PSEL;
    logic PENABLE;
    logic PWRITE;
    logic [7:0]  PADDR;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic PREADY;
    logic PSLVERR;

    apb3_top dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );

    initial PCLK = 1'b0;
    always #5 PCLK = ~PCLK;

    task apb_wr(
        input logic [7:0]  paddr,
        input logic [31:0] pwdata,
        input logic        pslverr,
        input string       name
    );
        PSEL = 1;
        PENABLE = 0;
        PWRITE = 1;
        PADDR = paddr;
        PWDATA = pwdata;

        @(posedge PCLK); #1;
        PENABLE = 1;

        do begin
            @(posedge PCLK);
        end while (PREADY !== 1'b1);

        #1;
        assert (PSLVERR === pslverr)
            else $error("%0s false (PSLVERR=%b)", name, PSLVERR);

        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
    endtask

    task apb_rd(
        input logic [7:0]  paddr,
        input logic [31:0] prdata,
        input logic        pslverr,
        input string       name
    );
        PSEL = 1;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = paddr;

        @(posedge PCLK); #1;
        PENABLE = 1;

        do begin
            @(posedge PCLK);
        end while (PREADY !== 1'b1);

        #1;
        assert (PRDATA === prdata && PSLVERR === pslverr)
            else $error(
                "%0s false (PRDATA=%h PSLVERR=%b)",
                name, PRDATA, PSLVERR
            );

        PSEL = 0;
        PENABLE = 0;
    endtask

    initial begin
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;
        PADDR = 0;
        PWDATA = 0;
        PRESETn = 0;

        #12;
        assert (
            PREADY === 1 &&
            PRDATA === 0 &&
            PSLVERR === 0 &&
            dut.ctrl_en === 0 &&
            dut.data_reg === 0
        )
            else $error("Test 1 false (reset)");

        PRESETn = 1;
        @(posedge PCLK); #1;

        apb_rd(8'h00, 32'h00000000, 0, "Test 1 CONTROL");
        apb_rd(8'h04, 32'h00000000, 0, "Test 1 DATA");
        apb_rd(8'h08, 32'h00000001, 0, "Test 1 STATUS");

        apb_wr(8'h00, 32'h00000001, 0, "Test 2 write CONTROL");
        apb_rd(8'h00, 32'h00000001, 0, "Test 2 read CONTROL");
        apb_rd(8'h08, 32'h00000003, 0, "Test 2 read STATUS");

        apb_wr(8'h00, 32'hFFFFFFFE, 0, "Test 2 write bit0=0");
        apb_rd(8'h00, 32'h00000000, 0, "Test 2 CONTROL bit0");

        apb_wr(8'h04, 32'hDEADBEEF, 0, "Test 3 write DATA");
        apb_rd(8'h04, 32'hDEADBEEF, 0, "Test 3 read DATA");

        apb_wr(8'h08, 32'hFFFFFFFF, 1, "Test 4 write STATUS");
        apb_rd(8'h08, 32'h00000001, 0, "Test 4 STATUS unchanged");
        apb_rd(8'h04, 32'hDEADBEEF, 0, "Test 4 DATA unchanged");

        apb_rd(8'h0C, 32'h00000000, 1, "Test 5 read 0x0C");
        apb_rd(8'h01, 32'h00000000, 1, "Test 5 read 0x01");
        apb_wr(8'h0C, 32'h00001234, 1, "Test 5 write 0x0C");
        apb_wr(8'h01, 32'h00001234, 1, "Test 5 write 0x01");

        PSEL = 1;
        PENABLE = 0;
        PWRITE = 1;
        PADDR = 8'h04;
        PWDATA = 32'hAAAAAAAA;

        #1;
        assert (PSLVERR === 0 && PRDATA === 0)
            else $error("Test 6 false (SETUP)");

        @(posedge PCLK); #1;
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;

        @(posedge PCLK); #1;
        apb_rd(8'h04, 32'hDEADBEEF, 0, "Test 6 DATA unchanged");

        $display("All tests completed.");
        $stop;
    end

endmodule
