module apb3_slave(
	input logic PCLK,
	input logic PRESETn,
	input logic PSEL,
	input logic PENABLE,
	input logic PWRITE,
	input logic [7:0] PADDR,
	input logic [31:0] PWDATA,
	output logic [31:0] PRDATA,
	output logic PREADY,
	output logic PSLVERR
);

	localparam [7:0] addr_control = 8'h00;
	localparam [7:0] addr_data = 8'h04;
	localparam [7:0] addr_status = 8'h08;
	
	reg control_0;
	reg [31:0] data;
	wire [31:0] status_val = {30'b0, control_0, 1'b1};
	
	assign PREADY = 1'b1;
	
	wire access = PSEL & PENABLE;
	
	always_ff @(posedge PCLK or negedge PRESETn) begin
		if (!PRESETn) begin
			control_0 <= 1'b0;
			data <= 32'b0;
		end else if (access && PREADY && PWRITE) begin
			case (PADDR)
				addr_control:
					control_0 <= PWDATA[0];
				addr_data: 
					data <= PWDATA;
				default: ;
			endcase
		end
	end

	always_comb begin
		PRDATA = 32'b0;
		PSLVERR = 1'b0;
		if (access) begin
			case (PADDR)
				addr_control:
					if (!PWRITE) PRDATA = {31'b0, control_0};
				addr_data:
					if (!PWRITE) PRDATA = data;
				addr_status: begin
					if (PWRITE) PSLVERR = 1'b1;
					else PRDATA = status_val;
				end
				default: PSLVERR = 1'b1;
			endcase
		end
	end
endmodule