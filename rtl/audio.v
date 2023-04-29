/*
 * FPGA PCM AUDIO PLAYER
 * Copyright (c) 2023 Lone Dynamics Corporation <info@lonedynamics.com>
 *
 * Expects 48KHz 16-bit signed PCM stereo audio in SPI flash @ 0x000000.
 *
 */

module audio
(

	input CLK_48,

	output LED_R,
	output LED_G,
	output LED_B,

	output SPI_SS_FLASH,
	input SPI_MISO,
	output SPI_MOSI,
`ifndef ECP5
	output SPI_SCK,
`endif

	output AUDIO_L,
	output AUDIO_R,

);

	localparam BITS = 16;

	localparam FLASH_AUDIO_ADDR = 24'h000000;
	localparam FLASH_AUDIO_SIZE = 24'd2883584;
	//localparam FLASH_AUDIO_SIZE = 24'd960000;

`ifdef ECP5
	wire SPI_SCK;
	USRMCLK usrmclk_i (.USRMCLKI(SPI_SCK), .USRMCLKTS(1'b0));
`endif

	// clocks
	wire clk = CLK_48;
	wire clk76_8;
	wire pll_locked;

	pll #() pll_i
	(
		.clkin(clk),
		.clkout0(clk76_8),
		.locked(pll_locked),
	);

	// flash LED

	reg [25:0] led_counter = 0;

   assign LED_R = 1;
	assign LED_G = 1;
   assign LED_B = ~led_counter[25];

   always @(posedge CLK_48) begin
      led_counter <= led_counter + 1;
   end

	// reset generator

   reg [11:0] resetn_counter = 0;
   wire resetn = &resetn_counter;

	always @(posedge clk) begin
		if (!pll_locked)
			resetn_counter <= 0;
		else if (!resetn)
			resetn_counter <= resetn_counter + 1;
	end

	// flash reader

	reg [23:0] flash_addr;
	reg [31:0] flash_data;

	wire flash_ready;

	spiflashro #() flash_i (
		.clk(clk),
		.resetn(resetn),
		.valid(1'b1),
		.ready(flash_ready),
		.addr(flash_addr),
		.rdata(flash_data),
		.ss(SPI_SS_FLASH),
		.sck(SPI_SCK),
		.mosi(SPI_MOSI),
		.miso(SPI_MISO)
	);

	reg [23:0] audio_addr;
	reg [31:0] audio_data;

	always @(posedge clk) begin

		flash_addr <= audio_addr;

		if (flash_ready) begin
			audio_data <= flash_data ^ 32'h80008000;	// remove sign bits
		end

	end

	// generate audio clock

	reg clk_audio;	// 768KHz / 16 bits == 48000Hz
	reg [7:0] clk_audio_ctr;
	always @(posedge clk76_8) begin

		clk_audio_ctr <= clk_audio_ctr + 1;
		if (clk_audio_ctr == 49) begin
			clk_audio_ctr <= 0;
			clk_audio <= ~clk_audio;
		end

	end

	// sigma-delta modulator

	reg [BITS:0] l_pwm_acc;
	reg [BITS:0] r_pwm_acc;

	reg [3:0] seq;

	always @(posedge clk_audio) begin

		if (!resetn) begin

			l_pwm_acc <= 0;
			r_pwm_acc <= 0;
			seq <= 0;
			audio_addr <= FLASH_AUDIO_ADDR;

		end else begin

			if (seq == 15) begin
				if (audio_addr >= FLASH_AUDIO_ADDR + FLASH_AUDIO_SIZE) begin
					audio_addr <= FLASH_AUDIO_ADDR;
				end else begin
					audio_addr <= audio_addr + 4;
				end
			end

			l_pwm_acc <= l_pwm_acc[BITS-1:0] + audio_data[31:16];
			r_pwm_acc <= r_pwm_acc[BITS-1:0] + audio_data[15:0];

			seq <= seq + 1;

		end

	end

	assign AUDIO_L = l_pwm_acc[BITS];
	assign AUDIO_R = r_pwm_acc[BITS];

endmodule
