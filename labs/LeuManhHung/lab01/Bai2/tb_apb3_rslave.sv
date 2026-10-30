`timescale 1ns/1ps 
module tb_apb3_rslave;
	logic PCLK;
	logic PRESETn;
	logic PSEL;
	logic PENABLE;
	logic PWRITE;
	logic [7:0] PADDR; // dia chi
	logic [31:0] PWDATA;// ghi
	logic [31:0] PRDATA; // doc
	logic PREADY; // giao dich done
	logic PSLVERR; // bao loi dia chi
apb3_rslave dut (
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
always #5
PCLK = ~ PCLK;
initial begin
	PCLK = 1'b0;
	PRESETn = 1'b0;
	PWRITE = 1'b0;
	PSEL = 1'b0;
	PENABLE = 1'b0;
	PADDR = 8'h0;
	PWDATA = 0;
	PRDATA = 0;
	PREADY = 1'b1;
	#20;
	PRESETn = 1'b1;
	#10;
	// test 1
	@(posedge PCLK); // doc CONTROL 
		PSEL = 1'b1;
		PENABLE = 0;
		PWRITE = 0;
		PADDR = 8'h00;
	@(posedge PCLK);
		PENABLE = 1;
	@(posedge PCLK);
		PSEL = 0;
		PENABLE = 0;
		$display("PRDATA = 0x%h", PRDATA); // in ra gia tri
		#10;
	@(posedge PCLK); // doc DATA 
		PSEL = 1'b1;
		PENABLE = 0;
		PWRITE = 0;
		PADDR = 8'h04;
	@(posedge PCLK);
		PENABLE = 1;
	@(posedge PCLK);
		PSEL = 0;
		PENABLE = 0;
		$display("PRDATA = 0x%h", PRDATA);
	#10;
	@(posedge PCLK); // doc STATUS 
		PSEL = 1'b1;
		PENABLE = 0;
		PWRITE = 0;
		PADDR = 8'h08;
	@(posedge PCLK);
		PENABLE = 1;
	@(posedge PCLK);
		PSEL = 0;
		PENABLE = 0 ;
		$display("PRDATA = 0x%h", PRDATA);
	#10;
	// Test 2:
	@(posedge PCLK); // Ghi control =1
		PSEL = 1 ;
		PENABLE = 0;
		PWRITE = 1;
		PADDR = 8'h00;
		PWDATA  = {31'b0,1'b1};
	@(posedge PCLK);
		PENABLE =1;
	@(posedge PCLK);
		PSEL = 0;
		PENABLE = 0;
		#10;
	@(posedge PCLK); // Doc control =1
		PSEL = 1;
		PENABLE = 0;
		PWRITE = 0;
		PADDR = 8'h00;
	@(posedge PCLK);
		PENABLE = 1 ;
	@(posedge PCLK)
		PSEL = 0;
		PENABLE = 0;
		$display("PRDATA = 0x%h", PRDATA);
		#10;
	@(posedge PCLK); // Doc status =3
		PSEL = 1;
		PENABLE = 0;
		PWRITE = 0;
		PADDR = 8'h08;
	@(posedge PCLK);
		PENABLE = 1 ;
	@(posedge PCLK)
		PSEL = 0;
		PENABLE = 0;
		$display("PRDATA = 0x%h", PRDATA);
		#10;
	// Test 3: Ghi Data roi doc
	@(posedge PCLK); // Ghi DATA=0xDEADBEEF
		PSEL = 1 ;
		PENABLE = 0;
		PWRITE = 1;
		PADDR = 8'h04;
		PWDATA  = 32'hDEADBEEF;
	@(posedge PCLK);
		PENABLE =1;
	@(posedge PCLK);
		PSEL = 0;
		PENABLE = 0;
		#10;
	@(posedge PCLK); // Doc data
		PSEL = 1;
		PENABLE = 0;
		PWRITE = 0;
	@(posedge PCLK);
		PENABLE = 1 ;
	@(posedge PCLK)
		PSEL = 0;
		PENABLE = 0;
		$display("PRDATA = 0x%h", PRDATA);
		#10;
	// Test 4: // Ghi, xong cho PSLVERR=1
	@(posedge PCLK); // Ghi DATA= 32'hABCDEFAB
		PSEL = 1 ;
		PENABLE = 0;
		PWRITE = 1;
		PADDR = 8'h04;
		PWDATA  = 32'hABCDEFAB;
		PSLVERR = 1;
	@(posedge PCLK);
		PENABLE =1;
	@(posedge PCLK);
		PSEL = 0;
		PENABLE = 0;
		PSLVERR = 0;
		$display("PRDATA = 0x%h", PRDATA);
		#10;
	// Test 5: Dia chi sai
	@(posedge PCLK); // Ghi
		PSEL = 1 ;
		PENABLE = 0;
		PWRITE = 1;
		PADDR = 8'h0C;
	@(posedge PCLK);
		PENABLE =1;
	@(posedge PCLK);
		PSEL = 0;
		PENABLE = 0;
		$display("PSLVERR = %b", PSLVERR);		
		#10;
	@(posedge PCLK); // Doc data
		PSEL = 1;
		PENABLE = 0;
		PWRITE = 0;
		PADDR = 8'h01;
	@(posedge PCLK);
		PENABLE = 1 ;
	@(posedge PCLK);
		PSEL = 0;
		PENABLE = 0;
		$display("PSLVERR = %b", PSLVERR);
		#10;
	// Test 6: Chi setup ko access
	// Update: Thanh data dang la: 0xDEADBEEF
	// Se setup cho thanh ghi data 1 gia tri nhung se in ra gia tri cu
	@(posedge PCLK); // trang thai setup, 
		PSEL = 1 ;
		PENABLE = 0;
		PWRITE = 1;
		PADDR = 8'h04;
		PWDATA  = 32'hACBDEFAB;
	@(posedge PCLK);
		PSEL = 0;
		PENABLE = 0;
		$display("PRDATA = 0x%h", PRDATA);
		#10;
	$finish;
	end
endmodule
		
		
		
	
		
		
	
	
	
	
	
	
	
		
		
	
		
		
	
	
	
	
	
	
	
	
	
	
	



		
		
	
	
	




