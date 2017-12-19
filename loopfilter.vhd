LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity loopfilter is
	GENERIC (
				LOOPF_WIDTH  : natural
		);
	Port ( 	
			i_clk 			 	: in STD_LOGIC;
			i_rst 			 	: in STD_LOGIC;
			i_filter_in_en 		: in STD_LOGIC;
			i_filter_in	 		: in STD_LOGIC_VECTOR (17 downto 0);
			o_filter_out_en		: out STD_LOGIC;
			o_filter_out 	 	: out STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0));
end loopfilter;

architecture RTL of loopfilter is
	signal s_current_input 	: STD_LOGIC_VECTOR (17 downto 0) := (others => '0');
	signal s_last_input 		: STD_LOGIC_VECTOR (17 downto 0) := (others => '0');
	signal s_current_output 	: STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0) := (others => '0');
begin

	s_current_input <= i_filter_in;
	o_filter_out <= s_current_output;

process(i_clk,i_rst)
	begin
		if (i_rst = '1') then
			s_last_input <= (others => '0');
			s_current_output <= (others => '0');
		elsif (i_clk='1' and i_clk'event) then
			if (i_filter_in_en='1') THEN		
				s_last_input <= s_current_input;
				s_current_output <= std_logic_vector ( resize(  x"5C" * signed(s_current_input) - x"42" * signed(s_last_input) + signed(s_current_output),30) );
				o_filter_out_en <= '1';
			else
				o_filter_out_en <= '0';
			end if;	
	end if;
end process;




-- process(i_clk,i_rst)
-- 	begin
-- 		if (i_rst = '1') then
-- 			s_last_input <= (others => '0');
-- 			s_last_output <= (others => '0');
-- 			s_current_output <= (others => '0');
-- 		elsif (i_clk='1' and i_clk'event) then
-- 			if (i_filter_in_en='1') THEN		
-- 				s_last_input <= s_current_input;
-- 				s_current_output <= std_logic_vector ( resize(  x"5C" * signed(s_current_input) - x"42" * signed(s_last_input) + signed(s_last_output),30) );
-- 				s_last_output <= s_current_output;
-- 				o_filter_out_en <= '1';
-- 			else
-- 				o_filter_out_en <= '0';
-- 			end if;	
-- 	end if;
-- end process;


end RTL;