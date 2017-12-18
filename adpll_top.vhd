LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use ieee.numeric_std.ALL;
use work.sine_lut_pkg.all;
use IEEE.MATH_REAL.ALL;

entity adpll_top is
	GENERIC (
		SIMULATION		: natural := 1;
		FTW_WIDTH    	: natural := 32;			-- 35
		LOOPF_WIDTH		: natural := 30;			-- 30
		DDS_CLOCK		: natural := 50_000_000		-- 50e6
	);
	PORT (	
				CLOCK_50			: IN STD_LOGIC;
				
				SW 				: IN STD_LOGIC_VECTOR(17 DOWNTO 0);
				KEY				: IN STD_LOGIC_VECTOR(3 DOWNTO 0);

				-- I2S

				AUD_ADCDAT		: inout std_logic;
				AUD_BCLK		: inout std_logic;
				AUD_ADCLRCK		: inout std_logic;
				AUD_DACLRCK		: inout std_logic;
				I2C_SDAT		: inout std_logic;
				AUD_XCK			: out std_logic;
				AUD_DACDAT		: out std_logic;
				I2C_SCLK		: out std_logic;


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
		FILTER_IN_EN 	: IN STD_LOGIC;
		FILTER_IN 	 	: in STD_LOGIC_VECTOR (17 downto 0);
		FILTER_OUT 	 	: out STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0);
		FILTER_OUT_EN 	: out STD_LOGIC);
end component Lowpass;

component dac_i2s is
port (

	CLOCK_50		: in std_logic;
    reset           : in std_logic;
	AUD_ADCDAT	    : inout std_logic;
	AUD_BCLK		: inout std_logic;
	AUD_ADCLRCK	    : inout std_logic;
	AUD_DACLRCK	    : inout std_logic;

	I2C_SDAT		: inout std_logic;

	AUD_XCK		    : out std_logic;
	AUD_DACDAT	    : out std_logic;
	I2C_SCLK		: out	std_logic;


	right_channel_audio_in	: in std_logic_vector(31 downto 0);
	left_channel_audio_in 	: in std_logic_vector(31 downto 0);
	audio_in_available		: in std_logic;

    audio_left          : out std_logic_vector(15 downto 0);
    audio_left_en       : out std_logic;
    audio_right         : out std_logic_vector(15 downto 0);
    audio_right_en      : out std_logic


);
end component dac_i2s;


-----------------------------
------- SIGNALS -------------
-----------------------------


constant DDS_STEP			: real := real(DDS_CLOCK) / 2**real(FTW_WIDTH);

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
SIGNAL s_ftw_rf_in			: std_logic_vector(FTW_WIDTH-1 downto 0)  := (others => '0');


SIGNAL s_loopfilter				: std_logic_vector(LOOPF_WIDTH-1 DOWNTO 0) := (others => '0');
SIGNAL s_ftw_nco				: std_logic_vector(FTW_WIDTH-1 downto 0)  := (others => '0');
signal s_nco_offset				: std_logic_vector(FTW_WIDTH-1 downto 0)  := (others => '0');
signal s_loopfilter_en			: std_logic;

signal s_fmdemod				: std_logic_vector(LOOPF_WIDTH-1 DOWNTO 0) := (others => '0');
signal s_fmdemod_en				: std_logic;

