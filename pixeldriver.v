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

	// 16 x 12 bit words per driver (3 drivers in series, each 16ch; one R,G,B),
  // so 16*12*3=576 bits per 16-wide column (two columns in parallel)

	// if led_mode=1, you're writing dot correction data, 96 bits (6 bits per pixel bigt endian).
  // If Mode=0, you're sending 12 bits per pixel greyscale
	// blanking 0=unblanked, we have to clock a 1 every 4096 greyscale_clocks
	// gsclk is reference clock for pwm grayscale

  reg [5:0]  frame_count = 0;      // a frame is 12 bits x 48 words x 6 rows
	reg [5:0]  word_count  = 0;	     // 48 words per line (3x16)
	reg [3:0]  bit_count   = 0;      // 12 bits per word
	reg [2:0]  row_count   = 0;      // 6 rows per frame
  reg [5:0]  counter     = {6{1}}; // Clock counter for sclk and gsclk
	reg [11:0] gsclk_count = 0;      // gsclk counter for blanking

  assign led_mode     = 0;
  assign led_sclk     = counter[5];
  assign sclk_strobe  = counter[5:0] == 0;
  assign led_gsclk    = counter[2];
  assign gsclk_strobe = counter[2:0] == 0;
	assign led_blank    = gsclk_count == 0;
  assign pixel        = word_count[5:0] == frame_count[5:0];
  assign led_l_sin    = {6{pixel}};
  assign led_r_sin    = {6{pixel}};
  assign led_cal_sin  = pixel;
  // assign led_xlat     = word_count == 0 && bit_count == 0;

	always @(posedge clock)
	begin
    counter <= counter + 1;
  end

	always @(posedge clock)
  begin
    if (gsclk_strobe) begin
	    gsclk_count <= gsclk_count + 1;
    end
	end

	always @(posedge clock)
	begin
    if (sclk_strobe) begin
      led_xlat <= 0;
      if (bit_count == 11) begin
        bit_count <= 0;
        if (word_count == 47) begin
          word_count <= 0;
          led_xlat <= 1;
          if (row_count == 5) begin
            row_count   <= 0;
            frame_count <= frame_count + 1;
          end else begin
            row_count <= row_count + 1;
          end
        end else begin
          word_count <= word_count + 1;
        end
      end else begin
        bit_count <= bit_count + 1;
      end
    end
  end

endmodule