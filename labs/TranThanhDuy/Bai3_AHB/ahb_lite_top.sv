module ahb_lite_top (
    input  logic        HCLK,
    input  logic        HRESETn,
    input  logic        HSEL,
    input  logic [31:0] HADDR,
    input  logic [1:0]  HTRANS,
    input  logic        HWRITE,
    input  logic [2:0]  HSIZE,
    input  logic [31:0] HWDATA,
    input  logic        HREADY,

    output logic [31:0] HRDATA,
    output logic        HREADYOUT,
    output logic        HRESP
);

    logic [31:0] reg_file [0:3];

    logic [1:0]  addr_reg;
    logic        wr_reg;
    logic        trans_valid;

    logic        transfer_valid;
    logic        word_access;
    logic        aligned_addr;

    assign transfer_valid = HSEL && HTRANS[1];
    assign word_access    = (HSIZE == 3'b010);
    assign aligned_addr   = (HADDR[31:4] == 28'b0) &&
                            (HADDR[1:0] == 2'b00);

    assign HREADYOUT = 1'b1;
    assign HRESP     = 1'b0;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            for (int i = 0; i < 4; i = i + 1)
                reg_file[i] <= 32'b0;

            addr_reg    <= 2'b00;
            wr_reg      <= 1'b0;
            trans_valid <= 1'b0;
        end
        else if (HREADY) begin
            if (trans_valid && wr_reg)
                reg_file[addr_reg] <= HWDATA;

            addr_reg    <= HADDR[3:2];
            wr_reg      <= HWRITE;
            trans_valid <= transfer_valid && word_access && aligned_addr;
        end
    end

    always_comb begin
        HRDATA = 32'b0;

        if (trans_valid && !wr_reg)
            HRDATA = reg_file[addr_reg];
    end

endmodule