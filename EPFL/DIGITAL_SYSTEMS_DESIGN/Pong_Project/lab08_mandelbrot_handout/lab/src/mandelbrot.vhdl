--=============================================================================
-- @file mandelbrot.vhdl
--=============================================================================
-- Standard library
LIBRARY ieee;
-- Standard packages
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
-- Packages
LIBRARY work;
USE work.dsd_prj_pkg.ALL;

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
ENTITY mandelbrot IS
  PORT (
    CLKxCI : IN STD_LOGIC;
    RSTxRI : IN STD_LOGIC;

    WExSO : OUT STD_LOGIC;
    XxDO : OUT unsigned(COORD_BW - 1 DOWNTO 0);
    YxDO : OUT unsigned(COORD_BW - 1 DOWNTO 0);
    ITERxDO : OUT unsigned(MEM_DATA_BW - 1 DOWNTO 0)
  );
END ENTITY mandelbrot;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
ARCHITECTURE rtl OF mandelbrot IS

  SIGNAL counterXxDN, counterXxDP, counterYxDN, counterYxDP : unsigned(COORD_BW - 1 DOWNTO 0);
  SIGNAL C_RExDN, C_RExDP, C_IMxDN, C_IMxDP, Z_RExDN, Z_RExDP, Z_IMxDN, Z_IMxDP : signed(N_BITS - 1 DOWNTO 0);
  SIGNAL iterationsxDN, iterationsxDP : unsigned (MEM_DATA_BW - 1 DOWNTO 0);
  SIGNAL magnitudeSquaredxDS : signed(2 * N_BITS - 1 DOWNTO 0);
  SIGNAL keepIteratingxS : STD_LOGIC;
  --=============================================================================
  -- ARCHITECTURE BEGIN
  --=============================================================================
BEGIN

  -- Register
  PROCESS (CLKxCI, RSTxRI)
  BEGIN
    IF (RSTxRI = '1') THEN -- Reset
      counterXxDP <= (OTHERS => '0');
      counterYxDP <= (OTHERS => '0');
      C_RExDP <= C_RE_0;
      C_IMxDP <= C_IM_0;
      Z_RExDP <= C_RE_0;
      Z_IMxDP <= C_IM_0;
      iterationsxDP <= (OTHERS => '0');
    ELSIF (CLKxCI'event AND CLKxCI = '1') THEN -- To the next state
      counterXxDP <= counterXxDN;
      counterYxDP <= counterYxDN;
      C_RExDP <= C_RExDN;
      C_IMxDP <= C_IMxDN;
      Z_RExDP <= Z_RExDN;
      Z_IMxDP <= Z_IMxDN;
      iterationsxDP <= iterationsxDN;
    END IF;
  END PROCESS;

  -- Combinational logics

  PROCESS (ALL)
  BEGIN
  -- Default values
    WExSO <= '0';
    XxDO <= counterXxDP;
    YxDO <= counterYxDP;
    ITERxDO <= iterationsxDP;
    counterXxDN <= counterXxDP;
    counterYxDN <= counterYxDP;
    C_RExDN <= C_RExDP;
    C_IMxDN <= C_IMxDP;
    Z_RExDN <= Z_RExDP;
    Z_IMxDN <= Z_IMxDP;

  -- Mandelbrot algorithm

    magnitudeSquaredxDS <= resize(shift_right((Z_RExDP * Z_RExDP), N_FRAC) + shift_right((Z_IMxDP * Z_IMxDP), N_FRAC), 2 * N_BITS);
    keepIteratingxS <= '1' WHEN (iterationsxDP < MAX_ITER AND magnitudeSquaredxDS < ITER_LIM) ELSE
      '0';

    IF (keepIteratingxS = '1') THEN 
      Z_RExDN <= resize(shift_right((Z_RExDP * Z_RExDP), N_FRAC) - shift_right((Z_IMxDP * Z_IMxDP), N_FRAC), N_BITS) + C_RExDP;
      Z_IMxDN <= resize(shift_right((2 * Z_RExDP * Z_IMxDP), N_FRAC), N_BITS) + C_IMxDP;
      iterationsxDN <= iterationsxDP + 1;
    ELSE
      WExSO <= '1';
      iterationsxDN <= (OTHERS => '0');
      IF (counterXxDP < HS_DISPLAY - 1) THEN -- Increment pixel
        counterXxDN <= counterXxDP + 1;
        C_RExDN <= C_RExDP + C_RE_INC;
        Z_RExDN <= C_RExDP + C_RE_INC;
        Z_IMxDN <= C_IMxDP;
      ELSE
        counterXxDN <= (OTHERS => '0');
        C_RExDN <= C_RE_0;
        Z_RExDN <= C_RE_0;
        IF (counterYxDP = VS_DISPLAY - 1) THEN
          counterYxDN <= (OTHERS => '0');
          C_IMxDN <= C_IM_0;
          Z_IMxDN <= C_IM_0;
        ELSE
          counterYxDN <= counterYxDP + 1;
          C_IMxDN <= C_IMxDP + C_IM_INC;
          Z_IMxDN <= C_IMxDP + C_IM_INC;
        END IF;
      END IF;
    END IF;
  END PROCESS;

END ARCHITECTURE rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================