LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;

entity adpll_top_tb is
end adpll_top_tb;

architecture Behavioral of adpll_top_tb is


component adpll_top is
	PORT (	
				CLOCK_50			: IN STD_LOGIC;
				
				SW 				: IN STD_LOGIC_VECTOR(17 DOWNTO 0);
				KEY				: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
				
				-- Clocks for ADC
				FPGA_CLK_B_N	: OUT STD_LOGIC;
				FPGA_CLK_B_P	: OUT STD_LOGIC;
				FPGA_CLK_A_N	: OUT STD_LOGIC;
				FPGA_CLK_A_P	: OUT STD_LOGIC;
				--  ADC Data Clock Output
				ADA_DCO			: IN STD_LOGIC;
				ADB_DCO			: IN STD_LOGIC;
				-- ADC data bits
				ADA_D			: IN STD_LOGIC_VECTOR(13 DOWNTO 0);
				ADB_D			: IN STD_LOGIC_VECTOR(13 DOWNTO 0);
				-- ADC output enable active low
				ADA_OE		: OUT STD_LOGIC;
				ADB_OE		: OUT STD_LOGIC;
				-- ADC Out-of-Range Indicator.
				ADA_OR		: IN STD_LOGIC;
				ADB_OR		: IN STD_LOGIC;
				-- Data Format Select Pin
				AD_SCLK		: INOUT STD_LOGIC;
				--  Duty Cycle Stabilizer Select
				AD_SDIO		: INOUT STD_LOGIC;

				ADA_SPI_CS	: OUT STD_LOGIC;
				ADB_SPI_CS	: OUT STD_LOGIC;	
				-- DAC data bits
				DA				: OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
				DB				: OUT STD_LOGIC_VECTOR(13 DOWNTO 0)
				
			);
			
end component;


component adpll_top_tester is
	PORT (	
				CLOCK_50		: OUT STD_LOGIC;
				
				SW 				: OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
				KEY				: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
				
				-- Clocks for ADC
				FPGA_CLK_B_N	: IN STD_LOGIC;
				FPGA_CLK_B_P	: IN STD_LOGIC;
				FPGA_CLK_A_N	: IN STD_LOGIC;
				FPGA_CLK_A_P	: IN STD_LOGIC;
				--  ADC Data Clock Output
				ADA_DCO			: OUT STD_LOGIC;
				ADB_DCO			: OUT STD_LOGIC;
				-- ADC data bits
				ADA_D			: OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
				ADB_D			: OUT STD_LOGIC_VECTOR(13 DOWNTO 0);
				-- ADC output enable active low
				ADA_OE		: IN STD_LOGIC;
				ADB_OE		: IN STD_LOGIC;
				-- ADC Out-of-Range Indicator.
				ADA_OR		: OUT STD_LOGIC;
				ADB_OR		: OUT STD_LOGIC;
				-- Data Format Select Pin
				AD_SCLK		: INOUT STD_LOGIC;
				--  Duty Cycle Stabilizer Select
				AD_SDIO		: INOUT STD_LOGIC;

				ADA_SPI_CS	: IN STD_LOGIC;
				ADB_SPI_CS	: IN STD_LOGIC;
						
				-- DAC data bits
				DA			: IN STD_LOGIC_VECTOR(13 DOWNTO 0);
				DB			: IN STD_LOGIC_VECTOR(13 DOWNTO 0)
				
				
			);
			
end component;



signal CLOCK_50	:  STD_LOGIC;
				
signal SW 				:  STD_LOGIC_VECTOR(17 DOWNTO 0);
signal KEY				:  STD_LOGIC_VECTOR(3 DOWNTO 0);
				
