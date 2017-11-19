`timescale 1ns / 1ps

// http://www.ti.com/lit/ds/symlink/tlc5941.pdf

module pixeldriver(
    input clock,
    output led_sclk,
    output reg [6:1] led_l_sin = 0,
    output reg [6:1] led_r_sin = 0,
    output reg led_cal_sin = 0,
    output reg led_mode = 0,
    output reg led_blank = 0,
    output reg led_xlat = 0,
    output led_gsclk,
    input pixel_clock,
    output reg [7:0] frame_count = 0
  );

	reg [11:0] blanking_clock = 0;

	// 16 x 12 bit words per driver (3 drivers in series, each 16ch; one R,G,B),
  // so 16*12*3=576 bits per 16-wide column (two columns in parallel)

	// if led_mode=1, you're writing dot correction data, 96 bits (6 bits per pixel bigt endian).
  // If Mode=0, you're sending 12 bits per pixel greyscale
	// blanking 0=unblanked, we have to clock a 1 every 4096 greyscale_clocks
	// gsclk is reference clock for pwm grayscale

	reg [5:0]  word_count = 0;	// 48 words per line (3x16)
	reg [3:0]  bit_count  = 0;  // 12 bits per word
	reg [2:0]  row_count  = 0;
  reg [11:0] dotadjust_test = 7;
	reg [11:0] pixels[0:((16*3)*2)-1];

	integer i;

  initial begin
    for(i=0; i<=(((16*3)*2)-1); i=i+1) begin
      pixels[i] <= 0;
    end
  end

	//if loading dot correct data or pixels
	wire [3:0] bits_per_word=(led_mode ? (6-1) : (12-1));

	always @(negedge pixel_clock)
	begin
   //counts down
    if (bit_count== 0 ) begin
      bit_count <= bits_per_word;

      //16 pixels, each r,g,b
      if (word_count == (16*3)-1) begin

        led_xlat <= 1;	//latch row

        if (led_mode==1) begin
          led_mode<=0;	//switch (permanently) from loading dot correct to grayscale after first line of sending it - normally you'd reload dot correct for each line as they're all different
        end

        word_count<=0;

        if (row_count==6-1) begin
          row_count<=0;
          frame_count<=frame_count+1;
          pixels[(16*3)-1]<=pixels[(16*3)-1]+8;
        end else
          row_count <= row_count+1;
      end else begin
        word_count <= word_count+1;
      end
    end else begin
      bit_count <= bit_count-1;
      led_xlat <= 0;
    end

    begin: Serialize
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

  reg [2:0] counter = 0;

  assign led_sclk = pixel_clock;
  assign led_gsclk = counter[2];

  assign gclock_strobe = &counter;

	always @(posedge clock)
	begin
    counter <= counter+1;

    if (gclock_strobe) begin
	    blanking_clock <= blanking_clock+1;
		  led_blank <= (blanking_clock==0);
    end
	end

endmodule
