LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;
use work.sine_lut_pkg.all;

entity adpll_top is
	GENERIC (
		FTW_WIDTH    	: natural := 35;			-- 35
		LOOPF_WIDTH		: natural := 30;			-- 30
		DDS_CLOCK		: natural := 50_000_000;	-- 50e6
		DDS_REF_FREQ	: natural := 50_000_000		-- 5e6
	);
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

component sample_avg is
	GENERIC (
		d_width		: natural := 16;
        stage       : natural := 4
	);
	PORT (
		clk			: IN STD_LOGIC;
		data_in_en	: IN STD_LOGIC;
		reset_n		: IN STD_LOGIC;
		data_in		: IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
		data_out	: OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
		ce			: OUT STD_LOGIC
	);	
end component sample_avg;

component Lowpass is
	GENERIC (
		LOOPF_WIDTH  : natural
		);
	Port ( 	
		CLK 			 : in STD_LOGIC;
		RST 			 : in STD_LOGIC;
		FILTER_IN_EN : IN STD_LOGIC;
		FILTER_IN 	 : in STD_LOGIC_VECTOR (17 downto 0);
		FILTER_OUT 	 : out STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0));
end component Lowpass;


-----------------------------
------- SIGNALS -------------
-----------------------------


signal reset				: STD_LOGIC := '0';
signal reset_n				: STD_LOGIC;

SIGNAL sys_clk				: STD_LOGIC;
SIGNAL sys_clk_90deg		: STD_LOGIC;	
SIGNAL sys_clk_180deg 		: STD_LOGIC;	
SIGNAL sys_clk_270deg 		: STD_LOGIC;

SIGNAL s_adc_a_data			: STD_LOGIC_VECTOR(13 DOWNTO 0)  := (others => '0');
SIGNAL s_adc_b_data			: STD_LOGIC_VECTOR(13 DOWNTO 0)  := (others => '0');
	
SIGNAL s_rf_in				: STD_LOGIC_VECTOR(13 DOWNTO 0) := (others => '0');
SIGNAL s_vco_sin			: STD_LOGIC_VECTOR(13 DOWNTO 0) := (others => '0');
SIGNAL s_vco_cos			: STD_LOGIC_VECTOR(13 DOWNTO 0) := (others => '0');
	
SIGNAL s_mixer_sin			: STD_LOGIC_VECTOR(27 DOWNTO 0)  := (others => '0');
SIGNAL s_mixer_cos			: STD_LOGIC_VECTOR(27 DOWNTO 0)  := (others => '0');
SIGNAL s_mixer_sin_fil		: STD_LOGIC_VECTOR(31 DOWNTO 0)  := (others => '0');
SIGNAL s_mixer_cos_fil		: STD_LOGIC_VECTOR(31 DOWNTO 0)  := (others => '0');
SIGNAL s_mixer_sin_fil_avg		: STD_LOGIC_VECTOR(17 DOWNTO 0)  := (others => '0');
SIGNAL s_mixer_sin_fil_avg_en	: STD_LOGIC;

SIGNAL s_phasemod				: STD_LOGIC_VECTOR(13 DOWNTO 0) := (others => '0');
SIGNAL s_ftw_phasemod			: std_logic_vector(FTW_WIDTH-1 downto 0)  := (others => '0');

SIGNAL s_loopfilter				: std_logic_vector(LOOPF_WIDTH-1 DOWNTO 0) := (others => '0');
SIGNAL s_ftw_nco				: std_logic_vector(FTW_WIDTH-1 downto 0)  := (others => '0');
signal s_nco_offset				: std_logic_vector(FTW_WIDTH-1 downto 0)  := (others => '0');


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

	s_nco_offset <= "00011001100110011001100110011001101";
	s_ftw_nco <= std_logic_vector(signed(s_nco_offset) + signed(s_loopfilter) + signed(s_phasemod)   );
	s_ftw_phasemod<="00000000000000010100111110001011010"; 

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






