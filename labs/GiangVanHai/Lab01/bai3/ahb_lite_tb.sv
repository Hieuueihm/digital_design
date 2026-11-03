module ahb_lite_tb; 
	logic HCLK;
	logic HRESETn;
	logic HSEL;
	logic [31:0] HADDR;
	logic [1:0] HTRANS;
	logic HWRITE;
	logic [2:0] HSIZE;
	logic [31:0] HWDATA;
	logic HREADY;
	logic [31:0] HRDATA;
	logic HREADYOUT;
	logic HRESP;
 
	ahb_lite dut(
		.HCLK(HCLK),
		.HRESETn(HRESETn),
		.HSEL(HSEL),
		.HADDR(HADDR),
		.HTRANS(HTRANS),
		.HWRITE(HWRITE),
		.HSIZE(HSIZE),
		.HWDATA(HWDATA),
		.HREADY(HREADY),
		.HRDATA(HRDATA),
		.HREADYOUT(HREADYOUT),.HRESP(HRESP)
	);
 
	initial HCLK = 1'b0;
	always #5 HCLK = ~HCLK;
	
	task ahb_wr(input [31:0] addr, input [31:0] data, input [2:0] s = 3'b010);
		HSEL = 1; 
		HTRANS = 2'b10; 
		HADDR = addr; 
		HWRITE = 1; 
		HSIZE = s; 
		HREADY = 1;
		@(posedge HCLK); #1;
		HSEL = 0; HTRANS = 2'b00; HWDATA = data;
		@(posedge HCLK); #1;
	endtask
 
	task ahb_rd(input [31:0] addr, input [31:0] exp, input string name, input [2:0] s = 3'b010);
		HSEL = 1; HTRANS = 2'b10; HADDR = addr; HWRITE = 0; HSIZE = s; HREADY = 1;
		@(posedge HCLK); #1;
		HSEL = 0; HTRANS = 2'b00;
		#1;
		assert (HRDATA === exp && HRESP === 0 && HREADYOUT === 1)
			else $error("%0s false (HRDATA=%h exp=%h)", name, HRDATA, exp);
		@(posedge HCLK); #1;
	endtask
 
	initial begin
		HSEL = 0;
		HTRANS = 0;
		HADDR = 0;
		HWRITE = 0;
		HSIZE = 3'b010;
		HWDATA = 0;
		HREADY = 1;
		HRESETn = 0;
		#12;
		assert (HRDATA === 0 && HREADYOUT === 1 && HRESP === 0 && dut.regs[0] === 0 && dut.regs[1] === 0 && dut.regs[2] === 0 && dut.regs[3] === 0)
			else $error("test 1 false (reset)");
		HRESETn = 1;
		@(posedge HCLK); #1;
		ahb_rd(32'h0, 32'h0, "test 1 REG0");
		ahb_rd(32'h4, 32'h0, "test 1 REG1");
		ahb_rd(32'h8, 32'h0, "test 1 REG2");
		ahb_rd(32'hC, 32'h0, "test 1 REG3");
 
		ahb_wr(32'h0, 32'hA5A5_A5A5);
		ahb_rd(32'h0, 32'hA5A5_A5A5, "test 2 REG0");
 
		// test 3
		HSEL = 1; HTRANS = 2'b10; HADDR = 32'h0; HWRITE = 1; HSIZE = 3'b010; HREADY = 1;
		@(posedge HCLK); #1;
		HTRANS = 2'b11; HADDR = 32'h4; HWDATA = 32'h1111_1111;
		@(posedge HCLK); #1;
		HSEL = 0; HTRANS = 2'b00; HWDATA = 32'h2222_2222;
		@(posedge HCLK); #1;
		assert (dut.regs[0] === 32'h1111_1111 && dut.regs[1] === 32'h2222_2222)
			else $error("test 3 false");
		ahb_rd(32'h0, 32'h1111_1111, "test 3 REG0");
		ahb_rd(32'h4, 32'h2222_2222, "test 3 REG1");
 
		// test 4

		// (a) HSEL = 0, HTRANS = NONSEQ
		HSEL = 0; HTRANS = 2'b10; HADDR = 32'h8; HWRITE = 1; HSIZE = 3'b010; HREADY = 1;
		@(posedge HCLK); #1;
		HSEL = 0; HTRANS = 2'b00; HWDATA = 32'hAAAA_AAAA;
		@(posedge HCLK); #1;

		// (b) HSEL = 1, HTRANS = IDLE
		HSEL = 1; HTRANS = 2'b00; HADDR = 32'h8; HWRITE = 1; HSIZE = 3'b010; HREADY = 1;
		@(posedge HCLK); #1;
		HSEL = 0; HTRANS = 2'b00; HWDATA = 32'hBBBB_BBBB;
		@(posedge HCLK); #1;

		// (c) HSEL = 1, HTRANS = BUSY
		HSEL = 1; HTRANS = 2'b01; HADDR = 32'h8; HWRITE = 1; HSIZE = 3'b010; HREADY = 1;
		@(posedge HCLK); #1;
		HSEL = 0; HTRANS = 2'b00; HWDATA = 32'hBABA_BABA;
		@(posedge HCLK); #1;

		assert (dut.regs[2] === 32'h0000_0000)
			else $error("test 4 false (REG2 bi ghi)");
 
		// test 5a
		HSEL = 1; HTRANS = 2'b10; HADDR = 32'hC; HWRITE = 1; HSIZE = 3'b010; HREADY = 0; HWDATA = 32'hCCCC_CCCC;
		@(posedge HCLK); #1;
		@(posedge HCLK); #1;
		assert (dut.regs[3] === 0)
			else $error("test 5a false (ghi khi HREADY=0)");
		HREADY = 1;
		@(posedge HCLK); #1;
		HSEL = 0; HTRANS = 2'b00; HWDATA = 32'h3333_3333;
		@(posedge HCLK); #1;
		assert (dut.regs[3] === 32'h3333_3333)
			else $error("test 5a false (REG3)");
 
		// test 5b
		HSEL = 1; HTRANS = 2'b10; HADDR = 32'h0; HWRITE = 1; HSIZE = 3'b010; HREADY = 1;
		@(posedge HCLK); #1;
		HTRANS = 2'b11; HADDR = 32'h4; HREADY = 0; HWDATA = 32'hDDDD_DDDD;
		@(posedge HCLK); #1;
		@(posedge HCLK); #1;
		assert (dut.regs[0] === 32'h1111_1111 && dut.regs[1] === 32'h2222_2222)
			else $error("test 5b false (ghi khi HREADY=0)");
		HREADY = 1; HWDATA = 32'h5555_5555;
		@(posedge HCLK); #1;
		HSEL = 0; HTRANS = 2'b00; HWDATA = 32'h6666_6666;
		@(posedge HCLK); #1;
		assert (dut.regs[0] === 32'h5555_5555 && dut.regs[1] === 32'h6666_6666)
			else $error("test 5b false (REG0/REG1 sau khi HREADY=1)");
 
		// test 6
		ahb_wr(32'h0, 32'hFFFF_FFFF, 3'b001);
		ahb_wr(32'h0, 32'hFFFF_FFFF, 3'b011);
		ahb_wr(32'h5, 32'hFFFF_FFFF);
		ahb_wr(32'h10, 32'hFFFF_FFFF);
		ahb_wr(32'h8000_0000, 32'hFFFF_FFFF);
		ahb_rd(32'h0, 32'h5555_5555, "test 6 REG0 unchanged");
		ahb_rd(32'h4, 32'h6666_6666, "test 6 REG1 unchanged");
		ahb_rd(32'h8, 32'h0000_0000, "test 6 REG2 unchanged");
		ahb_rd(32'hC, 32'h3333_3333, "test 6 REG3 unchanged");
		
		ahb_rd(32'h0, 32'h0, "test 6 HSIZE khong hop le", 3'b001);
		ahb_rd(32'h5, 32'h0, "test 6 HADDR khong hop le");
		ahb_rd(32'h8000_0000, 32'h0, "test 6 HADDR khong hop le");
		$stop;
	end
endmodule
