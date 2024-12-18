
--=============================================================================
-- @file dsd_prj_pkg.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
--
-- dsd_prj_pkg
--
-- @brief This file specifies the parameters used for the VGA controller, pong and mandelbrot circuits
--
-- The parameters are given here http://tinyvga.com/vga-timing/1024x768@70Hz
-- with a more elaborate explanation at https://projectf.io/posts/video-timings-vga-720p-1080p/
--
-- Briefly, the video timing for horizontal and vertical follows:
--    active pixels --> front porch --> sync --> back porch --> active pixels
-- During the sync period, we give a sync signal with the value of the polarity below.
--=============================================================================

package dsd_prj_pkg is

-------------------------------------------------------------------------------
-- Lab 5 parameters
-------------------------------------------------------------------------------

  -- Bitwidths for screen coordinate and colors
  constant COLOR_BW : natural := 4;  -- Each colour LED is 4 bits
  constant COORD_BW : natural := 12; -- 12 bits should accommodate any screen size we can consider

  constant BLACK_COLOR : std_logic_vector(COLOR_BW - 1 downto 0) := (others => '0');

  -- Horizontal timing parameters
  constant HS_DISPLAY     : natural   := 1024; -- Display width in pixels
  constant HS_FRONT_PORCH : natural   := 24;   -- Horizontal sync front porch length in number of pixels (clock-cycles)
  constant HS_PULSE       : natural   := 136;  -- Horizontal sync pulse length in number of pixels (clock-cycles)
  constant HS_BACK_PORCH  : natural   := 144;  -- Horizontal sync back porch length in number of pixels (clock-cycles)
  constant HS_POLARITY    : std_logic := '0';  -- Polarity indicates value of sync signal in sync period
                                                -- with negative polarity meaning active LOW.
  constant HS_TOTAL       : natural   := HS_DISPLAY + HS_FRONT_PORCH + HS_PULSE + HS_BACK_PORCH;

  -- Vertical timing parameters
  constant VS_DISPLAY     : natural   := 768; -- Display height in pixels
  constant VS_FRONT_PORCH : natural   := 3;   -- Vertical sync front porch length in number of horizontal lines
  constant VS_PULSE       : natural   := 6;   -- Vertical sync pulse length in number of horizontal lines
  constant VS_BACK_PORCH  : natural   := 29;  -- Vertical sync back porch length in number of horizontal lines
  constant VS_POLARITY    : std_logic := '0'; -- Vertical sync polarity
  constant VS_TOTAL       : natural   := VS_DISPLAY + VS_FRONT_PORCH + VS_PULSE + VS_BACK_PORCH;

-------------------------------------------------------------------------------
-- Lab 6 parameters
-------------------------------------------------------------------------------

  -- Memory parameters
  constant MEM_ADDR_BW : natural := 16;
  constant MEM_DATA_BW : natural := 12;

