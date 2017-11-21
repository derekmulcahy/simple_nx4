`timescale 1ns / 1ps

// http://www.ti.com/lit/ds/symlink/tlc5941.pdf

module pixeldriver(
    input clock,
    output led_sclk,
    output reg [6:1] led_l_sin = 0,
    output reg [6:1] led_r_sin = 0,
    output reg led_cal_sin = 0,
    output reg led_mode = 1,
    output reg led_blank = 0,
    output reg led_xlat = 0,
    output led_gsclk,
    output frame_pulse
  );

	// 16 x 12 bit words per driver (3 drivers in series, each 16ch; one R,G,B),
  // so 16*12*3=576 bits per 16-wide column (two columns in parallel)

	// if led_mode=1, you're writing dot correction data, 96 bits (6 bits per pixel bigt endian).
  // If Mode=0, you're sending 12 bits per pixel greyscale
	// blanking 0=unblanked, we have to clock a 1 every 4096 greyscale_clocks
	// gsclk is reference clock for pwm grayscale

  reg [7:0] frame_count = 0;
	reg [5:0]  word_count = 0;	// 48 words per line (3x16)
	reg [3:0]  bit_count  = 5;  // 12 bits per word
	reg [2:0]  row_count  = 0;
  reg [11:0] dotadjust_test = 7;
	reg [11:0] pixels[0:47];
  reg [5:0] counter = 0;

  assign led_sclk = counter[5];
  assign led_gsclk = counter[2];
  assign frame_pulse = frame_count[7];

  assign gsclk_strobe = &counter[2:0];
  assign sclk_strobe = &counter[5:0];

	integer j;

  initial begin
    for(j=0; j<=47; j=j+1) begin
      pixels[j] <= 0;
    end
  end

	integer i = 0;

	//if loading dot correct data or pixels
	wire [3:0] bits_per_word=(led_mode ? 5 : 11);

	always @(posedge clock)
	begin
    if (sclk_strobe) begin
      //counts down
      if (bit_count== 0 ) begin
        bit_count <= bits_per_word;

        //16 pixels, each r,g,b
        if (word_count == 47) begin

          led_xlat <= 1;	//latch row

          if (led_mode==1) begin
            led_mode<=0;	//switch (permanently) from loading dot correct to grayscale after first line of sending it - normally you'd reload dot correct for each line as they're all different
          end

          word_count<=0;

          if (row_count==6-1) begin
            row_count<=0;
            frame_count<=frame_count+1;
          end else
            row_count <= row_count+1;
        end else begin
          word_count <= word_count+1;
        end
      end else begin
        bit_count <= bit_count-1;
        led_xlat <= 0;
      end

      if (led_mode==0) begin
        //12 bit pixels
        if (word_count[5:0]==frame_count[5:0]) begin
          //strobe them as a test
          i = 1;
        end else begin
          i = pixels[word_count][bit_count];
        end
      end else begin
        //9 bit dot adjust
        i = dotadjust_test[bit_count];
      end
      led_l_sin[6:1] <= {6{i[0]}};
      led_r_sin[6:1] <= {6{i[0]}};
      led_cal_sin <= i[0];
    end
  end

	reg [11:0] blanking_clock = 0;

	always @(posedge clock)
	begin
    counter <= counter+1;

    if (gsclk_strobe) begin
	    blanking_clock <= blanking_clock+1;
		  led_blank <= (blanking_clock==0);
    end
	end

endmodule
