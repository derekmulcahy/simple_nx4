`timescale 1ns / 1ps

// http://www.ti.com/lit/ds/symlink/tlc5941.pdf

module pixeldriver(
    input  clock,
    output led_sclk,
    output [6:1] led_l_sin,
    output [6:1] led_r_sin,
    output led_cal_sin,
    output led_mode,
    output led_blank,
    output reg led_xlat = 0,
    output led_gsclk
  );

  reg [9:0]  bit_count     =  0; // 3 x 192 bits per row
  reg [2:0]  gsclk_counter = ~0; // clock counter for gsclk
  reg [11:0] gsclk_count   =  0; // gsclk counter for blanking
  reg [2:0]  sclk_counter  = ~0; // clock counter for sclk
  reg        sclk_stopped  =  0;

  wire [191:0] red, green, blue;
  wire [595:0] row;

  assign led_mode     = 0;
  assign led_sclk     = sclk_counter[2];
  assign sclk_strobe  = sclk_counter == 0;
  assign led_gsclk    = gsclk_counter[2];
  assign gsclk_strobe = gsclk_counter == 0;
  assign led_blank    = gsclk_count == 0;
  assign red          = 192'h000000080000000080000000080000000080000000080000;
  assign green        = 192'h000080000000080000000080000000080000000080000000;
  assign blue         = 192'h080000000080000000080000000080000000080000000080;
  assign row          = {red,green,blue};
  assign led_l_sin    = {6{row[bit_count]}};
  assign led_r_sin    = {6{row[bit_count]}};
  assign led_cal_sin  = 0;

  always @(posedge clock)
  begin
    gsclk_counter <= gsclk_counter + 1;
    if (gsclk_strobe) begin
      gsclk_count <= gsclk_count + 1;
    end
  end

  always @(posedge clock)
  begin
    led_xlat <= 0;
    if (!sclk_stopped && !led_blank) begin
      sclk_counter <= sclk_counter + 1;
    end
    if (led_blank) begin
      sclk_stopped <= 0;
    end
    if (sclk_strobe) begin
      if (bit_count == 575) begin
        bit_count    <= 0;
        sclk_stopped <= 1;
        led_xlat     <= 1;
      end else begin
        bit_count <= bit_count + 1;
      end
    end
  end

endmodule