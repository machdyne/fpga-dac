RTL=rtl/audio.v rtl/spiflashro32.v rtl/pll.v

audio_konfekt:
	mkdir -p output
	yosys -DECP5 -q -p "synth_ecp5 -top audio -json output/audio.json" $(RTL)
	nextpnr-ecp5 --12k --package CABGA256 --lpf boards/konfekt_v0.lpf --json output/audio.json --textcfg output/audio.config
	ecppack -v --compress --freq 2.4 output/audio.config --bit output/audio.bit

audio_noir:
	mkdir -p output
	yosys -DECP5 -q -p "synth_ecp5 -top audio -json output/audio.json" $(RTL)
	nextpnr-ecp5 --12k --package CABGA256 --lpf boards/noir_v0.lpf --json output/audio.json --textcfg output/audio.config
	ecppack -v --compress --freq 2.4 output/audio.config --bit output/audio.bit

prog:
	openFPGALoader -c dirtyJtag output/audio.bit

gen_sine:
	ffmpeg -f lavfi -i "sine=frequency=1000:duration=5" -ac 2 -ar 48000 -f s16le -c:a pcm_s16le sine.pcm
