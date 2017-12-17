LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;




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

	SIGNAL temp : STD_LOGIC_VECTOR (29 downto 0) := (others => '0');


	
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

				-- 1569 z - 676.7

				-- temp <= std_logic_vector("1011010101" * signed(CURRENT_INPUT) - "1010011101" * signed(LAST_INPUT) - signed(LAST_OUTPUT));
			    temp <=  std_logic_vector(x"5C" * signed(CURRENT_INPUT) - x"42" * signed(LAST_INPUT) + signed(LAST_OUTPUT));
				
				CURRENT_OUTPUT <= std_logic_vector ( resize(signed(temp),30) );

		 END IF;

			
			
	end if;
end process;

FILTER_OUT <= CURRENT_OUTPUT;

end Behavioral;