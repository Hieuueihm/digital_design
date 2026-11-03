module apb3_top (
    input  logic        PCLK,
    input  logic        PRESETn,
    input  logic        PSEL,
    input  logic        PENABLE,
    input  logic        PWRITE,
    input  logic [7:0]  PADDR,
    input  logic [31:0] PWDATA,
    output logic [31:0] PRDATA,
    output logic        PREADY,
    output logic        PSLVERR
);

    localparam logic [7:0] ADDR_CONTROL = 8'h00;
    localparam logic [7:0] ADDR_DATA    = 8'h04;
    localparam logic [7:0] ADDR_STATUS  = 8'h08;

    logic        ctrl_en;
    logic [31:0] data_reg;

    logic access;
    logic completing;
    logic sel_ctrl;
    logic sel_data;
    logic sel_status;
    logic addr_valid;
    logic addr_wr_ok;
    logic wr_en;

    assign access     = PSEL & PENABLE;
    assign PREADY     = 1'b1;
    assign completing = access & PREADY;

    assign sel_ctrl   = (PADDR == ADDR_CONTROL);
    assign sel_data   = (PADDR == ADDR_DATA);
    assign sel_status = (PADDR == ADDR_STATUS);

    assign addr_valid = sel_ctrl | sel_data | sel_status;
    assign addr_wr_ok = sel_ctrl | sel_data;

    assign wr_en = completing & PWRITE & addr_wr_ok;

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            ctrl_en  <= 1'b0;
            data_reg <= 32'h0000_0000;
        end else if (wr_en) begin
            if (sel_ctrl)
                ctrl_en <= PWDATA[0];

            if (sel_data)
                data_reg <= PWDATA;
        end
    end

    always_comb begin
        PRDATA = 32'h0000_0000;

        if (access && !PWRITE) begin
            case (PADDR)
                ADDR_CONTROL:
                    PRDATA = {31'b0, ctrl_en};

                ADDR_DATA:
                    PRDATA = data_reg;

                ADDR_STATUS:
                    PRDATA = {30'b0, ctrl_en, 1'b1};

                default:
                    PRDATA = 32'h0000_0000;
            endcase
        end
    end

    assign PSLVERR =
        completing & (~addr_valid | (PWRITE & sel_status));

endmodule