RF_IN : dds_synthesizer
	GENERIC MAP (
		ftw_width => 35
	)
	PORT MAP (
		clk_i	=> sys_clk,
		rst_i 	=> reset,
		ftw_i	=> "00011001100110011011101100100111100",
		phase_i	=>  x"0000",
--		phase_i =>  phasemod16,
		ampl_o 	=> s_rf_in
	);
	
	
VCOSin : dds_synthesizer
	GENERIC MAP (
		ftw_width => 35
	)
	PORT MAP (
		clk_i	=> sys_clk,
		rst_i 	=> reset,
		ftw_i	=> s_ftw_nco,
		phase_i => x"0000",
		ampl_o 	=> s_vco_sin
	);


VCOCos : dds_synthesizer
	GENERIC MAP (
		ftw_width => 35
	)
	PORT MAP (
		clk_i	=> sys_clk,
		rst_i 	=> reset,
		ftw_i	=> s_ftw_nco,
--		phase_i => x"0000",
		phase_i => x"4009",
		ampl_o 	=> s_vco_cos
	);
	
DDSPhaseMod : dds_synthesizer
	GENERIC MAP (
		ftw_width => 35
	)
	PORT MAP (
		clk_i	=> sys_clk,
		rst_i => reset,
		ftw_i	=> s_ftw_phasemod,	-- 1 kHz @ 50 MHz and 35 bits
		phase_i => x"0000",
		ampl_o => s_phasemod
	);
	
		

MixerSin : MultPhaseDet 
	PORT MAP 
	(
		REF 	=> s_rf_in,
		VCO 	=> s_vco_sin,
		SOUT 	=> s_mixer_sin
	);


LPFSin : LPF2
	PORT MAP (
		clk 		=> sys_clk,
		reset_n 	=> reset_n,
		ast_sink_valid => '1',
		ast_sink_data 	=> s_mixer_sin(27 DOWNTO 12),
		ast_source_data => s_mixer_sin_fil
	);


sample_avg_i1 : sample_avg
	GENERIC MAP(
		d_width	=> 18,
    	stage 	=> 6
	)
	PORT map (
		clk			=>	sys_clk,
		data_in_en	=>	'1',
		reset_n		=> reset_n,
		data_in		=> s_mixer_sin_fil(31 downto 14),
		data_out	=> s_mixer_sin_fil_avg,
		ce			=> s_mixer_sin_fil_avg_en
	);	

	
	
LPFPLL : Lowpass 
	GENERIC MAP (
		LOOPF_WIDTH => LOOPF_WIDTH
	)
	PORT MAP (
		CLK 			=> sys_clk,
		RST 			=> reset,
		FILTER_IN_EN 	=> s_mixer_sin_fil_avg_en,
		FILTER_IN 		=> s_mixer_sin_fil_avg,
		FILTER_OUT 		=> s_loopfilter
	);

	

MixerCos : MultPhaseDet 
		PORT MAP 
		(
			REF => s_rf_in,
			VCO => s_vco_cos,
			SOUT => s_mixer_cos
		);
	
	
LPFCos : LPF2
	PORT MAP (
		clk 		=> sys_clk,
		reset_n 	=> reset_n,
		ast_sink_valid => '1',
		ast_sink_data 	=> s_mixer_cos(27 DOWNTO 12),
		ast_source_data => s_mixer_cos_fil
	);
	

-- taninst1 : atan 
-- 	PORT MAP (
-- 		sys_clk => sys_clk,
-- 		i_q => fphase_cos,
-- 		i_i => fphase_sin,
-- 		result => s_tan
-- 	);
	
	


pll_sysclk_i1 : pll_sysclk
	PORT MAP (
		inclk0 	=> CLOCK_50,
		c0		=> sys_clk,
		c1		=> sys_clk_90deg,
		c2		=> sys_clk_180deg,
		c3		=> sys_clk_270deg,
		locked	=> open
	);



end Behavioral;
