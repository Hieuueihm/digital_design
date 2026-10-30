module ahb_rslave(
	input logic HCLK,
    input  logic HRESETn,
	 input  logic HSEL, // chon slave
    input  logic [31:0] HADDR,
    input  logic [1:0]  HTRANS, // HTRANS[1] = 1 CHO
    input  logic HWRITE,
    input  logic [2:0] HSIZE,
    input  logic [31:0] HWDATA,
    input  logic HREADY, // cho phep toi pha tiep
    output logic [31:0] HRDATA,
    output logic        HREADYOUT,
    output logic        HRESP
);

assign HREADYOUT = 1'b1;
assign HRESP = 1'b0;

reg [31:0] reg0, reg1, reg2, reg3;
reg dp_active; // dang o data phase
reg dp_write; //
reg [1:0] dp_addr; // xac dinh thanh ghi nao
wire addr_valid = (HSIZE == 3'b010) && 
						(HADDR == 32'h0000_0000 ||
						HADDR == 32'h0000_0004 ||
						HADDR == 32'h0000_0008 ||
						HADDR == 32'h0000_000C );
// khoi tao giao dich moi trong add phase
wire trans_en = HREADY && HSEL && HTRANS[1] && addr_valid; // cho phep khi 10 va 11
always @(posedge HCLK or negedge HRESETn) begin
	if (!HRESETn) begin // Khi reset
		reg0      <= 32'h0;
		reg1      <= 32'h0;
		reg2      <= 32'h0;
		reg3      <= 32'h0;
		dp_active <= 1'b0;
		dp_write  <= 1'b0;
		dp_addr <= 2'b00;
	end else begin
		if (HREADY) begin // cho phep
			if(trans_en) begin // 
				dp_active <= 1'b1;
				dp_write <= HWRITE;
				dp_addr <= HADDR [3:2]; // chi giu lai cac bit tu 3->2
			end else begin
				dp_active <= 0; // cho lenh tiep theo
			end
		end
			if (dp_active && dp_write) begin // viet vao thanh ghi nao
				case (dp_addr)
				
					 2'b00: reg0 <= HWDATA;
					 2'b01: reg1 <= HWDATA;
					 2'b10: reg2 <= HWDATA;
					 2'b11: reg3 <= HWDATA;
					 default;
				endcase
			end
		end
	end
always_comb begin 
	if(dp_active && !dp_write) begin // write = 1 : Doc
		case (dp_addr)
			2'b00: HRDATA = reg0;
         2'b01: HRDATA = reg1;
		   2'b10: HRDATA = reg2;
         2'b11: HRDATA = reg3;
      default: HRDATA = 32'h0;
		endcase
	end else begin
		HRDATA = 0;
	end
	end
endmodule
			
	
	
			
			
		







