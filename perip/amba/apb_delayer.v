module apb_delayer(
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

  output [31:0] out_paddr,
  output        out_psel,
  output        out_penable,
  output [2:0]  out_pprot,
  output        out_pwrite,
  output [31:0] out_pwdata,
  output [3:0]  out_pstrb,
  input         out_pready,
  input  [31:0] out_prdata,
  input         out_pslverr
);

  localparam r = 3;

  reg[31:0] delay;
  reg[31:0] prdata;
  reg       pslverr;

  parameter idle   = 3'b000; 
  parameter access = 3'b001; 
  parameter await  = 3'b010; 
  parameter resp   = 3'b011; 

  reg [2:0] cur_state;
  reg [2:0] next_state;

  //-----------------------------------------------------------------
  // Outputs 
  //-----------------------------------------------------------------
  assign out_paddr   = in_paddr;
  assign out_psel    = ((cur_state == idle) || (cur_state == access)) ? in_psel    : 0;
  assign out_penable = ((cur_state == idle) || (cur_state == access)) ? in_penable : 0;
  assign out_pprot   = in_pprot;
  assign out_pwrite  = in_pwrite;
  assign out_pwdata  = in_pwdata;
  assign out_pstrb   = in_pstrb;

  assign in_pready   = (cur_state == resp) ? 1       : 0;
  assign in_prdata   = (cur_state == resp) ? prdata  : 0;
  assign in_pslverr  = (cur_state == resp) ? pslverr : 0;

  //-----------------------------------------------------------------
  // Synchronous State - Transition always@ ( posedge Clock ) block
  //-----------------------------------------------------------------
  always @(posedge clock or negedge reset) begin
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
            idle:   if (in_psel)                  next_state = access;
            access: if (in_penable && out_pready) next_state = await;  
            await:  if (delay == 1)               next_state = resp; 
            resp:   if (in_penable && in_pready)  next_state = idle;
          default:                                next_state = cur_state;
        endcase
    end
  end

  //-----------------------------------------------------------------
  // Miscellaneous
  //-----------------------------------------------------------------
  always @(posedge clock or negedge reset) begin
    if (reset) begin
      prdata  <= 0;
      pslverr <= 0;
    end else if ((cur_state == access) && out_pready) begin
      prdata  <= out_prdata;
      pslverr <= out_pslverr;
    end
  end

  always @(posedge clock or negedge reset) begin
    if (reset) begin
      delay <= 0;
    end else if ((cur_state == idle) && in_psel) begin
      delay <= 2 * r - 2;
    end else if ((cur_state == access) && !out_pready) begin
      delay <= delay + r - 1;
    end else if ((cur_state == access) &&  out_pready) begin
      delay <= delay - 1;
    end else if ((cur_state == await)) begin
      delay <= delay - 1;
    end
  end

endmodule
