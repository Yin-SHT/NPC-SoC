module gpio_top_apb(
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

  output [15:0] gpio_out,
  input  [15:0] gpio_in,
  output [7:0]  gpio_seg_0,
  output [7:0]  gpio_seg_1,
  output [7:0]  gpio_seg_2,
  output [7:0]  gpio_seg_3,
  output [7:0]  gpio_seg_4,
  output [7:0]  gpio_seg_5,
  output [7:0]  gpio_seg_6,
  output [7:0]  gpio_seg_7
);

  localparam DIG_0 = 8'b11111101;
  localparam DIG_1 = 8'b01100000;
  localparam DIG_2 = 8'b11011010;
  localparam DIG_3 = 8'b11110010;
  localparam DIG_4 = 8'b01100110;
  localparam DIG_5 = 8'b10110110;
  localparam DIG_6 = 8'b10111110;
  localparam DIG_7 = 8'b11100000;
  localparam DIG_8 = 8'b11111111;
  localparam DIG_9 = 8'b11110110;

  reg[15:0] led_reg;   // addr: 0x0
  reg[15:0] but_reg;   // addr: 0x4
  reg[31:0] dig_reg;   // addr: 0x8

  reg[31:0] data_out;

  wire[7:0] seg_0;
  wire[7:0] seg_1;
  wire[7:0] seg_2;
  wire[7:0] seg_3;
  wire[7:0] seg_4;
  wire[7:0] seg_5;
  wire[7:0] seg_6;
  wire[7:0] seg_7;

  assign gpio_seg_0 = ~seg_0;
  assign gpio_seg_1 = ~seg_1;
  assign gpio_seg_2 = ~seg_2;
  assign gpio_seg_3 = ~seg_3;
  assign gpio_seg_4 = ~seg_4;
  assign gpio_seg_5 = ~seg_5;
  assign gpio_seg_6 = ~seg_6;
  assign gpio_seg_7 = ~seg_7;

  assign in_pready = in_penable;
  assign in_prdata = data_out;
  assign gpio_out  = led_reg;

  assign seg_0 = (dig_reg[ 3: 0] == 0) ? DIG_0 :
                 (dig_reg[ 3: 0] == 1) ? DIG_1 :
                 (dig_reg[ 3: 0] == 2) ? DIG_2 :
                 (dig_reg[ 3: 0] == 3) ? DIG_3 :
                 (dig_reg[ 3: 0] == 4) ? DIG_4 :
                 (dig_reg[ 3: 0] == 5) ? DIG_5 :
                 (dig_reg[ 3: 0] == 6) ? DIG_6 :
                 (dig_reg[ 3: 0] == 7) ? DIG_7 :
                 (dig_reg[ 3: 0] == 8) ? DIG_8 :
                 (dig_reg[ 3: 0] == 9) ? DIG_9 : DIG_0;

  assign seg_1 = (dig_reg[ 7: 4] == 0) ? DIG_0 :
                 (dig_reg[ 7: 4] == 1) ? DIG_1 :
                 (dig_reg[ 7: 4] == 2) ? DIG_2 :
                 (dig_reg[ 7: 4] == 3) ? DIG_3 :
                 (dig_reg[ 7: 4] == 4) ? DIG_4 :
                 (dig_reg[ 7: 4] == 5) ? DIG_5 :
                 (dig_reg[ 7: 4] == 6) ? DIG_6 :
                 (dig_reg[ 7: 4] == 7) ? DIG_7 :
                 (dig_reg[ 7: 4] == 8) ? DIG_8 :
                 (dig_reg[ 7: 4] == 9) ? DIG_9 : DIG_0;

  assign seg_2 = (dig_reg[11: 8] == 0) ? DIG_0 :
                 (dig_reg[11: 8] == 1) ? DIG_1 :
                 (dig_reg[11: 8] == 2) ? DIG_2 :
                 (dig_reg[11: 8] == 3) ? DIG_3 :
                 (dig_reg[11: 8] == 4) ? DIG_4 :
                 (dig_reg[11: 8] == 5) ? DIG_5 :
                 (dig_reg[11: 8] == 6) ? DIG_6 :
                 (dig_reg[11: 8] == 7) ? DIG_7 :
                 (dig_reg[11: 8] == 8) ? DIG_8 :
                 (dig_reg[11: 8] == 9) ? DIG_9 : DIG_0;

  assign seg_3 = (dig_reg[15:12] == 0) ? DIG_0 :
                 (dig_reg[15:12] == 1) ? DIG_1 :
                 (dig_reg[15:12] == 2) ? DIG_2 :
                 (dig_reg[15:12] == 3) ? DIG_3 :
                 (dig_reg[15:12] == 4) ? DIG_4 :
                 (dig_reg[15:12] == 5) ? DIG_5 :
                 (dig_reg[15:12] == 6) ? DIG_6 :
                 (dig_reg[15:12] == 7) ? DIG_7 :
                 (dig_reg[15:12] == 8) ? DIG_8 :
                 (dig_reg[15:12] == 9) ? DIG_9 : DIG_0;

  assign seg_4 = (dig_reg[19:16] == 0) ? DIG_0 :
                 (dig_reg[19:16] == 1) ? DIG_1 :
                 (dig_reg[19:16] == 2) ? DIG_2 :
                 (dig_reg[19:16] == 3) ? DIG_3 :
                 (dig_reg[19:16] == 4) ? DIG_4 :
                 (dig_reg[19:16] == 5) ? DIG_5 :
                 (dig_reg[19:16] == 6) ? DIG_6 :
                 (dig_reg[19:16] == 7) ? DIG_7 :
                 (dig_reg[19:16] == 8) ? DIG_8 :
                 (dig_reg[19:16] == 9) ? DIG_9 : DIG_0;

  assign seg_5 = (dig_reg[23:20] == 0) ? DIG_0 :
                 (dig_reg[23:20] == 1) ? DIG_1 :
                 (dig_reg[23:20] == 2) ? DIG_2 :
                 (dig_reg[23:20] == 3) ? DIG_3 :
                 (dig_reg[23:20] == 4) ? DIG_4 :
                 (dig_reg[23:20] == 5) ? DIG_5 :
                 (dig_reg[23:20] == 6) ? DIG_6 :
                 (dig_reg[23:20] == 7) ? DIG_7 :
                 (dig_reg[23:20] == 8) ? DIG_8 :
                 (dig_reg[23:20] == 9) ? DIG_9 : DIG_0;

  assign seg_6 = (dig_reg[27:24] == 0) ? DIG_0 :
                 (dig_reg[27:24] == 1) ? DIG_1 :
                 (dig_reg[27:24] == 2) ? DIG_2 :
                 (dig_reg[27:24] == 3) ? DIG_3 :
                 (dig_reg[27:24] == 4) ? DIG_4 :
                 (dig_reg[27:24] == 5) ? DIG_5 :
                 (dig_reg[27:24] == 6) ? DIG_6 :
                 (dig_reg[27:24] == 7) ? DIG_7 :
                 (dig_reg[27:24] == 8) ? DIG_8 :
                 (dig_reg[27:24] == 9) ? DIG_9 : DIG_0;

  assign seg_7 = (dig_reg[31:28] == 0) ? DIG_0 :
                 (dig_reg[31:28] == 1) ? DIG_1 :
                 (dig_reg[31:28] == 2) ? DIG_2 :
                 (dig_reg[31:28] == 3) ? DIG_3 :
                 (dig_reg[31:28] == 4) ? DIG_4 :
                 (dig_reg[31:28] == 5) ? DIG_5 :
                 (dig_reg[31:28] == 6) ? DIG_6 :
                 (dig_reg[31:28] == 7) ? DIG_7 :
                 (dig_reg[31:28] == 8) ? DIG_8 :
                 (dig_reg[31:28] == 9) ? DIG_9 : DIG_0;

  always @(posedge clock) begin
    if (reset) begin
      but_reg <= 0;
    end else begin
      but_reg <= gpio_in;
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      led_reg <= 0;
      dig_reg <= 0;
    end else if (in_penable) begin
      if (in_pwrite && in_psel) begin
        case (in_paddr[3:0])
          4'h0: begin
            if (in_pstrb[0]) led_reg[ 7: 0] <= in_pwdata[ 7: 0];
            if (in_pstrb[1]) led_reg[15: 8] <= in_pwdata[15: 8];
          end
          4'h8: begin
            if (in_pstrb[0]) dig_reg[ 7: 0] <= in_pwdata[ 7: 0];
            if (in_pstrb[1]) dig_reg[15: 8] <= in_pwdata[15: 8];
            if (in_pstrb[2]) dig_reg[23:16] <= in_pwdata[23:16];
            if (in_pstrb[3]) dig_reg[31:24] <= in_pwdata[31:24];
          end 
          default: begin
            led_reg <= led_reg;
            dig_reg <= dig_reg;
          end
        endcase
      end
    end
  end

  always @(posedge clock) begin
    if (reset) begin
      data_out <= 0;
    end else if (!in_pwrite && in_psel) begin
      case (in_paddr[3:0])
        4'h0: data_out <= {16'h0, led_reg};
        4'h4: data_out <= {16'h0, but_reg};
        4'h8: data_out <= dig_reg;
        default: data_out <= data_out;
      endcase
    end
  end

endmodule