--signal s_freq					: real := 0.0;


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

	s_nco_offset <=  std_logic_vector(to_unsigned(integer( 10000000.0/DDS_STEP ), s_ftw_phasemod'length));
	s_ftw_rf_in <= std_logic_vector(to_signed(integer( 10001000.0/DDS_STEP ), s_ftw_phasemod'length) + signed(s_phasemod) * 512); 
	s_ftw_nco <= std_logic_vector(signed(s_nco_offset) + signed(s_loopfilter));

	-- s_ftw_nco <= std_logic_vector(signed(s_nco_offset));

	-- s_ftw_phasemod <= x"00000000"; 

	s_ftw_phasemod <=  std_logic_vector(to_unsigned(integer( 1000.0/DDS_STEP ), s_ftw_phasemod'length));


	g0: IF SIMULATION = 1 GENERATE
	BEGIN
		Debug: PROCESS (sys_clk)
			variable v_freq : real := 0.0;
			variable v_freq_hz : integer := 0;
		BEGIN
			v_freq := real(to_integer(unsigned(s_ftw_nco))) * real(DDS_CLOCK) / 2**real(FTW_WIDTH);
			v_freq_hz := integer(v_freq);
		END PROCESS Debug;
	END GENERATE g0;


	

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



-- phase
-- 3FFF == 90 deg ; 360/65535 = 0.00549324788281071183337148088808
-- 1FFF == 45 deg
-- 1555 == 30 deg.
-- 0AAA == 15 deg.
--
-- phase detector output near zero when phase_i = 3FFF (90deg)
-- 15 deg phase error: 0x3FFF - 0x0AAA = 0x3555
-- 30 deg phase error: 0x3FFF - 0x1555 = 0x2AAA
-- 45 deg phase error: 0x3FFF - 0x1FFF = 0x2000

RF_IN : dds_synthesizer
	GENERIC MAP (
		ftw_width => FTW_WIDTH
	)
	PORT MAP (
		clk_i	=> sys_clk,
		rst_i 	=> reset,
		ftw_i	=> s_ftw_rf_in, 
		phase_i	=>  x"2000",		
		ampl_o 	=> s_rf_in			
									
	);
	
	
VCOSin : dds_synthesizer
	GENERIC MAP (
		ftw_width => FTW_WIDTH
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
		ftw_width => FTW_WIDTH
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
		ftw_width => FTW_WIDTH
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
    	stage 	=> 6			-- average over 2^6=64 samples
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
		FILTER_OUT 		=> s_loopfilter,
		FILTER_OUT_EN	=> s_loopfilter_en
	);

	

-- MixerCos : MultPhaseDet 
-- 		PORT MAP 
-- 		(
-- 			REF => s_rf_in,
-- 			VCO => s_vco_cos,
-- 			SOUT => s_mixer_cos
-- 		);
	
	
-- LPFCos : LPF2
-- 	PORT MAP (
-- 		clk 		=> sys_clk,
-- 		reset_n 	=> reset_n,
-- 		ast_sink_valid => '1',
-- 		ast_sink_data 	=> s_mixer_cos(27 DOWNTO 12),
-- 		ast_source_data => s_mixer_cos_fil
-- 	);
	

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

sample_avg_i2 : sample_avg
	GENERIC MAP(
		d_width	=> LOOPF_WIDTH,
    	stage 	=> 4			-- average over 2^6=64 samples
	)
	PORT map (
		clk			=>	sys_clk,
		data_in_en	=>	s_loopfilter_en,
		reset_n		=> reset_n,
		data_in		=> s_loopfilter,
		data_out	=> s_fmdemod,
		ce			=> s_fmdemod_en
	);	


dac_i2s_i1 : dac_i2s
port map (

	CLOCK_50		=> sys_clk,
    reset          	=> reset,
	AUD_ADCDAT	    => AUD_ADCDAT,
	AUD_BCLK		=> AUD_BCLK,
	AUD_ADCLRCK	    => AUD_ADCLRCK,
	AUD_DACLRCK	    => AUD_ADCLRCK,
	I2C_SDAT		=> I2C_SDAT,
	AUD_XCK		    => AUD_XCK,
	AUD_DACDAT	    => AUD_DACDAT,
	I2C_SCLK		=> I2C_SCLK,
	right_channel_audio_in	=> s_fmdemod & "00",
	left_channel_audio_in 	=> s_fmdemod & "00",
	audio_in_available		=> s_fmdemod_en,
    audio_left      		=> open,
    audio_left_en   		=> open,
    audio_right				=> open,
    audio_right_en			=> open
);


end Behavioral;
