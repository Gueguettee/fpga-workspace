--=============================================================================
-- @file vga_controller.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- vga_controller
--
-- @brief This file specifies a VGA controller circuit
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR VGA_CONTROLLER
--=============================================================================
entity vga_controller is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Data/color input
    RedxSI   : in std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSI : in std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSI  : in std_logic_vector(COLOR_BW - 1 downto 0);

    -- Coordinate output
    XCoordxDO : out unsigned(COORD_BW - 1 downto 0);
    YCoordxDO : out unsigned(COORD_BW - 1 downto 0);

    -- Timing output
    HSxSO : out std_logic;
    VSxSO : out std_logic;

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end vga_controller;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of vga_controller is

  signal CountLinexDN, CountLinexDP : unsigned(COORD_BW - 1 downto 0);
  signal CountColumnxDN, CountColumnxDP : unsigned(COORD_BW - 1 downto 0);

  signal XCoordxDS : unsigned(COORD_BW - 1 downto 0);
  signal YCoordxDS : unsigned(COORD_BW - 1 downto 0);

  signal XNextCoordxDN, XNextCoordxDP : unsigned(COORD_BW - 1 downto 0);
  signal YNextCoordxDN, YNextCoordxDP : unsigned(COORD_BW - 1 downto 0);

  signal InsideAreaXxS : std_logic;
  signal InsideAreaYxS : std_logic;
  signal InsideAreaxS : std_logic;

  signal HSxSP, HSxSN : std_logic;
  signal VSxSP, VSxSN : std_logic;

  signal RedxSN, RedxSP : std_logic_vector(COLOR_BW - 1 downto 0);
  signal GreenxSN, GreenxSP : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BluexSN, BluexSP : std_logic_vector(COLOR_BW - 1 downto 0);

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  process(CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then
      CountLinexDP <= (others => '0');
      CountColumnxDP <= (others => '0');

      XNextCoordxDP <= (others => '0');
      YNextCoordxDP <= (others => '0');

      RedxSP <= (others => '0');
      GreenxSP <= (others => '0');
      BluexSP <= (others => '0');

      HSxSP <= '0';
      VSxSP <= '0';

    elsif rising_edge(CLKxCI) then
      CountLinexDP <= CountLinexDN;
      CountColumnxDP <= CountColumnxDN;

      XNextCoordxDP <= XNextCoordxDN;
      YNextCoordxDP <= YNextCoordxDN;

      RedxSP <= RedxSN;
      GreenxSP <= GreenxSN;
      BluexSP <= BluexSN;

      HSxSP <= HSxSN;
      VSxSP <= VSxSN;
    end if;
  end process;

  InsideAreaXxS <= '0' when CountColumnxDN < (HS_PULSE + HS_BACK_PORCH) or CountColumnxDN >= (HS_TOTAL - HS_FRONT_PORCH) else '1';
  InsideAreaYxS <= '0' when CountLinexDN < (VS_PULSE + VS_BACK_PORCH) or CountLinexDN >= (VS_TOTAL - VS_FRONT_PORCH) else '1';
  InsideAreaxS <= InsideAreaXxS and InsideAreaYxS;

  CountLinexDN <= (others => '0') when CountLinexDP = (VS_TOTAL - 1) and CountColumnxDP = (HS_TOTAL - 1) else CountLinexDP + 1 when CountColumnxDP = (HS_TOTAL - 1) else CountLinexDP;
  CountColumnxDN <= (others => '0') when CountColumnxDP = (HS_TOTAL - 1) else CountColumnxDP + 1;

  XCoordxDS <= (others => '0') when InsideAreaxS = '0' else CountColumnxDN - HS_PULSE - HS_BACK_PORCH;
  YCoordxDS <= (others => '0') when InsideAreaYxS = '0' else CountLinexDN - VS_PULSE - VS_BACK_PORCH;

  RedxSN <= BLACK_COLOR when InsideAreaxS = '0' else RedxSI;
  GreenxSN <= BLACK_COLOR when InsideAreaxS = '0' else GreenxSI;
  BluexSN <= BLACK_COLOR when InsideAreaxS = '0' else BluexSI;

  HSxSN <= HS_POLARITY when CountColumnxDN < HS_PULSE else not HS_POLARITY;
  VSxSN <= HS_POLARITY when CountLinexDN < VS_PULSE else not VS_POLARITY;

  XNextCoordxDN <= XCoordxDS + 1 when XCoordxDS < HS_DISPLAY - 1 and InsideAreaxS = '1' else (others => '0');
  YNextCoordxDN <= YCoordxDS;

  RedxSO <= RedxSP;
  GreenxSO <= GreenxSP;
  BluexSO <= BluexSP;

  HSxSO <= HSxSP;
  VSxSO <= VSxSP;

  XCoordxDO <= XNextCoordxDP;
  YCoordxDO <= YNextCoordxDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
