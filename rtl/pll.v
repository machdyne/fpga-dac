// diamond 3.7 accepts this PLL
// diamond 3.8-3.9 is untested
// diamond 3.10 or higher is likely to abort with error about unable to use feedback signal
// cause of this could be from wrong CPHASE/FPHASE parameters
module pll
(
    input clkin, // 48 MHz, 0 deg
    output clkout0, // 76.8 MHz, 0 deg (76.5MHz on ICE40)
    output locked
);
`ifdef ECP5
(* FREQUENCY_PIN_CLKI="48" *)
(* FREQUENCY_PIN_CLKOP="76.8" *)
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .OUTDIVIDER_MUXA("DIVA"),
        .OUTDIVIDER_MUXB("DIVB"),
        .OUTDIVIDER_MUXC("DIVC"),
        .OUTDIVIDER_MUXD("DIVD"),
        .CLKI_DIV(5),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(8),
        .CLKOP_CPHASE(3),
        .CLKOP_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(8)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clkin),
        .CLKOP(clkout0),
        .CLKFB(clkout0),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(locked)
	);
`else
   SB_PLL40_CORE #(
		.FEEDBACK_PATH("SIMPLE"),
		.DIVR(4'b0011),
		.DIVF(7'b0110010),
		.DIVQ(3'b011),
		.FILTER_RANGE(3'b001) 
   ) pll_sysclk (
      .RESETB(1'b1),
      .BYPASS(1'b0),
      .REFERENCECLK(clkin),
      .PLLOUTCORE(clkout0),
      .LOCK(locked),
   );
`endif
endmodule
