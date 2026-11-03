module apb3_rslave(
	input logic PCLK,
	input logic PRESETn,
	input logic PSEL,
	input logic PENABLE,
	input logic PWRITE,
	input logic [7:0] PADDR, // dia chi
	input logic [31:0] PWDATA,// ghi
	output logic [31:0] PRDATA, // doc
	output logic PREADY, // giao dich done
	output logic PSLVERR // bao loi dia chi
);
logic CONTROL;
logic [31:0] DATA;
logic [31:0] STATUS;
assign STATUS = {30'b0, CONTROL, 1'b1};

assign PREADY = 1'b1;
wire is_access = PSEL && PENABLE;
wire addr = (PADDR == 8'h00 || PADDR == 8'h04 || PADDR == 8'h08 );
wire err_condition = ! addr || (PWRITE && (PADDR == 8'h08)); // loi khi khac valid hoac co dien vao thanh doc
assign PSLVERR = is_access ? err_condition : 1'b0; 
wire write_en = (is_access && PREADY && PWRITE && addr && !PSLVERR); // ghi thi PSLVERR = 0
always @(posedge PCLK or negedge PRESETn) begin // mach ghi
	if (!PRESETn) begin // khi reset
		CONTROL <= 1'b0;
		DATA <= 0; 
		end else if (write_en) begin
		case (PADDR)
		8'h00: CONTROL <= PWDATA[0];	// ghi bit[0]
		8'h04: DATA <= PWDATA; // Luu du 32 bit
		// STATUS khong dung vi RO
		default: ; // khong phai thi giu 2 truong hop tren
		endcase
		end
	end
always_comb begin
	if(is_access && !PWRITE) begin // Lenh doc
		case (PADDR)
			8'h00: PRDATA = {31'b0, CONTROL};
			8'h04: PRDATA = DATA;
			8'h08: PRDATA = STATUS;
		default: PRDATA = 0;        
		endcase
      end else begin
            PRDATA = 0;
        end
	end
endmodule
		







