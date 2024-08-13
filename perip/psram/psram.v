//`define SPI

module psram(
  input sck,
  input ce_n,
  inout [3:0] dio
);

`ifdef SPI

  // count
  reg[31:0] cnt;

  always @(posedge sck or posedge ce_n) begin
    if (ce_n) begin
      cnt <= 0;
    end else begin
      cnt <= cnt + 1;
    end
  end

  // receive command
  reg[7:0] cmd;

  always @(posedge sck or posedge ce_n) begin
    if (ce_n) begin
      cmd <= 0;
    end else if (cnt <= 7) begin
      cmd <= {cmd[6:0], dio[0]};
    end
  end

  // receive address
  reg[23:0] addr;

  always @(posedge sck or posedge ce_n) begin
    if (ce_n) begin
      addr <= 0;
    end else if (cnt >= 8 && cnt <= 13) begin
      addr <= {addr[19:0], dio};
    end
  end

  // read data
  reg[7:0]  mem[4194303:0]; // 2^22: 4 MB
  reg[31:0] buffer;

  always @(posedge sck or posedge ce_n) begin
    if (ce_n) begin
      buffer <= 0;
    end else if (cmd == 8'heb && cnt == 14) begin
      buffer <= {mem[addr + 3], mem[addr + 2], mem[addr + 1], mem[addr]};
    end
  end

  assign dio = (cmd == 8'heb && cnt == 21) ? buffer[7:4]   :
               (cmd == 8'heb && cnt == 22) ? buffer[3:0]   :
               (cmd == 8'heb && cnt == 23) ? buffer[15:12] :
               (cmd == 8'heb && cnt == 24) ? buffer[11:8]  :
               (cmd == 8'heb && cnt == 25) ? buffer[23:20] :
               (cmd == 8'heb && cnt == 26) ? buffer[19:16] :
               (cmd == 8'heb && cnt == 27) ? buffer[31:28] :
               (cmd == 8'heb && cnt == 28) ? buffer[27:24] : 4'bz;

  // write data
  always @(posedge sck) begin
    if (!ce_n) begin
      if (cmd == 8'h38) begin
        case (cnt)
          14: mem[addr + 0][7:4] <= dio;
          15: mem[addr + 0][3:0] <= dio;
          16: mem[addr + 1][7:4] <= dio;
          17: mem[addr + 1][3:0] <= dio;
          18: mem[addr + 2][7:4] <= dio;
          19: mem[addr + 2][3:0] <= dio;
          20: mem[addr + 3][7:4] <= dio;
          21: mem[addr + 3][3:0] <= dio;
        endcase
      end
    end
  end

`else

  // count
  reg[31:0] cnt;

  always @(posedge sck or posedge ce_n) begin
    if (ce_n) begin
      cnt <= 0;
    end else begin
      cnt <= cnt + 1;
    end
  end

  // receive command
  reg[7:0] cmd;

  always @(posedge sck or posedge ce_n) begin
    if (ce_n) begin
      cmd <= 0;
    end else if (cnt <= 1) begin
      cmd <= {cmd[3:0], dio};
    end
  end

  // receive address
  reg[23:0] addr;

  always @(posedge sck or posedge ce_n) begin
    if (ce_n) begin
      addr <= 0;
    end else if (cnt >= 2 && cnt <= 7) begin
      addr <= {addr[19:0], dio};
    end
  end

  // read data
  reg[7:0]  mem[4194303:0]; // 2^22: 4 MB
  reg[31:0] buffer;

  always @(posedge sck or posedge ce_n) begin
    if (ce_n) begin
      buffer <= 0;
    end else if (cmd == 8'heb && cnt == 8) begin
      buffer <= {mem[addr[21:0] + 3], mem[addr[21:0] + 2], mem[addr[21:0] + 1], mem[addr[21:0]]};
    end
  end

  assign dio = (cmd == 8'heb && cnt == 15) ? buffer[7:4]   :
               (cmd == 8'heb && cnt == 16) ? buffer[3:0]   :
               (cmd == 8'heb && cnt == 17) ? buffer[15:12] :
               (cmd == 8'heb && cnt == 18) ? buffer[11:8]  :
               (cmd == 8'heb && cnt == 19) ? buffer[23:20] :
               (cmd == 8'heb && cnt == 20) ? buffer[19:16] :
               (cmd == 8'heb && cnt == 21) ? buffer[31:28] :
               (cmd == 8'heb && cnt == 22) ? buffer[27:24] : 4'bz;

  // write data
  always @(posedge sck) begin
    if (!ce_n) begin
      if (cmd == 8'h38) begin
        case (cnt)
          8:  mem[addr[21:0] + 0][7:4] <= dio;
          9:  mem[addr[21:0] + 0][3:0] <= dio;
          10: mem[addr[21:0] + 1][7:4] <= dio;
          11: mem[addr[21:0] + 1][3:0] <= dio;
          12: mem[addr[21:0] + 2][7:4] <= dio;
          13: mem[addr[21:0] + 2][3:0] <= dio;
          14: mem[addr[21:0] + 3][7:4] <= dio;
          15: mem[addr[21:0] + 3][3:0] <= dio;
        endcase
      end
    end
  end

`endif

endmodule
