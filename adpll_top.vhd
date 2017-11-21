LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;
use work.sine_lut_pkg.all;

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


component MultPhaseDet is
	Port ( 
		REF : in STD_LOGIC_VECTOR (13 downto 0);
		VCO : in STD_LOGIC_VECTOR (13 downto 0);
		SOUT : out STD_LOGIC_VECTOR (27 downto 0));
end component;

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




component LPF2 is
	port (
		clk              : in  std_logic                     := '0';             --                     clk.clk
		reset_n          : in  std_logic                     := '0';             --                     rst.reset_n
		ast_sink_data    : in  std_logic_vector(15 downto 0) := (others => '0'); --   avalon_streaming_sink.data
		ast_sink_valid   : in  std_logic                     := '0';             --                        .valid
		ast_sink_error   : in  std_logic_vector(1 downto 0)  := (others => '0'); --                        .error
		ast_source_data  : out std_logic_vector(31 downto 0);                    -- avalon_streaming_source.data
		ast_source_valid : out std_logic;                                        --                        .valid
		ast_source_error : out std_logic_vector(1 downto 0)                      --                        .error
	);
end component LPF2;


-----------------------------
------- SIGNALS -------------
-----------------------------


signal reset				: STD_LOGIC := '0';
signal reset_n				: STD_LOGIC;

SIGNAL sys_clk				: STD_LOGIC;
SIGNAL sys_clk_90deg		: STD_LOGIC;	
SIGNAL sys_clk_180deg 		: STD_LOGIC;	
SIGNAL sys_clk_270deg 		: STD_LOGIC;

SIGNAL s_adc_a_data			: STD_LOGIC_VECTOR(13 DOWNTO 0);
SIGNAL s_adc_b_data			: STD_LOGIC_VECTOR(13 DOWNTO 0);
	
SIGNAL s_vco_sin			: STD_LOGIC_VECTOR(13 DOWNTO 0);
	
SIGNAL s_mixer_sin	: STD_LOGIC_VECTOR(27 DOWNTO 0);
SIGNAL s_mixer_cos	: STD_LOGIC_VECTOR(27 DOWNTO 0);


begin

	reset <= not KEY(0);
	reset_n <= not reset;

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




-------------------
	PROCESS (sys_clk)
		BEGIN
			IF (RISING_EDGE(sys_clk)) THEN
				--DA <= not dds_sin(13) & dds_sin(12 DOWNTO 0);
				--DB <= not dds_ref(13) & dds_ref(12 DOWNTO 0);
				DA <= s_adc_a_data;
				DB <= s_adc_b_data;				
			END IF;
	END PROCESS;
	
	PROCESS (ADA_DCO)
			BEGIN
				IF(RISING_EDGE(ADA_DCO)) THEN
					s_adc_a_data <= ADA_D;
				END IF;
	END PROCESS;


	PROCESS (ADB_DCO)
			BEGIN
				IF(RISING_EDGE(ADA_DCO)) THEN
					s_adc_b_data <= ADB_D;
				END IF;
	END PROCESS;
--------------------



MixerSin : MultPhaseDet 
		PORT MAP 
		(
			REF => s_adc_a_data,
			VCO => s_vco_sin,
			SOUT => s_mixer_sin
		);


LPFSin : LPF2
	PORT MAP (
		clk => sys_clk,
		reset_n => reset_n,
		ast_sink_valid => '1',
		ast_sink_data => s_mixer_sin(27 DOWNTO 12),
		ast_source_data => open
	);


pll_sysclk_i1 : pll_sysclk
	PORT MAP (
		inclk0 	=> CLOCK_50,
		c0		=> sys_clk,
		c1		=> sys_clk_90deg,
		c2		=> sys_clk_180deg,
		c3		=> sys_clk_270deg,
		locked	=> open
	);


VCO_SIN_i1 : dds_synthesizer
    PORT MAP (
		clk_i	=> sys_clk,
		rst_i   => reset,
		ftw_i	=> x"028F5C28",
		phase_i => x"0000",
		ampl_o  => s_vco_sin
	);



end Behavioral;
