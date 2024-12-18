--=============================================================================
-- @file mandelbrot_top.vhdl
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
-- mandelbrot_top
--
-- @brief This file specifies the toplevel of the pong game with the Mandelbrot
-- to generate the background for lab 8, the final lab.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT_TOP
--=============================================================================
entity mandelbrot_top is
  port (
    CLK125xCI : in std_logic;
    RSTxRI    : in std_logic;

    -- Button inputs
    LeftxSI  : in std_logic;
    RightxSI : in std_logic;

    -- Timing outputs
    HSxSO : out std_logic;
    VSxSO : out std_logic;

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end mandelbrot_top;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot_top is

--=============================================================================
-- SIGNAL (COMBINATIONAL) DECLARATIONS
--=============================================================================;

  -- clk_wiz_0
  signal CLK75xC : std_logic;

  -- blk_mem_gen_0
  signal WrAddrAxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal RdAddrBxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal ENAxS     : std_logic;
  signal WEAxS     : std_logic_vector(0 downto 0);
  signal ENBxS     : std_logic;
  signal DINAxD    : std_logic_vector(MEM_DATA_BW - 1 downto 0);
  signal DOUTBxD   : std_logic_vector(MEM_DATA_BW - 1 downto 0);

  signal BGRedxS   : std_logic_vector(COLOR_BW - 1 downto 0); -- Background colors from the memory
  signal BGGreenxS : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BGBluexS  : std_logic_vector(COLOR_BW - 1 downto 0);

  -- vga_controller
  signal RedxS   : std_logic_vector(COLOR_BW - 1 downto 0); -- Color to VGA controller
  signal GreenxS : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BluexS  : std_logic_vector(COLOR_BW - 1 downto 0);

  signal XCoordxD : unsigned(COORD_BW - 1 downto 0); -- Coordinates from VGA controller
  signal YCoordxD : unsigned(COORD_BW - 1 downto 0);

  signal VSEdgexS : std_logic; -- If 1, row counter resets (new frame). HIGH for 1 CC, when vertical sync starts)

  -- pong_fsm
  signal BallXxD  : unsigned(COORD_BW - 1 downto 0); -- Coordinates of ball and plate
  signal BallYxD  : unsigned(COORD_BW - 1 downto 0);
  signal PlateXxD : unsigned(COORD_BW - 1 downto 0);
  signal SmileyXxD : unsigned(COORD_BW - 1 downto 0);
  signal SmileyYxD : unsigned(COORD_BW - 1 downto 0);
  signal Smiley2XxD : unsigned(COORD_BW - 1 downto 0);
  signal Smiley2YxD : unsigned(COORD_BW - 1 downto 0);

  signal DrawBallxS  : std_logic; -- If 1, draw the ball
  signal DrawPlatexS : std_logic; -- If 1, draw the plate
  signal DrawSmileyxS : std_logic; -- If 1, draw the smiley
  signal DrawSmiley2xS : std_logic; -- If 1, draw the smiley

  signal RunningStatexS : std_logic; -- If 1, running

  -- mandelbrot
  signal MandelbrotWExS   : std_logic; -- If 1, Mandelbrot writes
  signal MandelbrotXxD    : unsigned(COORD_BW - 1 downto 0);
  signal MandelbrotYxD    : unsigned(COORD_BW - 1 downto 0);
  signal MandelbrotITERxD : unsigned(MEM_DATA_BW - 1 downto 0);    -- Iteration number from Mandelbrot (chooses colour)

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component clk_wiz_0 is
    port (
      clk_out1 : out std_logic;
      reset    : in  std_logic;
      locked   : out std_logic;
      clk_in1  : in  std_logic
    );
  end component clk_wiz_0;

  component blk_mem_gen_0
    port (
      clka  : in std_logic;
      ena   : in std_logic;
      wea   : in std_logic_vector(0 downto 0);
      addra : in std_logic_vector(15 downto 0);
      dina  : in std_logic_vector(11 downto 0);

      clkb  : in std_logic;
      enb   : in std_logic;
      addrb : in std_logic_vector(15 downto 0);
      doutb : out std_logic_vector(11 downto 0)
    );
  end component;

  component vga_controller is
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

      VSEdgexSO : out std_logic;

      -- Data/color output
      RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
      GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
      BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
    );
  end component vga_controller;

  component pong_fsm is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      -- Controls from push buttons
      LeftxSI  : in std_logic;
      RightxSI : in std_logic;

      -- Coordinate from VGA
      VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
      VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

      -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
      VSEdgexSI : in std_logic;

      -- Ball and plate coordinates
      BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
      BallYxDO  : out unsigned(COORD_BW - 1 downto 0);
      PlateXxDO : out unsigned(COORD_BW - 1 downto 0);
      SmileyXxDO : out unsigned(COORD_BW - 1 downto 0);
      SmileyYxDO : out unsigned(COORD_BW - 1 downto 0);
      Smiley2XxDO : out unsigned(COORD_BW - 1 downto 0);
      Smiley2YxDO : out unsigned(COORD_BW - 1 downto 0);

      RunningStatexSO : out std_logic
    );
  end component pong_fsm;

  component mandelbrot is
    port (
      CLKxCI : in  std_logic;
      RSTxRI : in  std_logic;

      WExSO   : out std_logic;
      XxDO    : out unsigned(COORD_BW - 1 downto 0);
      YxDO    : out unsigned(COORD_BW - 1 downto 0);
      ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
    );
  end component mandelbrot;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
  i_clk_wiz_0 : clk_wiz_0
    port map (
      clk_out1 => CLK75xC,
      reset    => RSTxRI,
      locked   => open,
      clk_in1  => CLK125xCI
    );

  i_blk_mem_gen_0 : blk_mem_gen_0
    port map (
      clka  => CLK75xC,
      ena   => ENAxS,
      wea   => WEAxS,
      addra => WrAddrAxD,
      dina  => DINAxD,

      clkb  => CLK75xC,
      enb   => ENBxS,
      addrb => RdAddrBxD,
      doutb => DOUTBxD
    );

  i_vga_controller: vga_controller
    port map (
      CLKxCI => CLK75xC,
      RSTxRI => RSTxRI,

      RedxSI   => RedxS,
      GreenxSI => GreenxS,
      BluexSI  => BluexS,

      HSxSO => HSxSO,
      VSxSO => VSxSO,

      VSEdgexSO => VSEdgexS,

      XCoordxDO => XCoordxD,
      YCoordxDO => YCoordxD,

      RedxSO   => RedxSO,
      GreenxSO => GreenxSO,
      BluexSO  => BluexSO
    );

  i_pong_fsm : pong_fsm
    port map (
      CLKxCI => CLK75xC,
      RSTxRI => RSTxRI,

      RightxSI => RightxSI,
      LeftxSI  => LeftxSI,

      VgaXxDI => XCoordxD,
      VgaYxDI => YCoordxD,

      VSEdgexSI => VSEdgexS,

      BallXxDO  => BallXxD,
      BallYxDO  => BallYxD,
      PlateXxDO => PlateXxD,
      SmileyXxDO => SmileyXxD,
      SmileyYxDO => SmileyYxD,
      Smiley2XxDO => Smiley2XxD,
      Smiley2YxDO => Smiley2YxD,

      RunningStatexSO => RunningStatexS
    );

  i_mandelbrot : mandelbrot
    port map (
      CLKxCI  => CLK75xC,
      RSTxRI  => RSTxRI,

      WExSO   => MandelbrotWExS,
      XxDO    => MandelbrotXxD,
      YxDO    => MandelbrotYxD,
      ITERxDO => MandelbrotITERxD
    );

