module ps2_top_apb(
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

  input         ps2_clk,
  input         ps2_data
);

  reg[7:0] fifo[1023:0];
  reg[9:0] r_ptr = 0;
  reg[9:0] w_ptr = 0;

  reg[7:0] buffer = 0;
  reg[3:0] count  = 0;

  reg[7:0] out_buf;

  wire read_en = in_psel && in_penable && !in_pwrite && (count == 0);

  assign in_pready  = read_en ? in_penable : 0;
  assign in_prdata  = {24'h0, out_buf};
  assign in_pslverr = 0;

  /* Read */
  always @(posedge clock) begin
    if (reset) begin
      r_ptr   <= 0;
      out_buf <= 0;
    end else if (read_en) begin
      if (r_ptr != w_ptr) begin
        out_buf <= fifo[r_ptr];
        r_ptr   <= r_ptr + 1;
      end else if (r_ptr == w_ptr) begin
        out_buf <= 0;
        r_ptr   <= r_ptr;
      end
    end
  end

  /* Write */
  always @(negedge ps2_clk) begin
    if (count >= 10 ) begin
      count <= 0;
    end else begin
      count <= count + 1;
    end
  end

  always @(negedge ps2_clk) begin
    if (count >= 1 && count <= 8) begin
      buffer[count - 1] <= ps2_data;
    end else if (count >= 10) begin
      buffer      <= 0;
    end
  end

  always @(negedge ps2_clk) begin
    if (count >= 10) begin
      fifo[w_ptr] <= buffer;
      w_ptr       <= w_ptr + 1;
    end
  end

endmodule
