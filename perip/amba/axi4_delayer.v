module axi4_delayer(
  input         clock,
  input         reset,

  output        in_arready,
  input         in_arvalid,
  input  [3:0]  in_arid,
  input  [31:0] in_araddr,
  input  [7:0]  in_arlen,
  input  [2:0]  in_arsize,
  input  [1:0]  in_arburst,
  input         in_rready,
  output        in_rvalid,
  output [3:0]  in_rid,
  output [31:0] in_rdata,
  output [1:0]  in_rresp,
  output        in_rlast,
  output        in_awready,
  input         in_awvalid,
  input  [3:0]  in_awid,
  input  [31:0] in_awaddr,
  input  [7:0]  in_awlen,
  input  [2:0]  in_awsize,
  input  [1:0]  in_awburst,
  output        in_wready,
  input         in_wvalid,
  input  [31:0] in_wdata,
  input  [3:0]  in_wstrb,
  input         in_wlast,
                in_bready,
  output        in_bvalid,
  output [3:0]  in_bid,
  output [1:0]  in_bresp,

  input         out_arready,
  output        out_arvalid,
  output [3:0]  out_arid,
  output [31:0] out_araddr,
  output [7:0]  out_arlen,
  output [2:0]  out_arsize,
  output [1:0]  out_arburst,
  output        out_rready,
  input         out_rvalid,
  input  [3:0]  out_rid,
  input  [31:0] out_rdata,
  input  [1:0]  out_rresp,
  input         out_rlast,
  input         out_awready,
  output        out_awvalid,
  output [3:0]  out_awid,
  output [31:0] out_awaddr,
  output [7:0]  out_awlen,
  output [2:0]  out_awsize,
  output [1:0]  out_awburst,
  input         out_wready,
  output        out_wvalid,
  output [31:0] out_wdata,
  output [3:0]  out_wstrb,
  output        out_wlast,
                out_bready,
  input         out_bvalid,
  input  [3:0]  out_bid,
  input  [1:0]  out_bresp
);

  localparam r = 2;

  /* R Info */
  reg [1:0]  rc_wptr;
  reg [1:0]  rc_rptr;

  reg [3:0]  rid[3:0];
  reg [31:0] rdata[3:0];
  reg [1:0]  rresp[3:0];
  reg        rlast[3:0];

  reg [15:0] rc_delay[3:0];
  reg        rc_recived[3:0];

  wire rc_out = ((cur_state == four_read  ) && ready_out) ? ((rc_delay[0] == 1) || (rc_delay[1] == 1) || (rc_delay[2] == 1) || (rc_delay[3] == 1)) : 
                ((cur_state == single_read) && ready_out) ? ((rc_delay[0] == 1)) : 0;

  wire rc_end = (cur_state == four_read  ) ? (
                                              (rc_delay[0]   == 0) && (rc_recived[0] == 1) &&
                                              (rc_delay[1]   == 0) && (rc_recived[1] == 1) &&
                                              (rc_delay[2]   == 0) && (rc_recived[2] == 1) &&
                                              (rc_delay[3]   == 0) && (rc_recived[3] == 1)
                                           ) :
                (cur_state == single_read) ? (
                                              (rc_delay[0]   == 0) && (rc_recived[0] == 1)
                                             ) : 0;

  reg  ready_out;
  reg  out;

  /* B Info */
  reg [3:0]  bid;
  reg [1:0]  bresp;

  reg [15:0] bc_delay;
  reg        bc_recived;

  reg  ready_bout;
  reg  bout;

  wire bc_out = ((cur_state == write) && ready_bout) ? (bc_delay == 1) : 0;


  //-----------------------------------------------------------------
  // FSM
  //-----------------------------------------------------------------
  parameter idle        = 3'b000; 
  parameter single_read = 3'b001; 
  parameter four_read   = 3'b010; 
  parameter write       = 3'b011; 

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------

  assign in_arready  = out_arready;
  assign out_arvalid = in_arvalid;
  assign out_arid    = in_arid;
  assign out_araddr  = in_araddr;
  assign out_arlen   = in_arlen;
  assign out_arsize  = in_arsize;
  assign out_arburst = in_arburst;

  assign out_rready  = (cur_state == four_read  ) ? (rlast[3] == 0) :
                       (cur_state == single_read) ? (rlast[0] == 0) : 0;
  assign in_rvalid   = (cur_state == four_read  ) && (out == 1) ? 1 : 
                       (cur_state == single_read) && (out == 1) ? 1 : 0;
  assign in_rid      = (cur_state == four_read  ) && (out == 1) ? rid[rc_rptr]   :
                       (cur_state == single_read) && (out == 1) ? rid[0]         : 0;
  assign in_rdata    = (cur_state == four_read  ) && (out == 1) ? rdata[rc_rptr] : 
                       (cur_state == single_read) && (out == 1) ? rdata[0]       : 0;
  assign in_rresp    = (cur_state == four_read  ) && (out == 1) ? rresp[rc_rptr] : 
                       (cur_state == single_read) && (out == 1) ? rresp[0]       : 0;
  assign in_rlast    = (cur_state == four_read  ) && (out == 1) ? rlast[rc_rptr] : 
                      (cur_state == single_read) && (out == 1) ? rlast[0]       : 0;

  assign in_awready  = out_awready;
  assign out_awvalid = in_awvalid;
  assign out_awid    = in_awid;
  assign out_awaddr  = in_awaddr;
  assign out_awlen   = in_awlen;
  assign out_awsize  = in_awsize;
  assign out_awburst = in_awburst;

  assign in_wready   = out_wready;
  assign out_wvalid  = in_wvalid;
  assign out_wdata   = in_wdata;
  assign out_wstrb   = in_wstrb;
  assign out_wlast   = in_wlast;

  assign out_bready  = (cur_state == write) && (bc_recived == 0);
  assign in_bvalid   = (cur_state == write) && (bout == 1) ? 1     : 0;
  assign in_bid      = (cur_state == write) && (bout == 1) ? bid   : 0;
  assign in_bresp    = (cur_state == write) && (bout == 1) ? bresp : 0;

  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ ( posedge Clock ) block
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset)  begin
      cur_state <= idle;
    end else begin
      cur_state <= next_state;
    end
  end

  //-----------------------------------------------------------------
  // Conditional State - Transition always@ ( * ) block
  //-----------------------------------------------------------------
  always @(*) begin
    if (reset) begin
      next_state = idle;  
    end else begin
        next_state = cur_state;
        case (cur_state)
            idle:  if (in_arvalid && (in_arlen == 3)) next_state = four_read;
                   else if (in_arvalid && (in_arlen == 0)) next_state = single_read;
                   else if (in_awvalid && (in_arlen == 0)) next_state = write;
            four_read:   if (rc_end) next_state = idle;
            single_read: if (rc_end) next_state = idle;
            write: if (bout && in_bvalid && in_bready) next_state = idle;
          default: next_state = cur_state;
        endcase
    end
  end

  //-----------------------------------------------------------------
  // Miscellaneous
  //-----------------------------------------------------------------
  always @(posedge clock) begin
    if (reset) begin
      for (integer i = 0; i < 4; i = i + 1) begin
        rid[i]   <= 0;
        rdata[i] <= 0;
        rresp[i] <= 0;
        rlast[i] <= 0;
        rc_recived[i] <= 0;
      end   
      rc_wptr <= 0;
    end else if (cur_state == four_read && out_rvalid) begin
      rid[rc_wptr]   <= out_rid;
      rdata[rc_wptr] <= out_rdata;
      rresp[rc_wptr] <= out_rresp;
      rlast[rc_wptr] <= out_rlast;
      rc_recived[rc_wptr] <= 1;
      rc_wptr <= rc_wptr + 1;
    end else if (cur_state == single_read && out_rvalid) begin
      rid[0]   <= out_rid;
      rdata[0] <= out_rdata;
      rresp[0] <= out_rresp;
      rlast[0] <= out_rlast;
      rc_recived[0] <= 1;
    end else if (cur_state == idle) begin
      for (integer i = 0; i < 4; i = i + 1) begin
        rid[i]   <= 0;
        rdata[i] <= 0;
        rresp[i] <= 0;
        rlast[i] <= 0;
        rc_recived[i] <= 0;
      end   
      rc_wptr <= 0;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      for (integer i = 0; i < 4; i = i + 1) begin
        rc_delay[i]   <= 0;
      end   
      ready_out <= 0;
    end else if (cur_state == idle && in_arvalid) begin
      if (in_arlen == 3) begin
        for (integer i = 0; i < 4; i = i + 1) begin
          rc_delay[i] <= 2 * r - 2;
        end   
      end else if (in_arlen == 0) begin
        rc_delay[0] <= 2 * r - 2;
      end
    end else if (cur_state == four_read) begin
      for (integer i = 0; i < 4; i = i + 1) begin
        if (!rc_recived[i]) begin
          if (!out_rvalid) begin
            rc_delay[i] <= rc_delay[i] + r - 1;
          end else if (out_rvalid) begin
            if (i == {30'h0, rc_wptr}) begin
              rc_delay[i] <= rc_delay[i] - 1;
            end else begin
              rc_delay[i] <= rc_delay[i] + r - 1;
            end
          end
        end else if (rc_recived[i] && rc_delay[i] > 0) begin
          rc_delay[i] <= rc_delay[i] - 1;
          ready_out <= 1;
        end
      end
    end else if (cur_state == single_read) begin
      if (!rc_recived[0]) begin
        if (!out_rvalid) begin
          rc_delay[0] <= rc_delay[0] + r - 1;
        end else if (out_rvalid) begin
          rc_delay[0] <= rc_delay[0] - 1;
        end
      end else if (rc_recived[0] && rc_delay[0] > 0) begin
        rc_delay[0] <= rc_delay[0] - 1;
        ready_out <= 1;
      end
    end else if (cur_state == idle) begin
      for (integer i = 0; i < 4; i = i + 1) begin
        rc_delay[i] <= 0;
      end   
      ready_out <= 0;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      rc_rptr <= 0;
    end else if (cur_state == four_read && out && in_rready && in_rvalid) begin
      rc_rptr <= rc_rptr + 1;
    end else if (cur_state == single_read || cur_state == idle) begin
      rc_rptr <= 0;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      out <= 0;
    end else if (!out && rc_out) begin
      out <= 1;
    end else if (out && in_rready && in_rvalid) begin
      out <= 0;
    end
  end

  /* Write Transaction */
  always @(posedge clock) begin
    if (reset) begin
      bid   <= 0;
      bresp <= 0;
      bc_recived <= 0;
    end else if (cur_state == write && out_bvalid) begin
      bid   <= out_bid;
      bresp <= out_bresp;
      bc_recived <= 1;
    end else if (cur_state == idle) begin
      bid   <= 0;
      bresp <= 0;
      bc_recived <= 0;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      bc_delay <= 0;
      ready_bout <= 0;
    end else if (cur_state == idle && in_awvalid) begin
      bc_delay <= 2 * r - 2;
    end else if (cur_state == write) begin
      if (!bc_recived) begin
        if (!out_bvalid) begin
          bc_delay <= bc_delay + r - 1;
        end else if (out_bvalid) begin
          bc_delay <= bc_delay - 1;
        end
      end else if (bc_recived && bc_delay > 0) begin
        bc_delay <= bc_delay - 1;
        ready_bout <= 1;
      end
    end else if (cur_state == idle) begin
      bc_delay <= 0;
      ready_bout <= 0;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      bout <= 0;
    end else if (!bout && bc_out) begin
      bout <= 1;
    end else if (bout && in_bready && in_bvalid ) begin
      bout <= 0;
    end
  end

endmodule
