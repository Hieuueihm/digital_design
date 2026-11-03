module synFIFO_tb;

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
	
	synFIFO dut(
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
	
	initial clk = 1'b0;
	always #5 clk = ~clk;
	
	initial begin
		wr_en = 0;
		rd_en = 0;
		wr_data = 8'h00;
		
		// test 1
		rst_n = 0;
		#12;
		assert (count === 0 && empty === 1 && full === 0 && rd_valid === 0 && rd_data === 8'h00)
			else $error("test 1 false");
			
		rst_n = 1;
		@(posedge clk);
		#1;
		
		wr_en = 1;
		wr_data = 8'h11;
		rd_en = 0;
		@(posedge clk); #1;
		assert (count === 1 && empty === 0 && full === 0)
			else $error("test 1 false (write)");
		
		wr_en = 0;
		rd_en = 1;
		@(posedge clk); #1;
		assert (count === 0 && empty === 1 && full === 0 && rd_valid === 1 && rd_data === 8'h11)
			else $error("test 1 false (read)");
		
		wr_en = 0;
		rd_en = 0;
		@(posedge clk); #1;
		assert(rd_valid === 0 && rd_data === 8'h11)
			else $error("test 1 false (read complete)");
			
		// test 2
		for (int i = 0; i < 8; i++) begin
			wr_en = 1;
			wr_data = 8'h00 + i;
			rd_en = 0;
			@(posedge clk); #1;
		end
		assert(count === 8 && full === 1 && empty === 0)
			else $error("test 2 false (not full)");
			
		wr_en = 1; wr_data = 8'h22; rd_en = 0;
		@(posedge clk); #1;
		assert(count === 8 && full === 1)
			else $error("test 2 false (overflow)");
		
		//test 3
		for (int i = 0; i < 8; i++) begin
			wr_en = 0;
			rd_en = 1;
			@(posedge clk); #1;
		end
		assert(count === 0 && empty === 1 && full === 0)
			else $error("test 3 false (not empty)");
		
		wr_en = 0; 
		rd_en = 1;
		@(posedge clk); #1;
		assert(rd_valid === 0 && rd_data === 8'h07 && count === 0)
			else $error("test 3 false");
		
		// test 4
		wr_en = 1; 
		wr_data = 8'h11;
		rd_en = 0;
		@(posedge clk); #1;
		wr_en = 1; 
		wr_data = 8'h22;
		rd_en = 0;
		@(posedge clk); #1;
		
		wr_en = 1;
		wr_data = 8'h33;
		rd_en = 1;
		@(posedge clk); #1;
		assert (rd_valid === 1 && rd_data === 8'h11 && count === 2)
			else $error("test 4 false");
			
		rd_en = 1;
		wr_en = 0;
		@(posedge clk); #1;
		rd_en = 1;
		wr_en = 0;
		@(posedge clk); #1;
		assert(rd_data === 8'h33 && empty === 1)
			else $error("test 4 false (read 33)");
			
		// test 5a
		wr_en = 1; 
		wr_data = 8'h44; 
		rd_en = 1;
      		@(posedge clk); #1;
      		assert(rd_valid === 0 && count === 1 && empty === 0)
			else $error("Test 5 false empty + wr/rd");
 
		wr_en = 0;
		rd_en = 1;
      		@(posedge clk); #1;
      		assert(rd_valid === 1 && rd_data === 8'h44 && count === 0)
			else $error("Test 5 gfalse read 44");
		
		//test 5b
		for (int i = 0; i < 8; i++) begin
			wr_en = 1; wr_data = 8'hA0 + i; rd_en = 0;
			@(posedge clk); #1;
      		end
      		assert (count === 8 && full === 1)
         		else $error("Test 5b false (not full)");
 
     		wr_en = 1; wr_data = 8'h99; rd_en = 1;
      		@(posedge clk); #1;
      		assert (rd_valid === 1 && rd_data === 8'hA0 && count === 7 && full === 0)
			else $error("Test 5b false (full + wr/rd)");

		for (int i = 1; i < 8; i++) begin
         		wr_en = 0; rd_en = 1;
         		@(posedge clk); #1;
         		assert (rd_valid === 1 && rd_data === 8'hA0 + i)
				else $error("Test 5b false at %0d", i);
      		end
      		assert (count === 0 && empty === 1)
			else $error("Test 5b false (not empty)");
		
		//test 6
		for (int i = 0; i < 20; i++) begin
			for (int k = 0; k < 3; k++) begin
				wr_en = 1; 
				wr_data = 8'hB0 + i; 
				rd_en = 0;
            			@(posedge clk); #1;
         		end
         		for (int k = 0; k < 3; k++) begin
				wr_en = 0; 
				rd_en = 1;
            		@(posedge clk); #1;
            		assert (rd_valid === 1 && rd_data === 8'hB0 + i)
					else $error("Test 6 false at %0d", i);
         		end
		end
      		assert (count === 0 && empty === 1)
         		else $error("Test 6 false (end)");
		$stop;
	end
endmodule
