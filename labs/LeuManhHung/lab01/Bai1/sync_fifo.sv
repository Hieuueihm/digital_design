module sync_fifo(
	input logic clk,
	input logic rst_n, 
	input logic wr_en,
	input logic [7:0] wr_data ,
	input logic rd_en,
	output logic [7:0] rd_data ,
	output logic rd_valid, // flag
	output logic full,
	output logic empty,
	output logic [3:0] count  // 8 bit nen lon hon 111
);

	logic [7:0] mem [0:7]; // du lieu 8 bit, chi so tu 0 toi 7
	logic [2:0] wr_ptr ;
	logic [2:0] rd_ptr ;
	logic do_wr, do_rd;
	assign do_wr = wr_en && !full; // doc khi wr_en =1 va k full
	assign do_rd = rd_en && !empty;// doc khi wr_en =1 va k full
	always @(posedge clk or negedge rst_n) begin
		if (rst_n == 1'b0) begin // gan code vao phan cung phai rst dau tien
			wr_ptr <= 3'b000;
			rd_ptr <= 3'b000;
			count  <= 4'b0000;
			rd_valid <= 1'b0;
			rd_data <= 1'b0;
			end else begin
				rd_valid <= 1'b0;
				case ({do_wr,do_rd})
					2'b10: begin // chi ghi
						mem [wr_ptr] <= wr_data; // gia tri cua wr_ptr nhu nao
						wr_ptr <= (wr_ptr == 3'b111) ? 1'b0 : wr_ptr + 1'b1;
						count <= count + 1'b1;
						end
					2'b01: begin // chi doc
						rd_data <= mem [rd_ptr]; // 
						rd_ptr <= (rd_ptr == 3'b111) ? 1'b0 : rd_ptr + 1'b1;
						count <= count - 1'b1;
						rd_valid <= 1'b1;
						end
					2'b11 : begin
						mem [wr_ptr] <= wr_data; // gia tri cua wr_ptr nhu nao
						wr_ptr <= (wr_ptr == 3'b111) ? 1'b0 : wr_ptr + 1'b1;
						rd_data <= mem [rd_ptr]; // 
						rd_ptr <= (rd_ptr == 3'b111) ? 1'b0 : rd_ptr + 1'b1;
						count <= count ;// count giu nguyen
						rd_valid <= 1'b1;
						end
						default : begin
						end
					endcase
				end
			end
			assign empty = (count == 4'b0000);
			assign full  = (count == 4'b1000);
endmodule
			
			
	

