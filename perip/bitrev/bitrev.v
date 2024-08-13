module bitrev (
  input  sck,
  input  ss,
  input  mosi,
  output miso
);
  reg[7:0] register;
  reg[3:0] count;

  always @( posedge sck ) begin
    if ( ss == 1'b0 ) begin
      if ( count <= 4'b0111 ) begin
        register <= { register[6:0], mosi };   
        count    <= count + 1;
      end else  begin
        register <= { 1'b0, register[7:1] };   
        count    <= count + 1;
      end
    end
  end

  assign miso = (( ss == 1'b0 ) && ( count >= 4'b0111 )) ? register[0] : 
                (( ss == 1'b0 ) && ( count <  4'b0111 )) ? 0           : 1;

endmodule
