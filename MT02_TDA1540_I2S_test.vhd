----------------------------------------------------------------------------------------
-- VHDL code for converting standard I2S signal (64fs) to offset-binary 
-- ("I2S 2x32=64-bit = 64fs" to "14-bit offset-binary" with inverted MSB and 
-- inverted stop-clocked BCK) for TDA1540 DAC (stereo) without the use of MCLK.
-- Basic data synchronisation is incorporated on LRCK signal and 
-- the sound is nice, very musical, clean, without digital interference.
-- The code is very simple, without advanced techniques, based mostly on standard logic.
-- Therefore inexperienced users can understand and modify it for other similar DACs.
-- It has low load on the CPLD and it takes up little memory.

-- Only 3 signal wires (I2S) are needed for input (DATA, BCK, LRCK).
-- output is true offset-binary specified for TDA1540: 
--  CL - stopped Left DAC clock
--  DL - Left DAC data (inversed MSB)
--  CR - stopped Right DAC clock
--  DR - Right DAC data (inversed MSB)
--  LL and LR - Latch for both channels (latched together)

-- It flawlessly works with the cheap CPLD EPM240T100C5 from aliexpress.

-- This VHDL code is open and free for all.

-- If you like my work and find it helpful, you can donate coffee for me :D 
-- https://www.buymeacoffee.com/miro1360coffee  Thank you :)
-- by miro1360, 01/2023
----------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity MT02_TDA1540_I2S is
	port(
		inBCK   : in  std_logic; -- I2S BCK
		inDATA  : in  std_logic; -- I2S DATA
		inLRCK  : in  std_logic; -- I2S LRCK
		outBCKL : out std_logic := '1'; -- DAC CL
		outBCKR : out std_logic := '1'; -- DAC CR
		outDL   : out std_logic := '0'; -- DAC DL
		outDR   : out std_logic := '0'; -- DAC DR
		outLL   : out std_logic := '0'; -- DAC LL
		outLR   : out std_logic := '0'  -- DAC LR
	);
end MT02_TDA1540_I2S;


architecture I2S_OB_TDA1540 of MT02_TDA1540_I2S is
	signal cntOB      : integer range 0 to 32 := 0;
	signal synchLRCK  : std_logic := '0';
	signal resetCLK   : std_logic := '0';
	signal dataFlagL  : std_logic := '0';
	signal dataFlagR  : std_logic := '0';
	signal leFlag     : std_logic := '0';
	signal lrckFlag0  : std_logic := '0';
	signal lrckFlag1  : std_logic := '0';
	signal srDATA     : std_logic_vector(3 - 2 downto 0); -- shift register buffer
	signal sdDATA     : std_logic;                        -- delayed data from register
begin

	
	synch_counter_OB_on_inLRCK : process(inBCK, inLRCK, synchLRCK, resetCLK)
	begin
		
		if rising_edge(inBCK) then
			
			lrckFlag1 <= lrckFlag0;
			lrckFlag0 <= inLRCK;
			-- detect LRCK event
			if	(lrckFlag1 = '1') AND (lrckFlag0 = '0') then
				synchLRCK <= '1';
			elsif (lrckFlag1 = '0') AND (lrckFlag0 = '1') then
				synchLRCK <= '1';
			else
				synchLRCK <= '0';
			end if;

		end if;
		
		if synchLRCK = '1' then	-- if LRCK event detected, reset counter_OB
			resetCLK <= '1';
		else
			resetCLK <= '0';
		end if;
		
	end process;
	
	
	counter_OB : process(inBCK)
	begin
		if rising_edge(inBCK) then
			if resetCLK = '1' then	-- synchronize/reset counter on each LRCK event
				cntOB <= 0;
			elsif cntOB < 31 then
				cntOB <= cntOB + 1;
			else
				cntOB <= 0;
			end if;
		end if;
	end process;
	
	
	delay_data : process(inBCK)	-- delay data for proper alignment
	begin
		if rising_edge(inBCK) then
			srDATA <= srDATA(srDATA'high - 1 downto srDATA'low) & inDATA;
			sdDATA <= srDATA(srDATA'high);
		end if;
	end process;
	
	
	output_OB : process(inBCK, cntOB, inLRCK)
	begin
	
		if falling_edge(inBCK) then
			
			if (cntOB = 1) AND (inLRCK = '0') then
				dataFlagL <= NOT sdDATA;	-- invert only MSB
			elsif (cntOB >= 2) AND (cntOB < 15) AND (inLRCK = '0') then
				dataFlagL <= sdDATA;	-- rest 13-bit data are not inverted
			else
				dataFlagL <= '0';
			end if;
			
			if (cntOB = 1) AND (inLRCK = '1') then
				dataFlagR <= NOT sdDATA;	-- invert only MSB
			elsif (cntOB >= 2) AND (cntOB < 15) AND (inLRCK = '1') then
				dataFlagR <= sdDATA; -- rest 13-bit data are not inverted
			else
				dataFlagR <= '0';
			end if;
			
			if (cntOB = 23) AND (inLRCK = '1') then	-- LE pulse duration (2 BCK)
				leFlag <= '1';
			elsif (cntOB >= 25) then
				leFlag <= '0';
			end if;
			
			outDL <= dataFlagL;
			outDR <= dataFlagR;
			
		end if;
		
		if rising_edge(inBCK) then
			outLL <= leFlag;	-- Latch pulse for left channel on rising BCK
			outLR <= leFlag;	-- Latch pulse for right channel on rising BCK
		end if;
		
		if (cntOB >= 3) AND (cntOB < 17) AND (inLRCK = '0') then
			outBCKL <= NOT inBCK;	-- stopped and inverted clock for left channel
		else
			outBCKL <= '1';
		end if;
		
		if (cntOB >= 3) AND (cntOB < 17) AND (inLRCK = '1') then
			outBCKR <= NOT inBCK;	-- stopped and inverted clock for right channel
		else
			outBCKR <= '1';
		end if;
		
	end process;
	
end I2S_OB_TDA1540;
