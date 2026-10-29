module ahb_lite(
	input logic HCLK,
	input logic HRESETn,
	input logic HSEL,
	input logic [31:0] HADDR,
	input logic [1:0] HTRANS,
	input logic HWRITE,
	input logic [2:0] HSIZE,
	input logic [31:0] HWDATA,
	input logic HREADY,
	output logic [31:0] HRDATA,
	output logic HREADYOUT,
	output logic HRESP
);

	logic [31:0] regs [0:3];
	logic [1:0] addr_q;
	logic write_q;
	logic valid_q;
	
	wire sel_tran = HSEL & HTRANS[1];
	wire size_ok = (HSIZE == 3'b010);
	wire addr_ok = (HADDR == 32'h0 || HADDR == 32'h4 || HADDR == 32'h8 || HADDR == 32'hC);
	wire new_valid = sel_tran & size_ok & addr_ok;
	
	assign HREADYOUT = 1'b1;
	assign HRESP = 1'b0;
	
	always_ff @(posedge HCLK or negedge HRESETn) begin
		if (!HRESETn) begin
			regs[0] <= 32'b0;
			regs[1] <= 32'b0;
			regs[2] <= 32'b0;
			regs[3] <= 32'b0;
			addr_q <= 2'b0;
			write_q <= 1'b0;
			valid_q <= 1'b0;
		end else if (HREADY) begin
			if (valid_q && write_q) regs[addr_q] <= HWDATA;
			addr_q <= HADDR[3:2];
			write_q <= HWRITE;
			valid_q <= new_valid;
		end
	end
	
	always_comb begin
		HRDATA = 32'b0;
		if (valid_q && !write_q) HRDATA = regs[addr_q];
	end
endmodule