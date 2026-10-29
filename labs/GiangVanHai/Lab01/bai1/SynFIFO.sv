module synFIFO #(parameter int DATA_WIDTH = 8, parameter int DEPTH = 8)(
		input logic clk,
		input logic rst_n,
		input logic wr_en,
		input logic [DATA_WIDTH-1:0] wr_data,
		input logic rd_en,
		
		output logic [DATA_WIDTH-1:0] rd_data,
		output logic rd_valid,
		output logic full,
		output logic empty,
		output logic [$clog2(DEPTH+1)-1:0] count 
);

	logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];
	localparam int PTR_W = (DEPTH > 1) ? $clog2(DEPTH) : 1;
	logic [PTR_W-1:0] wr_pointer, rd_pointer;
	
	assign full  = (count == DEPTH);
   assign empty = (count == 0);
	
	function logic [PTR_W-1:0] next_pointer(input logic [PTR_W-1:0] p);
		return (p == PTR_W'(DEPTH-1)) ? 0 : p + 1;
	endfunction
	
	wire wr_ok = wr_en && !full;
	wire rd_ok = rd_en && !empty;
	
	always_ff @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			wr_pointer <= '0;
			rd_pointer <= '0;
			count <= '0;
			rd_data <= '0;
			rd_valid <= '0;
		end 
		else begin
			rd_valid <= rd_ok;
			if (wr_ok) begin
					mem[wr_pointer] <= wr_data;
					wr_pointer <= next_pointer(wr_pointer);
			end
			if (rd_ok) begin
					rd_data <= mem[rd_pointer];
					rd_pointer <= next_pointer(rd_pointer);
			end
			case ({wr_ok,rd_ok})
				2'b10: count <= count + 1;
				2'b01: count <= count - 1;
				default: count <= count;
			endcase
		end
	end
endmodule
					