-- Clocks for ADC
signal FPGA_CLK_B_N	:  STD_LOGIC;
signal FPGA_CLK_B_P	:  STD_LOGIC;
signal FPGA_CLK_A_N	:  STD_LOGIC;
signal FPGA_CLK_A_P	:  STD_LOGIC;
--  ADC Data Clock Output
signal ADA_DCO		:  STD_LOGIC;
signal ADB_DCO		:  STD_LOGIC;
-- ADC data bits
signal ADA_D		:  STD_LOGIC_VECTOR(13 DOWNTO 0);
signal ADB_D		:  STD_LOGIC_VECTOR(13 DOWNTO 0);
-- ADC output enable active low
signal ADA_OE		:  STD_LOGIC;
signal ADB_OE		:  STD_LOGIC;
-- ADC Out-of-Range Indicator.
signal ADA_OR		:  STD_LOGIC;
signal ADB_OR		:  STD_LOGIC;
-- Data Format Select Pin
signal AD_SCLK		:  STD_LOGIC;
--  Duty Cycle Stabilizer Select
signal AD_SDIO		:  STD_LOGIC;
signal ADA_SPI_CS	:  STD_LOGIC;
signal ADB_SPI_CS	:  STD_LOGIC;			
-- DAC data bits
signal DA			:  STD_LOGIC_VECTOR(13 DOWNTO 0);
signal DB			:  STD_LOGIC_VECTOR(13 DOWNTO 0);
				
begin


 adpll_top_tester_i1 : adpll_top_tester 
	PORT MAP (	
			CLOCK_50    => CLOCK_50,	
			SW 	        => SW,
			KEY			=> KEY,
			-- Clocks for ADC
			FPGA_CLK_B_N => FPGA_CLK_B_N,
			FPGA_CLK_B_P => FPGA_CLK_B_P,
			FPGA_CLK_A_N => FPGA_CLK_A_N,
			FPGA_CLK_A_P => FPGA_CLK_A_P,
			--  ADC Data Clock Output
			ADA_DCO	=> ADA_DCO,
			ADB_DCO	=> ADB_DCO,
			-- ADC data bits
			ADA_D => ADA_D,		
			ADB_D => ADB_D,
			-- ADC output enable active low
			ADA_OE => ADA_OE,
			ADB_OE => ADB_OE,
			-- ADC Out-of-Range Indicator.
			ADA_OR	=> ADA_OR,
			ADB_OR	=> ADB_OR,
			-- Data Format Select Pin
			AD_SCLK	=> AD_SCLK,
			--  Duty Cycle Stabilizer Select
			AD_SDIO	=> AD_SDIO,
			ADA_SPI_CS => ADA_SPI_CS,
			ADB_SPI_CS => ADB_SPI_CS,
			-- DAC data bits
			DA => DA,
			DB => DB	
	);
			

 adpll_top_i1 : adpll_top 
	PORT MAP (	
			CLOCK_50    => CLOCK_50,	
			SW 	        => SW,
			KEY			=> KEY,
			-- Clocks for ADC
			FPGA_CLK_B_N => FPGA_CLK_B_N,
			FPGA_CLK_B_P => FPGA_CLK_B_P,
			FPGA_CLK_A_N => FPGA_CLK_A_N,
			FPGA_CLK_A_P => FPGA_CLK_A_P,
			--  ADC Data Clock Output
			ADA_DCO	=> ADA_DCO,
			ADB_DCO	=> ADB_DCO,
			-- ADC data bits
			ADA_D => ADA_D,		
			ADB_D => ADB_D,
			-- ADC output enable active low
			ADA_OE => ADA_OE,
			ADB_OE => ADB_OE,
			-- ADC Out-of-Range Indicator.
			ADA_OR	=> ADA_OR,
			ADB_OR	=> ADB_OR,
			-- Data Format Select Pin
			AD_SCLK	=> AD_SCLK,
			--  Duty Cycle Stabilizer Select
			AD_SDIO	=> AD_SDIO,
			ADA_SPI_CS => ADA_SPI_CS,
			ADB_SPI_CS => ADB_SPI_CS,
			-- DAC data bits
			DA => DA,
			DB => DB	
	);
		

end Behavioral;