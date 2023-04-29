# FPGA DAC

This is an experimental implementation of an FPGA-based sigma-delta DAC and audio player.

It expects 48KHz 16-bit signed PCM stereo audio data in SPI flash @ 0x000000.

## Supported Boards

* [Konfekt](https://machdyne.com/product/konfekt-computer/)
* [Noir](https://machdyne.com/product/noir-computer/))
* [Kölsch](https://machdyne.com/product/kolsch-computer/)

## Example Usage

```
$ make gen_sine
$ openFPGALoader -c dirtyJtag -f sine.pcm
$ make audio_noir
$ openFPGALoader -c dirtyJtag output/audio.bit
```
