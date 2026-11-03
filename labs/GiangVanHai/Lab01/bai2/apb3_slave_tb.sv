module apb3_slave_tb;
	logic PCLK;
	logic PRESETn;
	logic PSEL;
	logic PENABLE;
	logic PWRITE;
	logic [7:0] PADDR;
	logic [31:0] PWDATA;
	logic [31:0] PRDATA;
	logic PREADY;
	logic PSLVERR;
	
	apb3_slave dut(
		.PCLK(PCLK),
		.PRESETn(PRESETn),
		.PSEL(PSEL),
		.PENABLE(PENABLE),
		.PWRITE(PWRITE), 
		.PADDR(PADDR), 
		.PWDATA(PWDATA),
		.PRDATA(PRDATA),
		.PREADY(PREADY),
		.PSLVERR(PSLVERR)
	);
	
	initial PCLK = 1'b0;
	always #5 PCLK = ~PCLK;
	
	task apb_wr(input [7:0] paddr, input [31:0] pwdata, input pslverr, input string name);
		PSEL = 1; 
		PENABLE = 0; 
		PWRITE = 1; 
		PADDR = paddr; 
		PWDATA = pwdata;
		@(posedge PCLK); #1;
		PENABLE = 1; #1;
		assert (PSLVERR === pslverr) 
			else $error("%0s false (PSLVERR)", name);
		@(posedge PCLK); #1;
		PSEL = 0;
		PENABLE = 0;
		PWRITE = 0;
	endtask
	
	task apb_rd(input [7:0] paddr, input [31:0] prdata, input pslverr, input string name);
		PSEL = 1;
		PENABLE = 0;
		PWRITE = 0;
		PADDR = paddr;
		@(posedge PCLK); #1;
		PENABLE = 1; #1;
		assert (PRDATA === prdata && PSLVERR === pslverr)
			else $error("%0s false (PRDATA=%h PSLVERR=%b)", name, PRDATA, PSLVERR);
		@(posedge PCLK); #1;
		PSEL = 0;
		PENABLE = 0;
	endtask
 
	initial begin
		PSEL = 0; PENABLE = 0; PWRITE = 0; PADDR = 0; PWDATA = 0;
		
		//test 1
		PRESETn = 0;
		#12;
		assert (PREADY === 1 && PRDATA === 0 && PSLVERR === 0 && dut.control_0 === 0 && dut.data === 0)
			else $error("test 1 false (reset)");
		PRESETn = 1;
		@(posedge PCLK); #1;
		apb_rd(8'h00, 32'h0, 0, "test 1 CONTROL");
		apb_rd(8'h04, 32'h0, 0, "test 1 DATA");
		apb_rd(8'h08, 32'h1, 0, "test 1 STATUS");
		
		//test 2
		apb_wr(8'h00, 32'h1, 0, "test 2 write");
		apb_rd(8'h00, 32'h1, 0, "test 2 CONTROL");
		apb_rd(8'h08, 32'h3, 0, "test 2 STATUS");
		
		apb_wr(8'h00, 32'hFFFFFFFE, 0, "test 2 write bit0=0");
		apb_rd(8'h00, 32'h0, 0, "test 2 CONTROL bit0");
 
		// test 3
		apb_wr(8'h04, 32'hDEADBEEF, 0, "test 3 write");
		apb_rd(8'h04, 32'hDEADBEEF, 0, "test 3 DATA");
 
		// test 4
		apb_wr(8'h08, 32'hFFFFFFFF, 1, "test 4 write STATUS");
		apb_rd(8'h08, 32'h1, 0, "test 4 STATUS unchanged");
		apb_rd(8'h04, 32'hDEADBEEF, 0, "test 4 DATA unchanged");
 
		//test 5
		apb_rd(8'h0C, 32'h0, 1, "test 5 read 0x0C");
		apb_rd(8'h01, 32'h0, 1, "test 5 read 0x01");
		apb_wr(8'h0C, 32'h1234, 1, "test 5 write 0x0C");
		apb_wr(8'h01, 32'h1234, 1, "test 5 write 0x01");
		
		//test 6
		PSEL = 1;
		PENABLE = 0;
		PWRITE = 1;
		PADDR = 8'h04;
		PWDATA = 32'hAAAAAAAA;
		#1;
		assert (PSLVERR === 0 && PRDATA === 0) 
			else $error("test 6 false (SETUP)");
		@(posedge PCLK); #1;
		PSEL = 0;
		PENABLE = 0;
		PWRITE = 0;
		@(posedge PCLK); #1;
		apb_rd(8'h04, 32'hDEAD_BEEF, 0, "test 6 DATA unchanged");
		$stop;
	end
endmodule