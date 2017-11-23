library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
USE IEEE.STD_LOGIC_SIGNED.all;


entity sample_avg is
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
end sample_avg;


architecture Behavioral of sample_avg is

    component average2 is
        GENERIC (
                    d_width		: natural := 16
                    );
        PORT (
                    clk			: IN STD_LOGIC;
                    data_in_en	: IN STD_LOGIC;
                    reset_n		: IN STD_LOGIC;
                    data_in		: IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
                    data_out	: OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
                    ce			: OUT STD_LOGIC
        );	
    end component average2;


    type vector16 is array (natural range <>) of std_logic_vector(d_width-1 downto 0);
    signal s_signal : vector16(stage downto 0);
    signal s_ce : std_logic_vector(stage downto 0);


begin


s_signal(0) <= data_in;
s_ce(0) <= data_in_en;

data_out  <= s_signal(stage);
ce <= s_ce(stage);

GEN_REG:
    for I in 0 to stage-1 generate
            REG0: average2 
                generic map (d_width => d_width)
                port map (
                    clk => clk,
                    reset_n => reset_n,
                    data_in_en => s_ce(I),
                    data_in => s_signal(I),
                    data_out => s_signal(I+1),
                    ce => s_ce(I+1)
                );
    end generate;
end Behavioral;




------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
USE IEEE.STD_LOGIC_SIGNED.all;

entity average2 is
	GENERIC (
				d_width		: natural := 16
	);
	PORT (
				clk			: IN STD_LOGIC;
				data_in_en	: IN STD_LOGIC;
				reset_n		: IN STD_LOGIC;
				data_in		: IN STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
				data_out	: OUT STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
				ce			: OUT STD_LOGIC
	);	
end average2;


architecture Behavioral of average2 is
SIGNAL sample		: STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);
SIGNAL counter		: INTEGER RANGE 0 TO 3 := 0;
SIGNAL temp			: STD_LOGIC_VECTOR(d_width-1 DOWNTO 0);

begin
    data_out <= temp;
    PROCESS (clk)
    BEGIN
        IF (reset_N='0') THEN
            counter <= 0;
        ELSE
            IF (clk'event and clk='1') THEN
                IF (data_in_en='1') THEN
                    cASE (counter) IS
                        WHEN 1 => 		counter <= 0;
                                            --ce <= '1';
                        WHEN OTHERS => counter <= counter + 1;
                                            --ce <= '0';
                    END CASE;
                END IF;
            END IF;
        END IF;
    END PROCESS;
        
    PROCESS (clk)
    BEGIN
        IF (reset_N='0') THEN
            sample <= (others => '0');
            temp <= (others => '0');
            ce <= '0';
        ELSE
            IF (clk'event and clk='1') THEN
                ce <= '0';
                IF (data_in_en='1') THEN
                    cASE (counter) IS
                        WHEN 0 => 	sample <= data_in;
                                    ce <= '0';
                        WHEN 1 => 	temp <= std_logic_vector(
                                                        resize(
                                                            shift_right(
                                                                resize(signed(sample),sample'length+2) + 
                                                                resize(signed(data_in),data_in'length+2)
                                                            ,1)
                                                        ,data_in'length)
                                                    );
                                        ce <= '1';
                        WHEN OTHERS => NULL;
                    END CASE;
                END IF;
            END IF;	
        END IF;
    END PROCESS;            
end Behavioral;
