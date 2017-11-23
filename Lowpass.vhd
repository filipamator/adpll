LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
-- use ieee.std_logic_arith.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_SIGNED.ALL;



entity Lowpass is
	GENERIC (
				LOOPF_WIDTH  : natural
		);
	Port ( 	CLK 			 : in STD_LOGIC;
				RST 			 : in STD_LOGIC;
				FILTER_IN_EN : IN STD_LOGIC;
				FILTER_IN 	 : in STD_LOGIC_VECTOR (17 downto 0);
				FILTER_OUT 	 : out STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0));
end Lowpass;

architecture Behavioral of Lowpass is
	
	signal CURRENT_INPUT 	: STD_LOGIC_VECTOR (17 downto 0) := (others => '0');
	signal LAST_INPUT 		: STD_LOGIC_VECTOR (17 downto 0) := (others => '0');
	signal LAST_OUTPUT 		: STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0) := (others => '0');
	signal CURRENT_OUTPUT 	: STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0) := (others => '0');

	SIGNAL temp : STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0) := (others => '0');


	-- To dzialajacego filtra
	-- SIGNAL temp : STD_LOGIC_VECTOR (27 downto 0) := (others => '0');

	
	signal COUNT : STD_LOGIC := '0';

begin
	CURRENT_INPUT <= FILTER_IN;
	process(CLK,RST)
	begin
		if (RST = '1') then
			LAST_INPUT <= (others => '0');
			LAST_OUTPUT <= (others => '0');
			CURRENT_OUTPUT <= (others => '0');
			temp <= (others => '0');
		elsif rising_edge(CLK) then

		
		
			IF (FILTER_IN_EN='1') THEN
		
				LAST_INPUT <= CURRENT_INPUT;
				LAST_OUTPUT <= CURRENT_OUTPUT;


				 
				--temp <= "10111111001101" * CURRENT_INPUT - "10001010001101" * LAST_INPUT - LAST_OUTPUT;
				
				
				-- Ko=0.011, Kd=8192, bw=10kHz, z=0.707, Ts=1/(781250)
				-- a1= -1
				-- b0= 725.3026
				-- b1= -669.2253
				-- temp must have 26 bits
				
				--				725										669
			    temp <= "1011010101" * CURRENT_INPUT - "1010011101" * LAST_INPUT - LAST_OUTPUT;
				
				CURRENT_OUTPUT <= temp;

		 END IF;

			
			
	end if;
end process;

FILTER_OUT <= CURRENT_OUTPUT;

end Behavioral;