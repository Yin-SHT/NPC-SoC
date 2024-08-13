module sdram_particle(
  input        clk,
  input        cke,
  input        cs,
  input        ras,
  input        cas,
  input        we,
  input [13:0] a,
  input [ 1:0] ba,
  input [ 1:0] dqm,
  inout [15:0] dq
);

//-----------------------------------------------------------------
// Defines / Local params
//-----------------------------------------------------------------
localparam CMD_ACTIVE        = 4'b0011;
localparam CMD_READ          = 4'b0101;
localparam CMD_WRITE         = 4'b0100;
localparam CMD_PRECHARGE     = 4'b0010;

// Bank
localparam BANK0             = 2'd0;
localparam BANK1             = 2'd1;
localparam BANK2             = 2'd2;
localparam BANK3             = 2'd3;

wire[3:0] command = {cs, ras, cas, we};

reg[15:0] Bank0[16383:0][511:0];
reg[15:0] Bank1[16383:0][511:0];
reg[15:0] Bank2[16383:0][511:0];
reg[15:0] Bank3[16383:0][511:0];

//-----------------------------------------------------------------
// ACTIVE / WRITE
//-----------------------------------------------------------------
reg[13:0] row_addr_bank0;
reg[13:0] row_addr_bank1;
reg[13:0] row_addr_bank2;
reg[13:0] row_addr_bank3;

reg[15:0] sense_amp_bank0[511:0];
reg[15:0] sense_amp_bank1[511:0];
reg[15:0] sense_amp_bank2[511:0];
reg[15:0] sense_amp_bank3[511:0];

wire[8:0]  waddr = a[8:0];
wire[15:0] wdata = dq;
wire[1:0]  wstrb = dqm;

always @(posedge clk) begin
  if (!cke) begin
    row_addr_bank0 <= 0;
  end else if (command == CMD_ACTIVE) begin
    case (ba)
      BANK0: row_addr_bank0 <= a;
      BANK1: row_addr_bank1 <= a;
      BANK2: row_addr_bank2 <= a;
      BANK3: row_addr_bank3 <= a;
    endcase
  end 
end

always @(posedge clk) begin
  if (cke) begin
    if (command == CMD_ACTIVE) begin
      case (ba)
        BANK0: sense_amp_bank0 <= Bank0[a];
        BANK1: sense_amp_bank1 <= Bank1[a];
        BANK2: sense_amp_bank2 <= Bank2[a];
        BANK3: sense_amp_bank3 <= Bank3[a];
      endcase
    end else if (command == CMD_WRITE) begin
      case (ba)
        BANK0: begin
          if (!wstrb[0]) sense_amp_bank0[waddr][ 7: 0] <= wdata[ 7: 0];
          if (!wstrb[1]) sense_amp_bank0[waddr][15: 8] <= wdata[15: 8];
        end
        BANK1: begin
          if (!wstrb[0]) sense_amp_bank1[waddr][ 7: 0] <= wdata[ 7: 0];
          if (!wstrb[1]) sense_amp_bank1[waddr][15: 8] <= wdata[15: 8];
        end
        BANK2: begin
          if (!wstrb[0]) sense_amp_bank2[waddr][ 7: 0] <= wdata[ 7: 0];
          if (!wstrb[1]) sense_amp_bank2[waddr][15: 8] <= wdata[15: 8];
        end
        BANK3: begin
          if (!wstrb[0]) sense_amp_bank3[waddr][ 7: 0] <= wdata[ 7: 0];
          if (!wstrb[1]) sense_amp_bank3[waddr][15: 8] <= wdata[15: 8];
        end
      endcase
    end
  end
end


//-----------------------------------------------------------------
// READ
//-----------------------------------------------------------------
reg[15:0] output_buf;
reg[15:0] output_reg;

always @(posedge clk) begin
  if (!cke) begin
    output_buf <= 0;
  end else if (command == CMD_READ) begin
    case (ba)
      BANK0: output_buf <= sense_amp_bank0[a[8:0]];
      BANK1: output_buf <= sense_amp_bank1[a[8:0]];
      BANK2: output_buf <= sense_amp_bank2[a[8:0]];
      BANK3: output_buf <= sense_amp_bank3[a[8:0]];
    endcase
  end else begin
    output_buf <= 0;
  end
end

always @(posedge clk) begin
  if (!clk) begin
    output_reg <= 0;
  end else begin
    output_reg <= output_buf;
  end
end

assign dq = output_reg;

//-----------------------------------------------------------------
// Precharge
//-----------------------------------------------------------------
always @(posedge clk) begin
  if (cke) begin
    if (command == CMD_PRECHARGE && a[10] == 1 ) begin
      Bank0[row_addr_bank0] <= sense_amp_bank0; 
      Bank1[row_addr_bank1] <= sense_amp_bank1; 
      Bank2[row_addr_bank2] <= sense_amp_bank2; 
      Bank3[row_addr_bank3] <= sense_amp_bank3; 
    end else if (command == CMD_PRECHARGE && a[10] == 0) begin
      case (ba)
        BANK0: Bank0[row_addr_bank0] <= sense_amp_bank0; 
        BANK1: Bank1[row_addr_bank1] <= sense_amp_bank1; 
        BANK2: Bank2[row_addr_bank2] <= sense_amp_bank2; 
        BANK3: Bank3[row_addr_bank3] <= sense_amp_bank3; 
      endcase
    end
  end
end

endmodule
