`timescale 1ns / 1ps

// http://www.ti.com/lit/ds/symlink/tlc5941.pdf

module pixeldriver(
    input  clock,
    output led_sclk,
    output [6:1] led_l_sin,
    output [6:1] led_r_sin,
    output led_cal_sin,
    output reg led_mode = 1,
    output led_blank,
    output reg led_xlat = 0,
    output led_gsclk
  );

  reg [2:0]  gsclk_counter = ~0; // clock counter for gsclk
  reg [11:0] blank_count   =  0; // gsclk counter for blanking
  reg [2:0]  sclk_counter  = ~0; // clock counter for sclk
  reg        sclk_stopped  =  0; // sclk runs when data is being sent
  reg [9:0]  bit_count     =  0; // counts 576 grayscale bits or 288 dot-correction bits

  wire [595:0] gs;              // one row of grayscale bits, 12 * 16 * 3
  wire [191:0] gsr, gsg, gsb;   // 192 bits for grayscale red, green and blue
  wire [287:0] dc;              // one row of dot-correction bits, 6 * 16 * 3
  wire [95:0]  dcr, dcg, dcb;   // 96 bits for dot-correction red, green and blue

  assign led_sclk     = sclk_counter[2];    // sclk is clock/4
  assign sclk_strobe  = sclk_counter == 0;  // 1 clock wide sclk pulse every clock/4 cycles
  assign led_gsclk    = gsclk_counter[2];   // gsclk is clock/4
  assign gsclk_strobe = gsclk_counter == 0; // 1 clock wide gsclk pulse every clock/4 cycles
  assign led_blank    = blank_count == 0;   // generate blank pulse when blank_count wraps around
  assign dcr          = {16{6'b010000}};    // 6 red dot-correction bits, MSB is on right
  assign dcg          = {16{6'b010000}};    // 6 red dot-correction bits, MSB is on right
  assign dcb          = {16{6'b001000}};    // 6 red dot-correction bits, MSB is on right, blue needs boosting
  assign dc           = {dcr,dcg,dcb};      // assemble a row of the red, green and blue dot-correction bits

  // Grayscale data for all white
  // assign gsr          = {16{12'h00F}};
  // assign gsg          = {16{12'h00F}};
  // assign gsb          = {16{12'h00F}};

  // Grayscale data for BGR vertical stripes
  assign gsr          = 192'h00000000F00000000F00000000F00000000F00000000F000;
  assign gsg          = 192'h00000F00000000F00000000F00000000F00000000F000000;
  assign gsb          = 192'h00F00000000F00000000F00000000F00000000F00000000F;

  assign gs           = {gsr,gsg,gsb};      // assemble a row of the red, green and blue grayscale bits
  assign led_l_sin    = led_mode ? {6{dc[bit_count]}} : {6{gs[bit_count]}}; // select grayscale or dot-correction for mode
  assign led_r_sin    = led_l_sin;          // left and right are the same
  assign led_cal_sin  = 0;                  // calibration leds are off

  always @(posedge clock)
  begin
    gsclk_counter <= gsclk_counter + 1;
    if (gsclk_strobe) begin
      blank_count <= blank_count + 1;
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
      if (bit_count == (led_mode ? 287 : 575)) begin
        bit_count    <= 0;
        sclk_stopped <= led_mode ? 0 : 1;
        led_xlat     <= 1;
        led_mode     <= 0;
      end else begin
        bit_count <= bit_count + 1;
      end
    end
  end

endmodule