LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;
use work.sine_lut_pkg.all;



entity adpll_top_tester is
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
			
end adpll_top_tester;


architecture Behavioral of adpll_top_tester is

	component dds_synthesizer is
	generic(
	    ftw_width : integer := 32
			);
	port(
		clk_i   : in  std_logic;
		rst_i   : in  std_logic;
		ftw_i   : in  std_logic_vector(ftw_width-1 downto 0);
		phase_i : in  std_logic_vector(PHASE_WIDTH-1 downto 0);
		phase_o : out std_logic_vector(PHASE_WIDTH-1 downto 0);
		ampl_o  : out std_logic_vector(AMPL_WIDTH-1 downto 0)
    );
	end component;



signal clock : std_logic := '0';
signal reset : std_logic := '0';
signal dds_data : std_logic_vector(13 downto 0) := (others => '0');

begin

    -- 50 MHz clock
    clock <= not (clock) after 10 ns;
    CLOCK_50 <= clock;

    KEY(0) <= not reset;

    process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';
        wait;
    end process;



    ADA_DCO <= FPGA_CLK_A_P;
    process (FPGA_CLK_A_N)
    begin
        if (FPGA_CLK_A_N='1' and FPGA_CLK_A_N'event) then
            ADA_D <= dds_data;
        end if;
    end process;



DDS_i1 : dds_synthesizer
    PORT MAP (
		clk_i	=> clock,
		rst_i   => reset,
		ftw_i	=> x"3645A1CA",	-- 10.6 MHz
		phase_i => x"0000",
		ampl_o  => dds_data
	);



end Behavioral;