`timescale 1ns/1ps
`include "iob_eth_defs.vh"

module iob_eth_tb;

   parameter clk_per = 10;
   parameter pclk_per = 40;
   
   // backend signals
   reg 			rst;
   reg 			clk;

   reg [`ETH_ADDR_W-1:0] addr;
   reg 			 sel;
   reg 			 we;
   reg [31:0]            data_in;
   wire [31:0]           data_out;
   wire                  interrupt;

   // frontend signals
   wire                  GTX_CLK;
   wire                  ETH_RESETN;
   
   wire                  TX_CLK;   
   wire [3:0]            TX_DATA;
   wire                  TX_EN;
   
   reg                   RX_CLK;
   wire [3:0]            RX_DATA;
   reg                   RX_DV;
   
   //iterator
   integer               i;

   // data vector
   reg [`ETH_DATA_W-1:0] data[`ETH_TEST_SIZE-1:0];
   
   // Instantiate the Unit Under Test (UUT)
   
   iob_eth uut (
		.clk			(clk),
		.rst			(rst),

		// frontend 		
		.sel			(sel),
		.we			(we),
		.addr			(addr[`ETH_ADDR_W-1:0]),
		.data_in		(data_in[`ETH_MAC_ADDR_W/2-1:0]),
		.data_out		(data_out[`ETH_MAC_ADDR_W/2-1:0]),
		.interrupt		(interrupt),

		// phy backend
		.GTX_CLK		(GTX_CLK),
		.ETH_RESETN		(ETH_RESETN),
		
		.TX_CLK			(TX_CLK),
		.TX_DATA		(TX_DATA[3:0]),
		.TX_EN			(TX_EN),
		
		.RX_CLK			(RX_CLK),
		.RX_DATA		(RX_DATA[3:0]),
		.RX_DV			(RX_DV)
		);

   
   // loop back through PHY
   always @(TX_EN) 
     RX_DV <=  #(14*pclk_per) TX_EN;   
   
   //assign RX_DATA = TX_DATA;

   initial begin
   
`ifdef DEBUG
      $dumpfile("iob_eth.vcd");
      $dumpvars;
`endif

      // generate test data
      for(i=0; i < `ETH_TEST_SIZE; i= i+1)
	data[i]  = i+1;
	//data[i]  = $random;
 
      rst = 1;
      clk = 1;
      RX_CLK = 1;
      RX_DV = 0;
      we = 0;
      sel = 1;

      // deassert reset
      #100 @(posedge clk) rst = 0;
      
	
      // wait until tx ready
      #(clk_per) addr = `ETH_STATUS;
      while(~data_out[0])
	#(clk_per);

      
      // write number of bytes to transmit
      #(clk_per) addr = `ETH_TX_NBYTES;
      we = 1;
      data_in = `ETH_TEST_SIZE;
 
      // write data to send
      for(i=0; i < `ETH_TEST_SIZE; i= i+1) begin
	 #(clk_per) addr = `ETH_TX_DATA + i;
	 data_in = data[i];
     end

      // start sending
      #(clk_per) addr = `ETH_CONTROL;
      data_in = 1;
            
      #(clk_per) we = 0;

      
      // wait until rx ready
      #(10*clk_per) addr = `ETH_STATUS;
      while(~data_out[1])
	#(clk_per);

      $display("Got here");

      // read and check received data
      for(i=0; i < `ETH_TEST_SIZE; i= i+1) begin
	 addr = `ETH_RX_DATA + i;
	 #(clk_per) if (data_out != data[i]) begin 
	    $display("Test failed on vector %d", i);
	    $finish;
	 end
      end

      $display("Test passed!");
      $finish;

   end // initial begin
         
   //
   // CLOCKS 
   //
   
   //system clock
   always #(clk_per/2) clk = ~clk;

   //rx clock 
   always #(pclk_per/2) RX_CLK = ~RX_CLK;

   //tx clock
   assign TX_CLK = ~RX_CLK;

endmodule
