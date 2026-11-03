`timescale 1ns/1ps 
module tb_sync_fifo;
	logic clk;
	logic rst_n;
	logic wr_en;
	logic [7:0] wr_data;
	logic rd_en;
	logic [7:0] rd_data;
	logic rd_valid;
	logic full;
	logic empty;
	logic [3:0] count; 
	

   sync_fifo dut (
		.clk(clk),
		.rst_n(rst_n),
		.wr_en(wr_en),
		.wr_data(wr_data),
		.rd_en(rd_en),
		.rd_data(rd_data),
		.rd_valid(rd_valid),
		.full(full),
		.empty(empty),
		.count(count)
    );
always #5 clk = ~clk; // tao xung clock,1 chu ki = 10ns
initial begin
	clk = 1'b0;
	rst_n = 1'b0;
	wr_en = 1'b0;
	rd_en = 1'b0;
	wr_data = 8'h00;
	#20;
	rst_n = 1'b0;
	#10;
	// Sau reset
	$display("FIFO rong, count = %0d", count);
	#10;
	// Test 1 ; Reset, ghi 0x33 , doc 0x33
	assert (count === 0 && empty === 1 && full === 0 && rd_valid === 0 && rd_data === 8'h00)
		else $error("test 1 false");
	@(posedge clk);
   wr_en   = 1'b1;
   wr_data = 8'h33;
   @(posedge clk);
   wr_en   = 1'b0; // tat ghi
   $display("Sau khi ghi | count = %0d", count);
	// Doc ra
    @(posedge clk);
    rd_en   = 1'b1;
    @(posedge clk);
    rd_en   = 1'b0; // Tắt doc
    $display("rd_data = %h | count = %0d", rd_data, count);
	 #10;
	// Test 2: Ghi den khi co 8 phan tu, thu ghi tiep
	for (int i = 1; i <= 9; i++) begin
		@(posedge clk);
		wr_en   = 1'b1;
		wr_data = 8'h10 * i; // 
		@(posedge clk);
		wr_en   = 1'b0;
		$display("rd_data = %h | count = %0d",rd_data, count);
	 end
    #10;
	// Test 3 : Doc den khi empty
	for (int i = 1; i <= 9; i++) begin
		@(posedge clk);
		rd_en   = 1'b1;
		@(posedge clk);
		rd_en   = 1'b0;
		$display("rd_data = %h | count = %0d",rd_data, count);
	end
   #10;
	// Test 4 : Ghi + doc khi co 2 phan tu
	// Ghi 2 phan tu 0x11 , 0x22
	@(posedge clk);
   wr_en   = 1'b1;
   wr_data = 8'h11;
   @(posedge clk);
   wr_en   = 1'b0;
		  
   @(posedge clk);
   wr_en   = 1'b1;
   wr_data = 8'h22;
   @(posedge clk);
   wr_en   = 1'b0; 
	// Ghi 0x33 dong thoi doc
	@(posedge clk);
	wr_en = 1'b1;
	rd_en = 1'b1;
	wr_data = 8'h33;
	@(posedge clk);
	wr_en = 1'b0;
	rd_en = 1'b0;
	$display("rd_data = %h | count = %0d",rd_data, count);
	#10;
	// Test 5: Ghi va doc khi FIFO rong va day
	if (empty === 1'b1) begin // khi FIFO rong
		@(posedge clk);
		rd_en = 1'b1;
		wr_en = 1'b1;
		wr_data = 8'h12;
		@(posedge clk);
		wr_en = 1'b0;
		rd_en = 1'b0;
		$display("rd_data = %h | count = %0d",rd_data, count);
		end
	while (!full) begin // khi FIFO day
		@(posedge clk);
		rd_en = 1'b1;
		wr_en = 1'b1;
		wr_data = 8'h13;
		@(posedge clk);
		wr_en = 1'b0;
		rd_en = 1'b0;
		$display("rd_data = %h | count = %0d",rd_data, count);
		end
		rst_n = 1'b0; #20; rst_n = 1'b1; #10; // reset dua ve dau
	// Test 6: kiem tra sau khi quay vong
	for (int k=0;k<=3;k++) begin
		for (int i = 1; i <= 8; i++) begin // ghi du 8 du lieu
			@(posedge clk);
			wr_en   = 1'b1;
			wr_data = 8'h10 + i; 
			@(posedge clk);
			wr_en   = 1'b0;
		end
		for (int i = 0; i < 8; i++) begin
			 @(posedge clk);
			 rd_en   = 1'b1;
			 @(posedge clk);
			 rd_en   = 1'b0;
			 $display("rd_data = %h | count = %0d",rd_data, count); // kiem tra 
		end
	end
	$finish;
	end
endmodule
	
	
	
	
	
	 