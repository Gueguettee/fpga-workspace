--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package SD_filter_pkg is

    constant B : integer := 10;
    constant B_FIR : integer := 8;
    constant B_IIR : integer := 8;

    component DFF is
        port (
            D_i : in std_logic;
            rst_i : in std_logic;
            clk_i : in std_logic;
            Q_o : out std_logic;
            Qn_o : out std_logic
        );
    end component DFF;

    component bitstream_gen 
    port (
       clock : in STD_LOGIC;
       bitstream : out STD_LOGIC);
    end component;
    
    component FIR_rect 
    generic (
        N : integer := 886
    );
    port (
        bitstream_i : in STD_LOGIC;
        filtered_o : out STD_LOGIC_VECTOR (B_FIR-1 downto 0);
        reset_i : in STD_LOGIC;
        clock_i : in STD_LOGIC);
    end component;

    component IIR_LP1o
    generic (
        d : integer := 7
    );
    port (
        bitstream_i : in STD_LOGIC;
        filtered_o : out STD_LOGIC_VECTOR (B_IIR-1 downto 0);
        reset_i : in STD_LOGIC;
        clock_i : in STD_LOGIC);
    end component;

end SD_filter_pkg;

package body SD_filter_pkg is

---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
end SD_filter_pkg;
