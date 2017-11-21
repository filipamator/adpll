LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;


entity adpll_top is
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
			
end adpll_top;



architecture Behavioral of adpll_top is



-----------------------------
------- COMPONENTS ----------
-----------------------------
	
	
COMPONENT pll_sysclk IS
	PORT
	(
		inclk0		: IN STD_LOGIC  := '0';
		c0		: OUT STD_LOGIC ;
		c1		: OUT STD_LOGIC ;
		c2		: OUT STD_LOGIC ;
		c3		: OUT STD_LOGIC ;
		locked		: OUT STD_LOGIC 
	);
END COMPONENT pll_sysclk;


SIGNAL sys_clk				: STD_LOGIC;
SIGNAL sys_clk_90deg		: STD_LOGIC;	
SIGNAL sys_clk_180deg 		: STD_LOGIC;	
SIGNAL sys_clk_270deg 		: STD_LOGIC;

SIGNAL r_adc_a_data			: STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL r_adc_b_data			: STD_LOGIC_VECTOR(13 DOWNTO 0);
	

	
begin


	FPGA_CLK_A_P	<=  sys_clk_180deg;
	FPGA_CLK_A_N	<= not sys_clk_180deg;
	FPGA_CLK_B_P	<=  sys_clk_270deg;
	FPGA_CLK_B_N	<= not sys_clk_270deg;	
	
	AD_SCLK			<= '1';				-- DATA FORMAT SEL.
	AD_SDIO			<= '0';				-- DUTY CYCLE STAB.
	ADA_OE			<= '0';
	ADA_SPI_CS		<= '1';
	ADB_OE			<= '0';
	ADB_SPI_CS		<= '1';



	PROCESS (sys_clk)
		BEGIN
			IF (RISING_EDGE(sys_clk)) THEN
				--DA <= not dds_sin(13) & dds_sin(12 DOWNTO 0);
				--DB <= not dds_ref(13) & dds_ref(12 DOWNTO 0);
				DA <= r_adc_a_data;
				DB <= r_adc_b_data;				
			END IF;
	END PROCESS;
	
	PROCESS (ADA_DCO)
			BEGIN
				IF(RISING_EDGE(ADA_DCO)) THEN
					r_adc_a_data <= ADA_D;
				END IF;
	END PROCESS;


	PROCESS (ADB_DCO)
			BEGIN
				IF(RISING_EDGE(ADA_DCO)) THEN
					r_adc_b_data <= ADB_D;
				END IF;
	END PROCESS;



pll_sysclk_i1 : pll_sysclk
	PORT MAP (
		inclk0 	=> CLOCK_50,
		c0		=>	sys_clk,
		c1		=>	sys_clk_90deg,
		c2		=> sys_clk_180deg,
		c3		=> sys_clk_270deg,
		locked	=> open
	);




end Behavioral;
