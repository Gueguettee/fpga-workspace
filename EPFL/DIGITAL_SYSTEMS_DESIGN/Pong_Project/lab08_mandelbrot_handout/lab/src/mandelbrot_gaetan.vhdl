--=============================================================================
-- @file mandelbrot.vhdl
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
-- mandelbrot
--
-- @brief This file specifies a basic circuit for mandelbrot
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT
--=============================================================================
entity mandelbrot is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    WExSO   : out std_logic;
    XxDO    : out unsigned(COORD_BW - 1 downto 0);
    YxDO    : out unsigned(COORD_BW - 1 downto 0);
    ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
  );
end entity mandelbrot;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot is

  constant MULT_BW : integer := 2 * N_BITS;

  signal WExSN, WExSP : std_logic;

  signal XCountxDN, XCountxDP : unsigned(COORD_BW - 1 downto 0);
  signal YCountxDN, YCountxDP : unsigned(COORD_BW - 1 downto 0);

  -- Calculation
  signal XCountOffsetxDS, YCountOffsetxDS : signed(N_BITS - 1 downto 0);
  signal XxDN, XxDP : signed(N_BITS - 1 downto 0);
  signal YxDN, YxDP : signed(N_BITS - 1 downto 0);
  signal XSquaredxDS, YSquaredxDS : unsigned(MULT_BW - 1 downto 0);
  signal XYSquaredSumxDS : unsigned(MULT_BW - 1 downto 0);
  signal XTempxDS, YTempxDS : signed(MULT_BW - 1 downto 0);
  signal IterxDN, IterxDP : integer range 0 to MAX_ITER;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  process(CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then
      WExSP <= '0';

      XCountxDP <= (others => '0');
      YCountxDP <= (others => '0');

      IterxDP <= 0;

      XxDP <= (others => '0');
      YxDP <= (others => '0');

    elsif rising_edge(CLKxCI) then
      WExSP <= WExSN;

      XCountxDP <= XCountxDN;
      YCountxDP <= YCountxDN;

      IterxDP <= IterxDN;

      XxDP <= XxDN;
      YxDP <= YxDN;
    end if;
  end process;

  XCountOffsetxDS <= C_RE_0 + resize(shift_right(signed(shift_left(resize(XCountxDP, N_BITS), N_FRAC)) * C_RE_INC, N_FRAC), N_BITS);
  YCountOffsetxDS <= C_IM_0 + resize(shift_right(signed(shift_left(resize(YCountxDP, N_BITS), N_FRAC)) * C_IM_INC, N_FRAC), N_BITS);

  XSquaredxDS <= shift_right(unsigned(XxDP * XxDP), N_FRAC);
  YSquaredxDS <= shift_right(unsigned(YxDP * YxDP), N_FRAC);
  XYSquaredSumxDS <= XSquaredxDS + YSquaredxDS;

  XTempxDS <= signed(XSquaredxDS) - signed(YSquaredxDS);
  XxDN <= resize(XTempxDS + resize(XCountOffsetxDS, MULT_BW), N_BITS);
  YTempxDS <= shift_right(resize(shift_right(XxDP * YxDP, N_FRAC), N_BITS) * shift_left(to_signed(2, N_BITS), N_FRAC), N_FRAC);
  YxDN <= resize(YTempxDS + resize(signed(YCountOffsetxDS), MULT_BW), N_BITS);

  process(all)
  begin
    XCountxDN <= XCountxDP;
    YCountxDN <= YCountxDP;
    if WExSP = '1' then
      XCountxDN <= XCountxDP + 1;
      if XCountxDP = HS_DISPLAY - 1 then
        XCountxDN <= (others => '0');
        YCountxDN <= YCountxDP + 1;
        if YCountxDP = VS_DISPLAY - 1 then
          YCountxDN <= (others => '0');
        end if;
      end if;
    end if;
    
    WExSN <= '0';
    if XYSquaredSumxDS > unsigned((shift_left(to_unsigned(4, MULT_BW), N_FRAC))) or IterxDN = MAX_ITER then
      WExSN <= '1';
    end if;

    IterxDN <= IterxDP + 1;
    if WExSP = '1' then
      IterxDN <= 1;
    end if;

  end process;

  WExSO <= WExSP;

  XxDO <= XCountxDP;
  YxDO <= YCountxDP;

  ITERxDO <= to_unsigned(IterxDP, MEM_DATA_BW);

end architecture rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
