`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/20/2014 10:35:44 AM
// Design Name: 
// Module Name: memcached_flash_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mcdDsBinPCIe
#(parameter DRAM_WIDTH = 512,
  parameter FLASH_WIDTH = 64,
 // parameter DRAM_CMD_WIDTH = 24,
  parameter DRAM_CMD_WIDTH = 40,
  parameter FLASH_CMD_WIDTH	= 48)
(
input clk,
input aresetn,
input [183:0] udp_in_data,
output udp_in_ready,
input udp_in_valid,

output[183:0]  udp_out_data,
input udp_out_ready,
output udp_out_valid,

//stats signals
input [31:0] stats0,
input [31:0] stats1,

//pcie interface
input  [31: 0] pcie_axi_AWADDR,
input  pcie_axi_AWVALID,
output pcie_axi_AWREADY,

//data write
input  [31: 0]   pcie_axi_WDATA,
input  [3: 0] pcie_axi_WSTRB,
input  pcie_axi_WVALID,
output pcie_axi_WREADY,

//write response (handhake)
output [1:0] pcie_axi_BRESP,
output pcie_axi_BVALID,
input  pcie_axi_BREADY,

//address read
input  [31: 0] pcie_axi_ARADDR,
input  pcie_axi_ARVALID,
output pcie_axi_ARREADY,

//data read
output [31: 0] pcie_axi_RDATA,
output [1:0] pcie_axi_RRESP,
output pcie_axi_RVALID,
input  pcie_axi_RREADY,
input pcieClk,
input pcie_user_lnk_up,

//signals to/from sata_gth
input clk150,
input gth_reset,
output         hard_reset,     // Active high, reset button pushed on board
output         soft_reset,     // Active high, user reset can be pulled any time
//gth outputs
 // RX GTH tile <-> Link Module
input           RXELECIDLE0,
input [3:0]     RXCHARISK0,
input [31:0]    RXDATA,
input           RXBYTEISALIGNED0,
input          gt0_rxbyterealign_out,
input          gt0_rxcommadet_out,

 // TX GTH tile <-> Link Module
output           TXELECIDLE,
output [31:0]    TXDATA,
output           TXCHARISK,
      
input rx_reset_done, 
input tx_reset_done,
input rx_comwake_det,
input rx_cominit_det,
output tx_cominit, 
output tx_comwake,
output rx_start,
output link_initialized_clk156,
output ncq_idle_clk156,
output fin_read_sig_clk156,
//signals to DRAM memory interface
//ht stream interface signals
output           ht_s_axis_read_cmd_tvalid,
input          ht_s_axis_read_cmd_tready,
output[71:0]     ht_s_axis_read_cmd_tdata,
//read status
input          ht_m_axis_read_sts_tvalid,
output           ht_m_axis_read_sts_tready,
input[7:0]     ht_m_axis_read_sts_tdata,
//read stream
input[511:0]    ht_m_axis_read_tdata,
input[63:0]     ht_m_axis_read_tkeep,
input          ht_m_axis_read_tlast,
input          ht_m_axis_read_tvalid,
output           ht_m_axis_read_tready,

//write commands
output           ht_s_axis_write_cmd_tvalid,
input          ht_s_axis_write_cmd_tready,
output[71:0]     ht_s_axis_write_cmd_tdata,
//write status
input          ht_m_axis_write_sts_tvalid,
output           ht_m_axis_write_sts_tready,
input[7:0]     ht_m_axis_write_sts_tdata,
//write stream
output[511:0]     ht_s_axis_write_tdata,
output[63:0]      ht_s_axis_write_tkeep,
output           ht_s_axis_write_tlast,
output           ht_s_axis_write_tvalid,
input          ht_s_axis_write_tready,

//vs stream interface signals
output           vs_s_axis_read_cmd_tvalid,
input          vs_s_axis_read_cmd_tready,
output[71:0]     vs_s_axis_read_cmd_tdata,
//read status
input          vs_m_axis_read_sts_tvalid,
output           vs_m_axis_read_sts_tready,
input[7:0]     vs_m_axis_read_sts_tdata,
//read stream
input[511:0]    vs_m_axis_read_tdata,
input[63:0]     vs_m_axis_read_tkeep,
input          vs_m_axis_read_tlast,
input          vs_m_axis_read_tvalid,
output           vs_m_axis_read_tready,

//write commands
output           vs_s_axis_write_cmd_tvalid,
input          vs_s_axis_write_cmd_tready,
output[71:0]     vs_s_axis_write_cmd_tdata,
//write status
input          vs_m_axis_write_sts_tvalid,
output           vs_m_axis_write_sts_tready,
input[7:0]     vs_m_axis_write_sts_tdata,
//write stream
output[511:0]     vs_s_axis_write_tdata,
output[63:0]      vs_s_axis_write_tkeep,
output            vs_s_axis_write_tlast,
output            vs_s_axis_write_tvalid,
input           vs_s_axis_write_tready
);

//DRAM model connections
wire[DRAM_WIDTH-1: 0]  ht_dramRdData_data;
wire  ht_dramRdData_valid;
wire  ht_dramRdData_ready;
// ht_cmd_dramRdData: Push Output, 16b
wire[DRAM_CMD_WIDTH-1:0]  ht_cmd_dramRdData_data;
wire  ht_cmd_dramRdData_valid;
wire  ht_cmd_dramRdData_ready;
// ht_dramWrData:     Push Output, 512b
wire[DRAM_WIDTH-1:0]  ht_dramWrData_data;
wire  ht_dramWrData_valid;
wire  ht_dramWrData_ready;
// ht_cmd_dramWrData: Push Output, 16b
wire[DRAM_CMD_WIDTH-1:0]  ht_cmd_dramWrData_data;
wire  ht_cmd_dramWrData_valid;
wire  ht_cmd_dramWrData_ready;

// upd_cmd_dramRdData: Push Output, 16b
wire[DRAM_CMD_WIDTH-1:0]  upd_cmd_dramRdData_data;
wire  upd_cmd_dramRdData_valid;
wire  upd_cmd_dramRdData_ready;
// upd_cmd_dramWrData: Push Output, 16b
wire[DRAM_CMD_WIDTH-1:0]  upd_cmd_dramWrData_data;
wire  upd_cmd_dramWrData_valid;
wire  upd_cmd_dramWrData_ready;
// Update Flash Connection
// upd_flashRdData:     Pull Input, 64b
wire[FLASH_WIDTH-1:0]  upd_flashRdData_data;
wire  upd_flashRdData_valid;
wire  upd_flashRdData_ready;
// upd_cmd_flashRdData: Push Output, 48b
wire[FLASH_CMD_WIDTH-1:0]  upd_cmd_flashRdData_data;
wire  upd_cmd_flashRdData_valid;
wire  upd_cmd_flashRdData_ready;
// upd_flashWrData:     Push Output, 64b
wire[FLASH_WIDTH-1:0]  upd_flashWrData_data;
wire  upd_flashWrData_valid;
wire  upd_flashWrData_ready;
// upd_cmd_flashWrData: Push Output, 48b
wire[FLASH_CMD_WIDTH-1:0]  upd_cmd_flashWrData_data;
wire  upd_cmd_flashWrData_valid;
wire  upd_cmd_flashWrData_ready;

//dram memory path
wire dramValueStoreMemRdCmd_V_TVALID;
wire [DRAM_CMD_WIDTH-1:0] dramValueStoreMemRdCmd_V_TDATA;
wire dramValueStoreMemRdCmd_V_TREADY;
wire dramValueStoreMemRdData_V_V_TVALID;
wire [511:0] dramValueStoreMemRdData_V_V_TDATA;
wire dramValueStoreMemRdData_V_V_TREADY;
wire dramValueStoreMemWrCmd_V_TVALID;
wire [DRAM_CMD_WIDTH-1:0] dramValueStoreMemWrCmd_V_TDATA;
wire dramValueStoreMemWrCmd_V_TREADY;
wire dramValueStoreMemWrData_V_V_TVALID;
wire [511:0] dramValueStoreMemWrData_V_V_TDATA;
wire dramValueStoreMemWrData_V_V_TREADY;


//////////////////Memory Allocation Signals//////////////////////////////////////////-
wire[31:0] memcached2memAllocation_data;	// Address reclamation
wire memcached2memAllocation_valid;
wire memcached2memAllocation_ready;
wire[31:0] memAllocation2memcached_dram_data;	// Address assignment for DRAM
wire memAllocation2memcached_dram_valid;
wire memAllocation2memcached_dram_ready;
wire[31:0] memAllocation2memcached_flash_data;	// Address assignment for SSD
wire memAllocation2memcached_flash_valid;
wire memAllocation2memcached_flash_ready;

//flush related signals
wire flushReq_V;
wire flushAck_V;
wire flushDone_V;

readconverter_top ht_dram_read_converter(
    .dmRdCmd_V_TVALID(ht_s_axis_read_cmd_tvalid),
    .dmRdCmd_V_TREADY(ht_s_axis_read_cmd_tready),
    .dmRdCmd_V_TDATA(ht_s_axis_read_cmd_tdata),
    .dmRdData_V_TVALID(ht_m_axis_read_tvalid),
    .dmRdData_V_TREADY(ht_m_axis_read_tready),
    .dmRdData_V_TDATA(ht_m_axis_read_tdata),
    .dmRdData_V_TKEEP(ht_m_axis_read_tkeep),
    .dmRdData_V_TLAST(ht_m_axis_read_tlast),
    .dmRdStatus_V_V_TVALID(ht_m_axis_read_sts_tvalid),
    .dmRdStatus_V_V_TREADY(ht_m_axis_read_sts_tready),
    .dmRdStatus_V_V_TDATA(ht_m_axis_read_sts_tdata),
    .memRdCmd_V_TVALID(ht_cmd_dramRdData_valid),
    .memRdCmd_V_TREADY(ht_cmd_dramRdData_ready),
    .memRdCmd_V_TDATA(ht_cmd_dramRdData_data),
    .memRdData_V_V_TVALID(ht_dramRdData_valid),
    .memRdData_V_V_TREADY(ht_dramRdData_ready),
    .memRdData_V_V_TDATA(ht_dramRdData_data),
    .aresetn(aresetn),
    .aclk(clk)
);

writeconverter_top ht_dram_write_converter(
    .dmWrCmd_V_TVALID(ht_s_axis_write_cmd_tvalid),
    .dmWrCmd_V_TREADY(ht_s_axis_write_cmd_tready),
    .dmWrCmd_V_TDATA(ht_s_axis_write_cmd_tdata),
    .dmWrData_V_TVALID(ht_s_axis_write_tvalid),
    .dmWrData_V_TREADY(ht_s_axis_write_tready),
    .dmWrData_V_TDATA(ht_s_axis_write_tdata),
    .dmWrData_V_TKEEP(ht_s_axis_write_tkeep),
    .dmWrData_V_TLAST(ht_s_axis_write_tlast),
    .dmWrStatus_V_V_TVALID(ht_m_axis_write_sts_tvalid),
    .dmWrStatus_V_V_TREADY(ht_m_axis_write_sts_tready),
    .dmWrStatus_V_V_TDATA(ht_m_axis_write_sts_tdata),
    .memWrCmd_V_TVALID(ht_cmd_dramWrData_valid),
    .memWrCmd_V_TREADY(ht_cmd_dramWrData_ready),
    .memWrCmd_V_TDATA(ht_cmd_dramWrData_data),
    .memWrData_V_V_TVALID(ht_dramWrData_valid),
    .memWrData_V_V_TREADY(ht_dramWrData_ready),
    .memWrData_V_V_TDATA(ht_dramWrData_data),
    .aresetn(aresetn),
    .aclk(clk)
);


readconverter_top vs_dram_read_converter(
    .dmRdCmd_V_TVALID(vs_s_axis_read_cmd_tvalid),
    .dmRdCmd_V_TREADY(vs_s_axis_read_cmd_tready),
    .dmRdCmd_V_TDATA(vs_s_axis_read_cmd_tdata),
    .dmRdData_V_TVALID(vs_m_axis_read_tvalid),
    .dmRdData_V_TREADY(vs_m_axis_read_tready),
    .dmRdData_V_TDATA(vs_m_axis_read_tdata),
    .dmRdData_V_TKEEP(vs_m_axis_read_tkeep),
    .dmRdData_V_TLAST(vs_m_axis_read_tlast),
    .dmRdStatus_V_V_TVALID(vs_m_axis_read_sts_tvalid),
    .dmRdStatus_V_V_TREADY(vs_m_axis_read_sts_tready),
    .dmRdStatus_V_V_TDATA(vs_m_axis_read_sts_tdata),
    .memRdCmd_V_TVALID(dramValueStoreMemRdCmd_V_TVALID),
    .memRdCmd_V_TREADY(dramValueStoreMemRdCmd_V_TREADY),
    .memRdCmd_V_TDATA(dramValueStoreMemRdCmd_V_TDATA),
    .memRdData_V_V_TVALID(dramValueStoreMemRdData_V_V_TVALID),
    .memRdData_V_V_TREADY(dramValueStoreMemRdData_V_V_TREADY),
    .memRdData_V_V_TDATA(dramValueStoreMemRdData_V_V_TDATA),
    .aresetn(aresetn),
    .aclk(clk)
);
writeconverter_top vs_dram_write_converter(
    .dmWrCmd_V_TVALID(vs_s_axis_write_cmd_tvalid),
    .dmWrCmd_V_TREADY(vs_s_axis_write_cmd_tready),
    .dmWrCmd_V_TDATA(vs_s_axis_write_cmd_tdata),
    .dmWrData_V_TVALID(vs_s_axis_write_tvalid),
    .dmWrData_V_TREADY(vs_s_axis_write_tready),
    .dmWrData_V_TDATA(vs_s_axis_write_tdata),
    .dmWrData_V_TKEEP(vs_s_axis_write_tkeep),
    .dmWrData_V_TLAST(vs_s_axis_write_tlast),
    .dmWrStatus_V_V_TVALID(vs_m_axis_write_sts_tvalid),
    .dmWrStatus_V_V_TREADY(vs_m_axis_write_sts_tready),
    .dmWrStatus_V_V_TDATA(vs_m_axis_write_sts_tdata),
    .memWrCmd_V_TVALID(dramValueStoreMemWrCmd_V_TVALID),
    .memWrCmd_V_TREADY(dramValueStoreMemWrCmd_V_TREADY),
    .memWrCmd_V_TDATA(dramValueStoreMemWrCmd_V_TDATA),
    .memWrData_V_V_TVALID(dramValueStoreMemWrData_V_V_TVALID),
    .memWrData_V_V_TREADY(dramValueStoreMemWrData_V_V_TREADY),
    .memWrData_V_V_TDATA(dramValueStoreMemWrData_V_V_TDATA),
    .aresetn(aresetn),
    .aclk(clk)
);

//Update Table DRAM model instantiation
ssd_mem_node flashVS(
                .clk156(clk),
   	            .nReset156(aresetn),
  	            .clk156_dramRdData_valid(upd_flashRdData_valid),
   	            .clk156_dramRdData_ready(upd_flashRdData_ready),
   	            .clk156_dramRdData_data(upd_flashRdData_data),
   	            //ht_cmd_dramRdData: Push Output, 48b
   	            .clk156_cmd_dramRdData_data(upd_cmd_flashRdData_data[44:0]),
   	            .clk156_cmd_dramRdData_valid(upd_cmd_flashRdData_valid),
   	            .clk156_cmd_dramRdData_ready(upd_cmd_flashRdData_ready),
   	            //ht_dramWrData:     Push Output, 64b
   	            .clk156_dramWrData_data(upd_flashWrData_data),
   	            .clk156_dramWrData_valid(upd_flashWrData_valid),
   	            .clk156_dramWrData_ready(upd_flashWrData_ready),
   	            //ht_cmd_dramWrData: Push Output, 48b
   	            .clk156_cmd_dramWrData_data(upd_cmd_flashWrData_data[44:0]),
   	            .clk156_cmd_dramWrData_valid(upd_cmd_flashWrData_valid),
   	            .clk156_cmd_dramWrData_ready(upd_cmd_flashWrData_ready),
   	            .link_initialized_clk156(link_initialized_clk156),
                .ncq_idle_clk156(ncq_idle_clk156),
                .fin_read_sig_clk156(fin_read_sig_clk156),
                .clk150(clk150),
                .gth_reset(gth_reset),
                .hard_reset(hard_reset),     // Active high, reset button pushed on board
                .soft_reset(soft_reset),     // Active high, user reset can be pulled any time
                        //gth outputs
                         // RX GTH tile <-> Link Module
                .RXELECIDLE0(RXELECIDLE0),
                .RXCHARISK0(RXCHARISK0),
                .RXDATA(RXDATA),
                .RXBYTEISALIGNED0(RXBYTEISALIGNED0),
                .gt0_rxbyterealign_out(gt0_rxbyterealign_out),
                .gt0_rxcommadet_out(gt0_rxcommadet_out),
                        
                         // TX GTH tile <-> Link Module
                 .TXELECIDLE(TXELECIDLE),
                 .TXDATA(TXDATA),
                 .TXCHARISK(TXCHARISK),
                              
                 .rx_reset_done(rx_reset_done), 
                 .tx_reset_done(tx_reset_done),
                 .rx_comwake_det(rx_comwake_det),
                 .rx_cominit_det(rx_cominit_det),
                 .tx_cominit(tx_cominit),
                 .tx_comwake(tx_comwake),
                 .rx_start(rx_start)
);

//pciE instantiation
pcie_mem_alloc #(.REVISION(32'h12000006)) pcie_mem_alloc_inst  (
    .ACLK(clk),
    .Axi_resetn(aresetn),
    
    .stats0_data (stats0),
    .stats1_data (stats1),
    .stats2_data (32'h0),
    .stats3_data (32'h0),
    
    .pcie_axi_AWADDR(pcie_axi_AWADDR),
    .pcie_axi_AWVALID(pcie_axi_AWVALID),
    .pcie_axi_AWREADY(pcie_axi_AWREADY),
       
    .pcie_axi_WDATA(pcie_axi_WDATA),
    .pcie_axi_WSTRB(pcie_axi_WSTRB),
    .pcie_axi_WVALID(pcie_axi_WVALID),
    .pcie_axi_WREADY(pcie_axi_WREADY),
       
    .pcie_axi_BRESP(pcie_axi_BRESP),
    .pcie_axi_BVALID(pcie_axi_BVALID),
    .pcie_axi_BREADY(pcie_axi_BREADY),
       
    .pcie_axi_ARADDR(pcie_axi_ARADDR),
    .pcie_axi_ARVALID(pcie_axi_ARVALID),
    .pcie_axi_ARREADY(pcie_axi_ARREADY),
       
    .pcie_axi_RDATA(pcie_axi_RDATA),
    .pcie_axi_RRESP(pcie_axi_RRESP),
    .pcie_axi_RVALID(pcie_axi_RVALID),
    .pcie_axi_RREADY(pcie_axi_RREADY),
    .pcieClk(pcieClk),
    .pcie_user_lnk_up(pcie_user_lnk_up),
   
    .memcached2memAllocation_data(memcached2memAllocation_data),	// Address reclamation axis input 32
    .memcached2memAllocation_valid(memcached2memAllocation_valid),
    .memcached2memAllocation_ready(memcached2memAllocation_ready),
    
    .memAllocation2memcached_dram_data(memAllocation2memcached_dram_data),	// Address assignment for DRAM axis output 32
    .memAllocation2memcached_dram_valid(memAllocation2memcached_dram_valid),
    .memAllocation2memcached_dram_ready(memAllocation2memcached_dram_ready),
    
    .memAllocation2memcached_flash_data(memAllocation2memcached_flash_data),	// Address assignment for SSD axis output 32
    .memAllocation2memcached_flash_valid(memAllocation2memcached_flash_valid),
    .memAllocation2memcached_flash_ready(memAllocation2memcached_flash_ready),
    
    .flushReq(flushReq_V),                                                    
    .flushAck(flushAck_V),                                                    
    .flushDone(flushDone_V)                                              
    );

					
//memcached Pipeline Instantiation
//memcached_bin_flash_ip  myMemcachedPipeline (
memcachedPipeline myMemcachedPipeline(//use the one from synplify
                .hashTableMemRdCmd_V_TVALID(ht_cmd_dramRdData_valid),
				.hashTableMemRdCmd_V_TREADY(ht_cmd_dramRdData_ready),
				.hashTableMemRdCmd_V_TDATA(ht_cmd_dramRdData_data),
				.hashTableMemRdData_V_V_TVALID(ht_dramRdData_valid),
				.hashTableMemRdData_V_V_TREADY(ht_dramRdData_ready),
				.hashTableMemRdData_V_V_TDATA(ht_dramRdData_data),
				.hashTableMemWrCmd_V_TVALID(ht_cmd_dramWrData_valid),
				.hashTableMemWrCmd_V_TREADY(ht_cmd_dramWrData_ready),
				.hashTableMemWrCmd_V_TDATA(ht_cmd_dramWrData_data),
				.hashTableMemWrData_V_V_TVALID(ht_dramWrData_valid),
				.hashTableMemWrData_V_V_TREADY(ht_dramWrData_ready),
				.hashTableMemWrData_V_V_TDATA(ht_dramWrData_data),
				.inData_TVALID(udp_in_valid),
				.inData_TREADY(udp_in_ready),
				.inData_TDATA(udp_in_data),
				.outData_TVALID(udp_out_valid),
				.outData_TREADY(udp_out_ready),
				.outData_TDATA(udp_out_data),
				.flashValueStoreMemRdCmd_V_TVALID(upd_cmd_flashRdData_valid),
				.flashValueStoreMemRdCmd_V_TREADY(upd_cmd_flashRdData_ready),
				.flashValueStoreMemRdCmd_V_TDATA(upd_cmd_flashRdData_data),
				.flashValueStoreMemRdData_V_V_TVALID(upd_flashRdData_valid),
				.flashValueStoreMemRdData_V_V_TREADY(upd_flashRdData_ready),
				.flashValueStoreMemRdData_V_V_TDATA(upd_flashRdData_data),
				.flashValueStoreMemWrCmd_V_TVALID(upd_cmd_flashWrData_valid),
				.flashValueStoreMemWrCmd_V_TREADY(upd_cmd_flashWrData_ready),
				.flashValueStoreMemWrCmd_V_TDATA(upd_cmd_flashWrData_data),
				.flashValueStoreMemWrData_V_V_TVALID(upd_flashWrData_valid),
				.flashValueStoreMemWrData_V_V_TREADY(upd_flashWrData_ready),
				.flashValueStoreMemWrData_V_V_TDATA (upd_flashWrData_data),
				.addressReturnOut_V_V_TDATA(memcached2memAllocation_data),
				.addressReturnOut_V_V_TVALID(memcached2memAllocation_valid),
				.addressReturnOut_V_V_TREADY(memcached2memAllocation_ready),
				.addressAssignDramIn_V_V_TDATA(memAllocation2memcached_dram_data),
				.addressAssignDramIn_V_V_TVALID(memAllocation2memcached_dram_valid),
				.addressAssignDramIn_V_V_TREADY(memAllocation2memcached_dram_ready),
				.addressAssignFlashIn_V_V_TDATA(memAllocation2memcached_flash_data),
				.addressAssignFlashIn_V_V_TVALID(memAllocation2memcached_flash_valid),
				.addressAssignFlashIn_V_V_TREADY(memAllocation2memcached_flash_ready),
				.ap_rst_n(aresetn),
				.ap_clk(clk),
				.dramValueStoreMemRdCmd_V_TVALID(dramValueStoreMemRdCmd_V_TVALID),
                .dramValueStoreMemRdCmd_V_TDATA(dramValueStoreMemRdCmd_V_TDATA),
                .dramValueStoreMemRdCmd_V_TREADY(dramValueStoreMemRdCmd_V_TREADY),
                .dramValueStoreMemRdData_V_V_TVALID(dramValueStoreMemRdData_V_V_TVALID),
                .dramValueStoreMemRdData_V_V_TDATA(dramValueStoreMemRdData_V_V_TDATA),
                .dramValueStoreMemRdData_V_V_TREADY(dramValueStoreMemRdData_V_V_TREADY),
                .dramValueStoreMemWrCmd_V_TVALID(dramValueStoreMemWrCmd_V_TVALID),
                .dramValueStoreMemWrCmd_V_TDATA(dramValueStoreMemWrCmd_V_TDATA),
                .dramValueStoreMemWrCmd_V_TREADY(dramValueStoreMemWrCmd_V_TREADY),
                .dramValueStoreMemWrData_V_V_TVALID(dramValueStoreMemWrData_V_V_TVALID),
                .dramValueStoreMemWrData_V_V_TDATA(dramValueStoreMemWrData_V_V_TDATA),
                .dramValueStoreMemWrData_V_V_TREADY(dramValueStoreMemWrData_V_V_TREADY),
                .flushReq_V(flushReq_V),
                .flushAck_V(flushAck_V),
                .flushDone_V(flushDone_V)                
                            
);

/* ------------------------------------------------------------ */
/* ChipScope Debugging                                          */
/* ------------------------------------------------------------ */
//chipscope debugging
/*
reg [255:0] data;
reg [31:0]  trig0;
wire [35:0] control0, control1;
wire vio_reset; //active high

chipscope_icon icon0
(
    .CONTROL0 (control0),
    .CONTROL1 (control1)
);

chipscope_ila ila0
(
    .CLK     (clk),
    .CONTROL (control0),
    .TRIG0   (trig0),
    .DATA    (data)
);
chipscope_vio vio0
(
    .CONTROL(control1),
    .ASYNC_OUT(vio_reset)
);

always @(posedge clk) begin
    data[39:0] <= ht_cmd_dramRdData_data;
    data[79:40] <= dramValueStoreMemRdCmd_V_TDATA;
    data[80] <= ht_cmd_dramRdData_valid;
    data[81] <= ht_cmd_dramRdData_ready;
    data[82] <= ht_dramRdData_valid;
    data[83] <= ht_dramRdData_ready;
    data[84] <= ht_s_axis_read_cmd_tvalid;
    data[85] <= ht_s_axis_read_cmd_tready;
    data[86] <= ht_m_axis_read_tvalid;
    data[87] <= ht_m_axis_read_tready;
    data[88] <= ht_m_axis_read_tkeep;
    data[89] <= ht_m_axis_read_tlast;
    data[90] <= ht_m_axis_read_sts_tvalid;
    data[91] <= ht_m_axis_read_sts_tready;
    data[92] <= dramValueStoreMemRdCmd_V_TVALID;
    data[93] <= dramValueStoreMemRdCmd_V_TREADY;
    data[94] <= dramValueStoreMemRdData_V_V_TVALID;
    data[95] <= dramValueStoreMemRdData_V_V_TREADY;
    data[96] <= vs_s_axis_read_cmd_tvalid;
    data[97] <= vs_s_axis_read_cmd_tready;
    data[98] <= vs_m_axis_read_tvalid;
    data[99] <= vs_m_axis_read_tready;
    data[100] <= vs_m_axis_read_tkeep;
    data[101] <= vs_m_axis_read_tlast;
    data[102] <= vs_m_axis_read_sts_tvalid;
    data[103] <= vs_m_axis_read_sts_tready;
    data[104] <= link_initialized_clk156;
    data[105] <= ncq_idle_clk156;
    data[106] <= fin_read_sig_clk156;
    
    trig0[0] <= ht_cmd_dramRdData_valid;
    trig0[1] <= ht_cmd_dramRdData_ready;
    trig0[2] <= ht_dramRdData_valid;
    trig0[3] <= ht_dramRdData_ready;
    trig0[4] <= ht_s_axis_read_cmd_tvalid;
    trig0[5] <= ht_s_axis_read_cmd_tready;
    trig0[6] <= ht_m_axis_read_tvalid;
    trig0[7] <= ht_m_axis_read_tready;
    trig0[8] <= ht_m_axis_read_tkeep;
    trig0[9] <= ht_m_axis_read_tlast;
    trig0[10] <= ht_m_axis_read_sts_tvalid;
    trig0[11] <= ht_m_axis_read_sts_tready;
    trig0[12] <= dramValueStoreMemRdCmd_V_TVALID;
    trig0[13] <= dramValueStoreMemRdCmd_V_TREADY;
    trig0[14] <= dramValueStoreMemRdData_V_V_TVALID;
    trig0[15] <= dramValueStoreMemRdData_V_V_TREADY;
    trig0[16] <= vs_s_axis_read_cmd_tvalid;
    trig0[17] <= vs_s_axis_read_cmd_tready;
    trig0[18] <= vs_m_axis_read_tvalid;
    trig0[19] <= vs_m_axis_read_tready;
    trig0[20] <= vs_m_axis_read_tkeep;
    trig0[21] <= vs_m_axis_read_tlast;
    trig0[22] <= vs_m_axis_read_sts_tvalid;
    trig0[23] <= vs_m_axis_read_sts_tready;
end*/

endmodule