--=============================================================================
-- MEMORY SIGNAL MAPPING
--=============================================================================

  -- Port A
  ENAxS     <= MandelbrotWExS;
  WEAxS     <= (others => MandelbrotWExS);
  WrAddrAxD <= std_logic_vector(
    unsigned(
      shift_right(resize(MandelbrotXxD, MEM_ADDR_BW), 2)) 
    + unsigned(
      shift_left(shift_right(resize(MandelbrotYxD, MEM_ADDR_BW), 2), (10 - 2))));
  DINAxD    <= std_logic_vector(MandelbrotITERxD);
  -- -- Port A
  -- ENAxS     <= '0';
  -- WEAxS     <= "0";
  -- WrAddrAxD <= (others => '0');
  -- DINAxD    <= (others => '0');

  -- Port B
  ENBxS     <= '1';
  RdAddrBxD <= std_logic_vector(
    unsigned(
      shift_right(resize(XCoordxD, MEM_ADDR_BW), 2)) 
    + unsigned(
      shift_left(shift_right(resize(YCoordxD, MEM_ADDR_BW), 2), (10 - 2)))); -- Map the X and Y coordinates to the address of the memory

--=============================================================================
-- SPRITE SIGNAL MAPPING
--=============================================================================

  DrawBallxS <= '1' when BallXxD <= XCoordxD and BallXxD + (BALL_WIDTH - 1) >= XCoordxD and BallXxD <= HS_DISPLAY - BALL_WIDTH and BallYxD <= YCoordxD and BallYxD + (BALL_HEIGHT - 1) >= YCoordxD else '0';
  DrawPlatexS <= '1' when PlateXxD <= XCoordxD and PlateXxD + (PLATE_WIDTH - 1) >= XCoordxD and VS_DISPLAY - PLATE_HEIGHT <= YCoordxD else '0';
  DrawSmileyxS <= '1' when SmileyXxD <= XCoordxD and SmileyXxD + (SMILEY_WIDTH - 1) >= XCoordxD and  SmileyYxD <= YCoordxD and SmileyYxD + (SMILEY_HEIGHT - 1) >= YCoordxD else '0';
  DrawSmiley2xS <= '1' when Smiley2XxD <= XCoordxD and Smiley2XxD + (SMILEY_WIDTH - 1) >= XCoordxD and  Smiley2YxD <= YCoordxD and Smiley2YxD + (SMILEY_HEIGHT - 1) >= YCoordxD else '0';

  process(all)
  begin
    BGRedxS   <= DOUTBxD(3 * COLOR_BW - 1 downto 2 * COLOR_BW);
    BGGreenxS <= DOUTBxD(2 * COLOR_BW - 1 downto 1 * COLOR_BW);
    BGBluexS  <= DOUTBxD(1 * COLOR_BW - 1 downto 0 * COLOR_BW);

    RedxS   <= BGRedxS;
    GreenxS <= BGGreenxS;
    BluexS  <= BGBluexS;

    if DrawBallxS = '1' then
      if BALL_TILE(to_integer(YCoordxD - BallYxD), to_integer(XCoordxD - BallXxD)) = '1' then
        RedxS   <= (others => '1');
        GreenxS <= (others => '0');
        BluexS  <= (others => '0');
      end if;
    end if;
    
    if DrawPlatexS = '1' then
      RedxS   <= (others => '1');
      GreenxS <= (others => '1');
      BluexS  <= (others => '1');
    end if;

    if DrawSmileyxS = '1' then
      if RunningStatexS = '1' then
        if SMILEY_TILE(to_integer(shift_right(YCoordxD - SmileyYxD, 2)), to_integer(shift_right(XCoordxD - SmileyXxD, 2))) = '1' then
          RedxS   <= (others => '0');
          GreenxS <= (others => '1');
          BluexS  <= (others => '0');
        end if;
      else
        if SMILEY_TILE_LOOSER(to_integer(shift_right(YCoordxD - SmileyYxD, 2)), to_integer(shift_right(XCoordxD - SmileyXxD, 2))) = '1' then
          RedxS   <= (others => '1');
          GreenxS <= (others => '1');
          BluexS  <= (others => '0');
        end if;
      end if;
    end if;

    if DrawSmiley2xS = '1' then
      if RunningStatexS = '1' then
        if SMILEY_TILE(to_integer(shift_right(YCoordxD - Smiley2YxD, 2)), to_integer(shift_right(XCoordxD - Smiley2XxD, 2))) = '1' then
          RedxS   <= (others => '0');
          GreenxS <= (others => '1');
          BluexS  <= (others => '0');
        end if;
      else
        if SMILEY_TILE_LOOSER(to_integer(shift_right(YCoordxD - Smiley2YxD, 2)), to_integer(shift_right(XCoordxD - Smiley2XxD, 2))) = '1' then
          RedxS   <= (others => '1');
          GreenxS <= (others => '1');
          BluexS  <= (others => '0');
        end if;
      end if;
    end if;
  end process;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
