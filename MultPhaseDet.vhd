
LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use ieee.std_logic_arith.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;


entity MultPhaseDet is

Port ( 
	REF : in STD_LOGIC_VECTOR (13 downto 0);
	VCO : in STD_LOGIC_VECTOR (13 downto 0);
	SOUT : out STD_LOGIC_VECTOR (27 downto 0));
end MultPhaseDet;

architecture Behavioral of MultPhaseDet is

	signal OUT_TEMP : STD_LOGIC_VECTOR (27 downto 0);
begin
	OUT_TEMP <= VCO * REF;
	SOUT <= OUT_TEMP;
end Behavioral;