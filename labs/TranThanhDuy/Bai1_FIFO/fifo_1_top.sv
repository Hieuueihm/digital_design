module fifo_1_top (
		input logic clk,
		input logic rst_n,
		
		input logic wr_en,
		input logic [7:0] wr_data,
		
		input logic rd_en,
		output logic [7:0] rd_data,
		output logic rd_valid,
		
		output logic full,
		output logic empty,
		output logic [3:0] count
);

		logic [7:0] mem [0:7];
		logic [2:0] wr_ptr;
		logic [2:0] rd_ptr;
		logic wr_oke;
		logic rd_oke;
		
		assign empty = (count == 4'd0);
		assign full = (count == 4'd8);
		
		assign wr_oke = (wr_en && !full);
		assign rd_oke = (rd_en && !empty);
		
		always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr   <= 3'd0;
            rd_ptr   <= 3'd0;
            count    <= 4'd0;
            rd_data  <= 8'd0;
            rd_valid <= 1'b0;
        end
        else begin
            rd_valid <= 1'b0;

            if (wr_oke) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr      <= wr_ptr + 3'd1;
            end

            if (rd_oke) begin
                rd_data  <= mem[rd_ptr];
                rd_ptr   <= rd_ptr + 3'd1;
                rd_valid <= 1'b1;
            end

            case ({wr_oke, rd_oke})
                2'b10: count <= count + 4'd1;
                2'b01: count <= count - 4'd1;
                default: count <= count;
            endcase
        end
    end

endmodule