-------------------------------------------------------------------------------
-- Lab 7 parameters
-------------------------------------------------------------------------------

  -- Pong parameters (in pixels)
  constant BALL_WIDTH   : natural := 10;
  constant BALL_HEIGHT  : natural := 10;
  constant BALL_STEP_X  : natural := 2;
  constant BALL_STEP_Y  : natural := 2;
  constant PLATE_WIDTH  : natural := 120;
  constant PLATE_HEIGHT : natural := 10;
  constant PLATE_STEP_X : natural := 80;
  constant SMILEY_WIDTH : natural := 80;
  constant SMILEY_HEIGHT : natural := 80;
  constant SMILEY_STEP_X : natural := 5;
  constant SMILEY_STEP_Y : natural := 5;
  constant SMILEY_FACTOR : natural := 4;

  constant SPEED : natural := 4;
  constant STEP_X : natural := SPEED * BALL_STEP_X;
  constant STEP_Y : natural := SPEED * BALL_STEP_Y;

  type array_ball_t is array (0 to BALL_WIDTH - 1, 0 to BALL_HEIGHT - 1) of std_logic;
  constant BALL_TILE : array_ball_t := (
    0 => ('0', '0', '0', '1', '1', '1', '1', '0', '0', '0'),
    1 => ('0', '0', '1', '1', '1', '1', '1', '1', '0', '0'),
    2 => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    3 => ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
    4 => ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
    5 => ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
    6 => ('1', '1', '1', '1', '1', '1', '1', '1', '1', '1'),
    7 => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    8 => ('0', '0', '1', '1', '1', '1', '1', '1', '0', '0'),
    9 => ('0', '0', '0', '1', '1', '1', '1', '0', '0', '0')
  );
  -- Coordonates of the ball : BALL_TILE(0, 0)

  type smiley_t is array (0 to SMILEY_WIDTH/SMILEY_FACTOR - 1, 0 to SMILEY_HEIGHT/SMILEY_FACTOR - 1) of std_logic;
  constant SMILEY_TILE : smiley_t := (
    0  => ('0', '0', '0', '0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0', '0', '0', '0'),
    1  => ('0', '0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0', '0'),
    2  => ('0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0'),
    3  => ('0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0'),
    4  => ('0', '0', '1', '1', '1', '1', '0', '0', '1', '1', '1', '1', '0', '0', '1', '1', '1', '1', '0', '0'),
    5  => ('0', '0', '1', '1', '1', '0', '0', '0', '0', '1', '1', '0', '0', '0', '0', '1', '1', '1', '0', '0'),
    6  => ('0', '1', '1', '1', '1', '0', '0', '0', '0', '1', '1', '0', '0', '0', '0', '1', '1', '1', '1', '0'),
    7  => ('0', '1', '1', '1', '1', '1', '0', '0', '1', '1', '1', '1', '0', '0', '1', '1', '1', '1', '1', '0'),
    8  => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    9  => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    10 => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    11 => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    12 => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    13 => ('0', '1', '1', '1', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '1', '1', '1', '0'),
    14 => ('0', '0', '1', '1', '1', '0', '0', '1', '1', '1', '1', '1', '1', '0', '0', '1', '1', '1', '0', '0'),
    15 => ('0', '0', '1', '1', '1', '1', '0', '0', '0', '0', '0', '0', '0', '0', '1', '1', '1', '1', '0', '0'),
    16 => ('0', '0', '0', '1', '1', '1', '1', '0', '0', '0', '0', '0', '0', '1', '1', '1', '1', '0', '0', '0'),
    17 => ('0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0'),
    18 => ('0', '0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0', '0', '0'),
    19 => ('0', '0', '0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0', '0', '0', '0')
  );

  constant SMILEY_TILE_LOOSER : smiley_t := (
    0  => ('0', '0', '0', '0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0', '0', '0', '0'),
    1  => ('0', '0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0', '0'),
    2  => ('0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0'),
    3  => ('0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0'),
    4  => ('0', '0', '1', '1', '1', '1', '1', '0', '1', '1', '1', '1', '0', '1', '1', '1', '1', '1', '0', '0'),
    5  => ('0', '0', '1', '1', '1', '1', '0', '0', '0', '1', '1', '0', '0', '0', '1', '1', '1', '1', '0', '0'),
    6  => ('0', '1', '1', '1', '1', '0', '0', '0', '0', '1', '1', '0', '0', '0', '0', '1', '1', '1', '1', '0'),
    7  => ('0', '1', '1', '1', '1', '0', '0', '0', '0', '1', '1', '0', '0', '0', '0', '1', '1', '1', '1', '0'),
    8  => ('0', '1', '1', '1', '1', '1', '0', '0', '1', '1', '1', '1', '1', '0', '0', '1', '1', '1', '1', '0'),
    9  => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    10 => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    11 => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    12 => ('0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0'),
    13 => ('0', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '0'),
    14 => ('0', '0', '1', '1', '1', '1', '0', '0', '0', '0', '0', '0', '0', '0', '1', '1', '1', '1', '0', '0'),
    15 => ('0', '0', '1', '1', '1', '0', '0', '1', '1', '1', '1', '1', '1', '0', '0', '1', '1', '1', '0', '0'),
    16 => ('0', '0', '0', '1', '1', '0', '1', '1', '1', '1', '1', '1', '1', '1', '0', '1', '1', '0', '0', '0'),
    17 => ('0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0'),
    18 => ('0', '0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0', '0', '0'),
    19 => ('0', '0', '0', '0', '0', '0', '1', '1', '1', '1', '1', '1', '1', '0', '0', '0', '0', '0', '0', '0')
  );


-------------------------------------------------------------------------------
-- Lab 8 parameters
-------------------------------------------------------------------------------

  -- Mandelbrot parameters
  -- Use QNi.Nf notation, with Ni being number of integer bits WITH sign and Nf number of fractional bits
  -- Use UQNi.Nf notation for unsigned, with Ni being just the number of integer bits WITHOUT sign
  constant N_INT  : natural := 3;   -- # Integer bits (plus sign-bit)
  constant N_FRAC : natural := 20;  -- # Fractional bits
  constant N_BITS : natural := N_INT + N_FRAC;

  constant ITER_LIM : natural := 2**(2 + N_FRAC); -- Represents 2^2 in UQ3.15 (100.000000000000000)
  constant MAX_ITER : natural := 100;             -- Maximum iteration bumber before stopping

  -- Start at (-2, -1) = (0b110, 0b111) on the complex plane. As the Mandelbrot fractal is symmetric
  -- along the real axis, this can be used to draw the Mandelbrot fractal similar to starting at (-2, 1).
  -- The benefit of starting at (-2, -1) is that we only have to ADD the increments to C_RE_0 and C_IM_0
  -- instead of having to subtract the increment C_IM_INC from C_IM_0 to go down the imaginary axis
  constant C_RE_0 : signed(N_BITS - 1 downto 0) := to_signed(-2 * (2**N_FRAC), N_BITS); -- Q3.15
  constant C_IM_0 : signed(N_BITS - 1 downto 0) := to_signed(-1 * (2**N_FRAC), N_BITS); -- Q3.15

  -- Increment by 3*2^(-10) and 5*2^(-11) for real and imaginary, respectively.
  -- For real (X), starting at -2 with 1024 = 2^10 pixels, we end at -2 + 2^10 * 3 * 2^(-10) = -2 + 3 = 1
  -- For imaginary (Y), starting at -1 with 768 pixels, we end at -1 + 768*5*2^(-11) = 0.875
  constant C_RE_INC : signed(N_BITS - 1 downto 0) := to_signed(3 * 2**(-10 + N_FRAC), N_BITS); -- Q3.15
  constant C_IM_INC : signed(N_BITS - 1 downto 0) := to_signed(5 * 2**(-11 + N_FRAC), N_BITS); -- Q3.15

end package dsd_prj_pkg;
