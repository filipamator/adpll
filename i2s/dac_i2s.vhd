library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;


entity dac_i2s is
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
end entity dac_i2s;

architecture rtl of dac_i2s is

component avconf is
	port (
		I2C_SCLK		: out std_logic;
		I2C_SDAT		: inout std_logic;
		CLOCK_50		: in std_logic;
		reset			: in std_logic
	);
end component avconf;



component Audio_Controller is
--	generic (
--		AUDIO_DATA_WIDTH
--		BIT_COUNTER_INIT
--	);
	port (
	-- // Inputs
		CLOCK_50						: in std_logic;
		reset							: in std_logic;
		clear_audio_in_memory	: in std_logic;
		read_audio_in				: in std_logic;
		clear_audio_out_memory	: in std_logic;
		left_channel_audio_out	: in std_logic_vector(32 downto 1);
		right_channel_audio_out	: in std_logic_vector(32 downto 1);
		write_audio_out			: in std_logic;
		AUD_ADCDAT					: in std_logic;
	-- // Bidirectionals
		AUD_BCLK						: inout std_logic;
		AUD_ADCLRCK					: inout std_logic;
		AUD_DACLRCK					: inout std_logic;
		-- // Outputs
		audio_in_available		: out std_logic;
		left_channel_audio_in	: out std_logic_vector(32 downto 1);
		right_channel_audio_in	: out std_logic_vector(32 downto 1);
		audio_out_allowed			: out std_logic;
		AUD_XCK						: out std_logic;
		AUD_DACDAT					: out std_logic
	);
end component Audio_Controller;


constant PHASE_WIDTH 	: integer := 10;
constant AMPL_WIDTH 	: integer := 16;
constant ftw_width 		: integer := 32;



component fifo IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		usedw		: OUT STD_LOGIC_VECTOR (1 DOWNTO 0)
	);
END component fifo;



component echo is
	generic (
		DELAY		: natural := 4800
	);
	port (	
		clk 		: in std_logic;
		ce			: in std_logic;
		data_in	: in std_logic_vector(31 downto 0);
		data_out : out std_logic_vector(31 downto 0)
	);
end component echo;

component gen48khz is
generic (
		CLKCOUNTER	: natural := 1000
		
);
port (
		clock 	: in std_logic;
		reset_n	: in std_logic;
		enable	: out std_logic
);
end component gen48khz;



--signal audio_in_available 		: std_logic;
--signal left_channel_audio_in 	: std_logic_vector(32 downto 1);
--signal right_channel_audio_in : std_logic_vector(32 downto 1);
signal read_audio_in 			: std_logic;
signal audio_out_allowed 		: std_logic;
signal left_channel_audio_out : std_logic_vector(32 downto 1);
signal right_channel_audio_out : std_logic_vector(32 downto 1);
signal write_audio_out 			: std_logic;
signal delay_cnt					: integer;
signal delay						: integer;
signal snd							: std_logic;
signal sound						: std_logic_vector(31 downto 0);

signal	s_audio				: std_logic_vector(15 downto 0);
signal	s_audio2				: std_logic_vector(15 downto 0);
signal	s_dds					: std_logic_vector(15 downto 0);
signal	s_audio_en2			: std_logic;

signal	s_right_in			: std_logic_vector(31 downto 0);
signal 	s_left_in			: std_logic_vector(31 downto 0);

signal	s_right_in_del			: std_logic_vector(31 downto 0);
signal 	s_left_in_del			: std_logic_vector(31 downto 0);
signal	s_fft_left,s_fft_right	: std_logic_vector(15 downto 0);


signal reset_n : std_logic;

begin

reset_n <= not reset;


-- with echo
--left_channel_audio_out	<=   s_left_in_del + s_left_in;
--right_channel_audio_out	<=   s_right_in_del + s_right_in;

-- without echo
left_channel_audio_out	<=   s_left_in;
right_channel_audio_out	<=   s_right_in;

read_audio_in <= '1';
sound <= s_audio2 & x"0000" when s_audio2(15) = '0' else
			s_audio2 & x"1111" when s_audio2(15) = '1';
write_audio_out <= s_audio_en2 and audio_out_allowed;


process (CLOCK_50)
begin
    if (CLOCK_50='1' and CLOCK_50'event) then
        if s_audio_en2='1' then
            audio_left_en <= '1';
            audio_left <= s_left_in(28 downto 13);
            audio_right_en  <= '1';
            audio_right <= s_right_in(28 downto 13);
        else
            audio_left_en <= '0';
            audio_right_en  <= '0';
        end if;
    end if;
end process;
		
	
	
Audio_Controller_i1 : Audio_Controller 
	port map (
		CLOCK_50						=> CLOCK_50,
		reset							=> reset,
		clear_audio_in_memory 	=> '0',
		read_audio_in				=> read_audio_in,
		clear_audio_out_memory	=> '0',
		left_channel_audio_out	=> left_channel_audio_out,
		right_channel_audio_out	=> right_channel_audio_out,
		write_audio_out			=> write_audio_out,
		AUD_ADCDAT					=> AUD_ADCDAT,
		AUD_BCLK						=> AUD_BCLK,
		AUD_ADCLRCK					=> AUD_ADCLRCK,
		AUD_DACLRCK					=> AUD_DACLRCK,
		audio_in_available		=> open, -- audio_in_available,
		left_channel_audio_in	=> open, -- left_channel_audio_in,
		right_channel_audio_in	=> open, -- right_channel_audio_in,
		audio_out_allowed			=> audio_out_allowed,
		AUD_XCK						=> AUD_XCK,
		AUD_DACDAT					=> AUD_DACDAT
);	
	

avconf_i1 : avconf
	port map (
		I2C_SCLK	=> I2C_SCLK,
		I2C_SDAT	=> I2C_SDAT,
		CLOCK_50 => CLOCK_50,
		reset		=> reset
	);
	
	
gen48khz_i1 : gen48khz
	port map (
		clock => CLOCK_50,
		reset_n => reset_n,
		enable => s_audio_en2
		
	);


fifo_left : fifo
	port map (
		clock		=> CLOCK_50,
		data		=> left_channel_audio_in,
		rdreq		=> s_audio_en2,
		wrreq		=> audio_in_available,
		empty		=> open,
		full		=> open,
		q			=> s_left_in,
		usedw		=> open
	);
	

fifo_right : fifo
	port map (
		clock		=> CLOCK_50,
		data		=> right_channel_audio_in,
		rdreq		=> s_audio_en2,
		wrreq		=> audio_in_available,
		empty		=> open,
		full		=> open,
		q			=> s_right_in,
		usedw		=> open
	);


	
-- echo_left : echo
-- 		port map (
-- 			clk => CLOCK_50,
-- 			ce => write_audio_out,
-- 			data_in => s_left_in,
-- 			data_out => s_left_in_del
-- 		);
	
-- echo_right : echo
-- 		port map (
-- 			clk => CLOCK_50,
-- 			ce => write_audio_out,
-- 			data_in => s_right_in,
-- 			data_out => s_right_in_del
-- 		);
	

end rtl;