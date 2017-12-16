LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity rc is
	Port ( 	
                i_clock		 : in STD_LOGIC;
				i_reset	     : in STD_LOGIC;
				i_data_en    : IN STD_LOGIC;
				i_data 	     : in STD_LOGIC_VECTOR (31 downto 0);
				o_data 	     : out STD_LOGIC_VECTOR (31 downto 0)
        );
end rc;

architecture Behavioral of rc is


component int32_fp
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;

component fp_int32
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;

component fp_mult
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;

component fp_add
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;

component fp_sub
	PORT
	(
		aclr		: IN STD_LOGIC ;
		clock		: IN STD_LOGIC ;
		dataa		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
end component;


    signal s_data   : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_result,s_data_fp  : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    signal s_b0 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_b1 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_a1 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');

    signal s_xn : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_xn1 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_yn : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_yn1 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    


    signal s_mult1 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_mult2 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_mult3 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_temp : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');


    signal s_sum1,s_sum2,s_sumr : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    signal s_sum12,s_sum22,s_sumr2 : STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
    

	-- signal CURRENT_INPUT 	: STD_LOGIC_VECTOR (17 downto 0) := (others => '0');
	-- signal s_last_input 		: STD_LOGIC_VECTOR (17 downto 0) := (others => '0');
	-- signal s_last_output 		: STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0) := (others => '0');
	-- signal CURRENT_OUTPUT 	: STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0) := (others => '0');

	-- SIGNAL temp : STD_LOGIC_VECTOR (LOOPF_WIDTH-1 downto 0) := (others => '0');

	
	-- signal COUNT : STD_LOGIC := '0';

begin


--	CURRENT_INPUT <= FILTER_IN;


	process(i_clock,i_reset)
	begin
		if (i_reset = '1') then
			-- LAST_INPUT <= (others => '0');
			-- LAST_OUTPUT <= (others => '0');
			-- CURRENT_OUTPUT <= (others => '0');
			-- temp <= (others => '0');
		elsif (i_clock='1' and i_clock'event) then
			if (i_data_en='1') then
				for i in -1 to 27 loop
				    case i is
						when 0 =>
                            s_data <= i_data;

                        when 6 =>               

                            s_b0 <= x"40400000";    -- 3
                            s_b1 <= x"00000000";
                            s_a1 <= x"00000000";

                            s_xn <= s_data_fp;              -- integer to float conversion -- 6 clock cycles
                            -- s_xn1 <= x"00000000";
                            -- s_yn1 <= x"00000000";


                            -- s_mult1 = s_b0 * s_xn
                            -- s_mult2 = s_b1 * s_xn1
                            -- s_mult3 = s_a1 * s_yn1

                        when 7 =>

                            s_xn1 <= s_xn;

                        when 12 =>

                            -- s_sumr = s_b0 * s_xn + s_b1 * s_xn1

                            s_sum1 <= s_mult1;
                            s_sum2 <= s_mult2;
                            
                            s_temp <= s_mult3;

                        when 20 => 

                            -- s_sumr2 =  s_b0 * s_xn + s_b1 * s_xn1   -  s_a1 * s_yn1

                            s_sum12 <= s_sumr;
                            s_sum22 <= s_temp;

                        when 27 => 

                            s_result <= s_sumr2;    -- current result a.k.a s_yn
                            s_yn1 <= s_sumr2;       -- assign current result to last result


                        when others =>
                    end case;		
				end loop;



				-- LAST_INPUT <= CURRENT_INPUT;
				-- LAST_OUTPUT <= CURRENT_OUTPUT;

			    -- temp <= "1011010101" * CURRENT_INPUT - "1010011101" * LAST_INPUT - LAST_OUTPUT;
				-- CURRENT_OUTPUT <= temp;

		    END IF;
	    end if;
end process;

-- FILTER_OUT <= CURRENT_OUTPUT;



int32_fp_i1 : int32_fp 
	port map
	(
		aclr    => i_reset,
		clock	=> i_clock,
		dataa   => s_data,
		result	=> s_data_fp
	);


fp_mult_i1 : fp_mult
	port map
	(
		aclr    => i_reset,
		clock	=> i_clock,
		dataa	=> s_b0,
		datab	=> s_xn,
		result	=> s_mult1
	);


fp_mult_i2 : fp_mult
	port map
	(
		aclr    => i_reset,
		clock	=> i_clock,
		dataa	=> s_b1,
		datab	=> s_xn1,   -- 1
		result	=> s_mult2
	);


fp_mult_i3 : fp_mult
	port map
	(
		aclr    => i_reset,
		clock	=> i_clock,
		dataa	=> s_a1,
		datab	=> s_yn1,
		result	=> s_mult3
	);

fp_add_i1 : fp_add
	port map
	(
		aclr    => i_reset,
		clock	=> i_clock,
		dataa	=> s_sum1,
		datab	=> s_sum2,
		result	=> s_sumr
	);   


fp_sub_i1 : fp_sub
	port map
	(
		aclr    => i_reset,
		clock	=> i_clock,
		dataa	=> s_sum12,
		datab	=> s_sum22,
		result	=> s_sumr2
	);   

end Behavioral;