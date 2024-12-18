library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tilt_position_controller is
port ( 
           input_tilt_1    : in std_logic;
           input_tilt_2    : in std_logic;
           input_tilt_3    : in std_logic;
           output_tilt_o : out STD_LOGIC_VECTOR(2 downto 0)
     );
end entity tilt_position_controller;

architecture mix of tilt_position_controller is
begin
    output_tilt_o(0) <= input_tilt_1;
    output_tilt_o(1) <= input_tilt_2;
    output_tilt_o(2) <= input_tilt_3; 
        
end architecture mix;
