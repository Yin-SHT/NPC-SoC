// define this macro to enable fast behavior simulation
// for flash by skipping SPI transfers
//`define FAST_FLASH

module spi_top_apb #(
  parameter flash_addr_start = 32'h30000000,
  parameter flash_addr_end   = 32'h3fffffff,
  parameter spi_ss_num       = 8
) (
  input         clock,
  input         reset,
  input  [31:0] in_paddr,
  input         in_psel,
  input         in_penable,
  input  [2:0]  in_pprot,
  input         in_pwrite,
  input  [31:0] in_pwdata,
  input  [3:0]  in_pstrb,
  output        in_pready,
  output [31:0] in_prdata,
  output        in_pslverr,

  output                  spi_sck,
  output [spi_ss_num-1:0] spi_ss,
  output                  spi_mosi,
  input                   spi_miso,
  output                  spi_irq_out
);

`ifdef FAST_FLASH

wire [31:0] data;
parameter invalid_cmd = 8'h0;
flash_cmd flash_cmd_i(
  .clock(clock),
  .valid(in_psel && !in_penable),
  .cmd(in_pwrite ? invalid_cmd : 8'h03),
  .addr({8'b0, in_paddr[23:2], 2'b0}),
  .data(data)
);
assign spi_sck    = 1'b0;
assign spi_ss     = 8'b0;
assign spi_mosi   = 1'b1;
assign spi_irq_out= 1'b0;
assign in_pslverr = 1'b0;
assign in_pready  = in_penable && in_psel && !in_pwrite;
assign in_prdata  = data[31:0];

`else

wire[4:0]  adr_i;
wire[31:0] dat_i;
wire[31:0] dat_o;
wire[3:0]  sel_i;
wire       we_i;
wire       stb_i;
wire       cyc_i;
wire       ack_o;

wire in_flash = ( in_paddr >= 32'h3000_0000 ) && ( in_paddr <= 32'h3fff_ffff );
wire in_spi   = ( in_paddr >= 32'h1000_1000 ) && ( in_paddr <= 32'h1000_1fff );

