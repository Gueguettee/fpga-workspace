library ieee;
use ieee.std_logic_1164.all;

package main_control_pkg is

-------------------------- CONSTANTS ------------------------- 

	constant freq_addr_length_c    	: integer := 8;
    constant ifbw_addr_length_c    	: integer := 8;
    constant path_addr_length_c    	: integer := 8;

    constant freq_data_length_c 	: integer := 6;
    constant ifbw_data_length_c 	: integer := 5;
    constant path_data_length_c		: integer := 24;

    constant max_smpl_nmbr_c        : integer := 26; --(23 ifbw values + 3 + 1: 2^3 * 2^23 (+1bit for calcul)) 

    constant filter_bank_controller_length_c : integer := 4;

-------------------------- COMPONENTS ------------------------- 

    component sp_RAM is
        generic(
            DATA_LENGTH         : integer := 8;
            ADDR_LENGTH         : integer := 8
        );
        port
        (
            clk_i       :in  std_logic;
            rst_i       :in  std_logic;
            wr_en_i     :in  std_logic;
            rd_en_i     :in  std_logic;
            wr_addr_i   :in  std_logic_vector(ADDR_LENGTH - 1 downto 0);
            rd_addr_i   :in  std_logic_vector(ADDR_LENGTH - 1 downto 0);
            data_i      :in  std_logic_vector(DATA_LENGTH - 1 downto 0);
            data_o      :out std_logic_vector(DATA_LENGTH - 1 downto 0)
        );
    end component;

end main_control_pkg;