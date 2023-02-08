# I2S-TDA1540
VHDL code for converting standard I2S data (64fs) to the offset-binary data needed for TDA1540 DAC.
- "I2S 2x32=64-bit = 64fs" to "14-bit offset-binary" with inverted MSB and inverted stop-clocked BCK) for TDA1540 DAC (stereo) without the use of MCLK (= even less digital work)
- basic data synchronisation is incorporated on LRCK signal
- the sound is nice, very musical, clean, without digital interference
- my VHDL code is very simple, without advanced techniques, based mostly on standard logic
- therefore inexperienced users can understand and modify it for other similar DACs
- it has low load on the CPLD and it takes up little memory
- only 3 signal wires (I2S) are needed for input (DATA, BCK, LRCK).
- output is true offset-binary specified for TDA1540: 
--  CL - stopped Left DAC clock
--  DL - Left DAC data (inversed MSB)
--  CR - stopped Right DAC clock
--  DR - Right DAC data (inversed MSB)
--  LL and LR - Latch for both channels (latched together)
- it flawlessly works with the cheap CPLD EPM240T100C5 from aliexpress and can be easily configured for others
- my VHDL code is open and free for all

If you like my work and find it helpful, you can donate coffee for me :D 
Donate Coffee for miro1360: 
https://www.buymeacoffee.com/miro1360coffee
Thank you :)