wire[31:0] cmd = { 8'h03, in_paddr[23:0] };
wire[31:0] data_bswap = { dat_o[7:0], dat_o[15:8], dat_o[23:16], dat_o[31:24] };

parameter idle        = 4'b0000;
parameter normal      = 4'b0001;

parameter xip_wtx0    = 4'b0010;
parameter xip_wtx1    = 4'b0011;
parameter xip_wdiv    = 4'b0100;
parameter xip_wss     = 4'b0101;
parameter xip_wctrl   = 4'b0110;
parameter xip_rctrl   = 4'b0111;
parameter xip_xctrl   = 4'b1000;
parameter xip_rrx0    = 4'b1001;

reg [3:0] cur_state;
reg [3:0] next_state;

assign adr_i     =  (cur_state == normal   ) ? in_paddr[4:0] :
                    (cur_state == xip_wtx0 ) ? 5'h00         :
                    (cur_state == xip_wtx1 ) ? 5'h04         :
                    (cur_state == xip_wdiv ) ? 5'h14         :
                    (cur_state == xip_wss  ) ? 5'h18         :
                    (cur_state == xip_wctrl) ? 5'h10         : 
                    (cur_state == xip_rctrl) ? 5'h10         :
                    (cur_state == xip_xctrl) ? 5'h00         :
                    (cur_state == xip_rrx0 ) ? 5'h00         : 0;

assign dat_i     =  (cur_state == normal   ) ? in_pwdata     :
                    (cur_state == xip_wtx0 ) ? 32'h00        :
                    (cur_state == xip_wtx1 ) ? cmd           :
                    (cur_state == xip_wdiv ) ? 32'h01        :
                    (cur_state == xip_wss  ) ? 32'h01        :
                    (cur_state == xip_wctrl) ? 32'h2140      : 
                    (cur_state == xip_rctrl) ? 32'h00        :
                    (cur_state == xip_xctrl) ? 32'h00        :
                    (cur_state == xip_rrx0 ) ? 32'h00        : 0;

assign sel_i     =  (cur_state == normal   ) ? in_pstrb      :
                    (cur_state == xip_wtx0 ) ? 4'b1111       :
                    (cur_state == xip_wtx1 ) ? 4'b1111       :
                    (cur_state == xip_wdiv ) ? 4'b0011       :
                    (cur_state == xip_wss  ) ? 4'b0001       :
                    (cur_state == xip_wctrl) ? 4'b0011       : 
                    (cur_state == xip_rctrl) ? 0             :
                    (cur_state == xip_xctrl) ? 0             :
                    (cur_state == xip_rrx0 ) ? 0             : 0;

assign we_i      =  (cur_state == normal   ) ? in_pwrite     :
                    (cur_state == xip_wtx0 ) ? 1             :
                    (cur_state == xip_wtx1 ) ? 1             :
                    (cur_state == xip_wdiv ) ? 1             :
                    (cur_state == xip_wss  ) ? 1             :
                    (cur_state == xip_wctrl) ? 1             : 
                    (cur_state == xip_rctrl) ? 0             :
                    (cur_state == xip_xctrl) ? 0             :
                    (cur_state == xip_rrx0 ) ? 0             : 0;

assign stb_i     =  (cur_state == normal   ) ? in_psel       :
                    (cur_state == xip_wtx0 ) ? 1             :
                    (cur_state == xip_wtx1 ) ? 1             :
                    (cur_state == xip_wdiv ) ? 1             :
                    (cur_state == xip_wss  ) ? 1             :
                    (cur_state == xip_wctrl) ? 1             : 
                    (cur_state == xip_rctrl) ? 1             :
                    (cur_state == xip_xctrl) ? 0             :
                    (cur_state == xip_rrx0 ) ? 1             : 0;

assign cyc_i     =  (cur_state == normal   ) ? in_penable    :
                    (cur_state == xip_wtx0 ) ? 1             :
                    (cur_state == xip_wtx1 ) ? 1             :
                    (cur_state == xip_wdiv ) ? 1             :
                    (cur_state == xip_wss  ) ? 1             :
                    (cur_state == xip_wctrl) ? 1             : 
                    (cur_state == xip_rctrl) ? 1             :
                    (cur_state == xip_xctrl) ? 1             :
                    (cur_state == xip_rrx0 ) ? 1             : 0;

assign in_pready =  (cur_state == normal   ) ? ack_o         :
                    (cur_state == xip_wtx0 ) ? 0             :
                    (cur_state == xip_wtx1 ) ? 0             :
                    (cur_state == xip_wdiv ) ? 0             :
                    (cur_state == xip_wss  ) ? 0             :
                    (cur_state == xip_wctrl) ? 0             :
                    (cur_state == xip_rctrl) ? 0             :
                    (cur_state == xip_xctrl) ? 0             :
                    (cur_state == xip_rrx0 ) ? ack_o         : 0;

assign in_prdata =  (cur_state == normal   ) ? dat_o         :
                    (cur_state == xip_wtx0 ) ? dat_o         :
                    (cur_state == xip_wtx1 ) ? dat_o         :
                    (cur_state == xip_wdiv ) ? dat_o         :
                    (cur_state == xip_wss  ) ? dat_o         :
                    (cur_state == xip_wctrl) ? dat_o         :
                    (cur_state == xip_rctrl) ? dat_o         :
                    (cur_state == xip_xctrl) ? dat_o         :
                    (cur_state == xip_rrx0 ) ? data_bswap    : 0;

always @(posedge clock) begin
  if (reset) begin
    cur_state <= idle;
  end else begin
    cur_state <= next_state;
  end
end

always @( * ) begin
  if (reset) begin
    next_state = idle;  
  end else begin
      next_state = cur_state;
      case (cur_state)
        idle:   if (in_psel && in_spi) next_state = normal;
                else if (in_psel && in_flash) next_state = xip_wtx0;
        xip_wtx0:  if (cyc_i && ack_o) next_state = xip_wtx1;
        xip_wtx1:  if (cyc_i && ack_o) next_state = xip_wdiv;
        xip_wdiv:  if (cyc_i && ack_o) next_state = xip_wss;
        xip_wss:   if (cyc_i && ack_o) next_state = xip_wctrl;
        xip_wctrl: if (cyc_i && ack_o) next_state = xip_rctrl;
        xip_rctrl: if (cyc_i && ack_o) next_state = xip_xctrl;
        xip_xctrl: if (!ctrl[8])       next_state = xip_rrx0;
                   else                next_state = xip_rctrl;
        xip_rrx0:  if (cyc_i && ack_o) next_state = idle;
        normal:    if (cyc_i && ack_o) next_state = idle;
        default:                       next_state = cur_state;
      endcase
  end
end

reg[31:0] ctrl;

always @(posedge clock) begin
  if (reset) begin
    ctrl <= 0;
  end else if (cur_state == xip_wctrl && cyc_i && ack_o) begin
    ctrl <= 32'h2140;
  end else if (cur_state == xip_rctrl && cyc_i && ack_o) begin
    ctrl <= in_prdata;
  end else begin
    ctrl <= ctrl;
  end
end

spi_top u0_spi_top (
  .wb_clk_i(clock),
  .wb_rst_i(reset),
  .wb_adr_i(adr_i),
  .wb_dat_i(dat_i),
  .wb_dat_o(dat_o),
  .wb_sel_i(sel_i),
  .wb_we_i (we_i),
  .wb_stb_i(stb_i),
  .wb_cyc_i(cyc_i),  
  .wb_ack_o(ack_o),  
  .wb_err_o(in_pslverr),
  .wb_int_o(spi_irq_out),

  .ss_pad_o(spi_ss),
  .sclk_pad_o(spi_sck),
  .mosi_pad_o(spi_mosi),
  .miso_pad_i(spi_miso)
);

//spi_top u0_spi_top (
//  .wb_clk_i(clock),
//  .wb_rst_i(reset),
//  .wb_adr_i(in_paddr[4:0]),
//  .wb_dat_i(in_pwdata),
//  .wb_dat_o(in_prdata),
//  .wb_sel_i(in_pstrb),
//  .wb_we_i (in_pwrite),
//  .wb_stb_i(in_psel),
//  .wb_cyc_i(in_penable),
//  .wb_ack_o(in_pready),
//  .wb_err_o(in_pslverr),
//  .wb_int_o(spi_irq_out),
//
//  .ss_pad_o(spi_ss),
//  .sclk_pad_o(spi_sck),
//  .mosi_pad_o(spi_mosi),
//  .miso_pad_i(spi_miso)
//);

`endif // FAST_FLASH

endmodule
