--=============================================================================
-- @file pong_fsm.vhdl
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
-- pong_fsm
--
-- @brief This file specifies a basic circuit for the pong game. Note that coordinates are counted
-- from the upper left corner of the screen.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR PONG_FSM
--=============================================================================
entity pong_fsm is
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
    SmileyYxDO : out unsigned(COORD_BW - 1 downto 0)
  );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is

  type FSM_t is
  (
    IDLE,
    CALCULATION,
    WAITING
  );

  type Direction_t is
  (
    XY,
    nXY,
    nXnY,
    XnY
  );

  type SmileyDirection_t is
  (
    X,
    Y,
    nX,
    nY
  );

  signal StatexDN, StatexDP : FSM_t := IDLE;
  signal BallXxDN, BallXxDP, BallYxDN, BallYxDP : unsigned(COORD_BW - 1 downto 0) := (others => '0');
  signal SmileyXxDN, SmileyXxDP, SmileyYxDN, SmileyYxDP : unsigned(COORD_BW - 1 downto 0) := (others => '0');
  signal PlateXxDN, PlateXxDP : unsigned(COORD_BW - 1 downto 0) := (others => '0');
  signal LeftxSP, RightxSP : std_logic;
  signal VSEdgexSP: std_logic;
  signal DirectionxDN, DirectionxDP : Direction_t := XY;
  signal SmileyDirectionxDN, SmileyDirectionxDP : SmileyDirection_t := X;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  process(all)
  begin
    StatexDN <= StatexDP;

    DirectionxDN <= DirectionxDP;
    SmileyDirectionxDN <= SmileyDirectionxDP;

    BallXxDN <= BallXxDP;
    BallYxDN <= BallYxDP;

    PlateXxDN <= PlateXxDP;

    SmileyXxDN <= SmileyXxDP;
    SmileyYxDN <= SmileyYxDP;

    if LeftxSP = '0' and LeftxSI = '1' then
      if PlateXxDP >= PLATE_STEP_X then
        PlateXxDN <= PlateXxDP - PLATE_STEP_X;
      end if;
    end if;

    if RightxSP = '0' and RightxSI = '1' then
      if PlateXxDP <= (HS_DISPLAY - PLATE_STEP_X - PLATE_WIDTH) then
        PlateXxDN <= PlateXxDP + PLATE_STEP_X;
      end if;
    end if;

    case StatexDP is
      when IDLE =>
        BallXxDN <= to_unsigned(((HS_DISPLAY - BALL_WIDTH) / 2 - 1), COORD_BW);
        BallYxDN <= to_unsigned(((VS_DISPLAY - BALL_HEIGHT) / 2 - 1), COORD_BW);

        PlateXxDN <= to_unsigned(((HS_DISPLAY - PLATE_WIDTH) / 2 - 1), COORD_BW);

        SmileyXxDN <= to_unsigned(((HS_DISPLAY - SMILEY_WIDTH) / 4 - 1), COORD_BW);
        SmileyYxDN <= to_unsigned(((HS_DISPLAY - SMILEY_HEIGHT) / 4 - 1), COORD_BW);

        DirectionxDN <= XnY;

        if LeftxSP = '1' and RightxSP = '1' then
          StatexDN <= WAITING;
        end if;

      when WAITING =>
        if VSEdgexSP = '0' and VSEdgexSI = '1' then
          StatexDN <= CALCULATION;
        end if;

      when CALCULATION =>
        StatexDN <= WAITING;

        case SmileyDirectionxDP is
          when X =>
            if SmileyYxDP + SMILEY_STEP_X + SMILEY_WIDTH < to_unsigned(HS_DISPLAY - (HS_DISPLAY - SMILEY_WIDTH) / 4, COORD_BW) then
              SmileyXxDN <= SmileyXxDP + SMILEY_STEP_X;
            else
              SmileyDirectionxDN <= Y;
            end if;
          when Y =>
            if SmileyYxDP + SMILEY_STEP_Y + SMILEY_HEIGHT < to_unsigned(VS_DISPLAY - (VS_DISPLAY - SMILEY_HEIGHT) / 4, COORD_BW) then
              SmileyYxDN <= SmileyYxDP + SMILEY_STEP_Y;
            else
              SmileyDirectionxDN <= nX;
            end if;
          when nX =>
            if SmileyXxDP - SMILEY_STEP_X > to_unsigned(((HS_DISPLAY - SMILEY_WIDTH) / 4 - 1), COORD_BW) then
              SmileyXxDN <= SmileyXxDP - SMILEY_STEP_X;
            else
              SmileyDirectionxDN <= nY;
            end if;
          when nY =>
            if SmileyYxDP - SMILEY_STEP_Y > to_unsigned(((VS_DISPLAY - SMILEY_HEIGHT) / 4 - 1), COORD_BW) then
              SmileyYxDN <= SmileyYxDP - SMILEY_STEP_Y;
            else
              SmileyDirectionxDN <= X;
            end if;
        end case;
        
        if DirectionxDP = XY or DirectionxDP = XnY then
          if (BallXxDP + STEP_X + BALL_WIDTH > SmileyXxDN and BallXxDP + STEP_X < SmileyXxDN + SMILEY_WIDTH) 
              or (BallXxDP + STEP_X > HS_DISPLAY - BALL_WIDTH) then
            if DirectionxDP = XY then
              DirectionxDN <= nXY;
            else
              DirectionxDN <= nXnY;
            end if;
          else
            BallXxDN <= BallXxDP + STEP_X;
          end if;

          -- if BallXxDP <= (HS_DISPLAY - BALL_WIDTH - STEP_X) then
          --   BallXxDN <= BallXxDP + STEP_X;
          -- else
          --   if DirectionxDP = XY then
          --     DirectionxDN <= nXY;
          --   else
          --     DirectionxDN <= nXnY;
          --   end if;
          --   if BallXxDP >= (HS_DISPLAY - BALL_WIDTH - STEP_X/2) then
          --     BallXxDN <= (HS_DISPLAY - BALL_WIDTH - STEP_X/2) - (BallXxDP - (HS_DISPLAY - BALL_WIDTH - STEP_X/2));
          --   else
          --     BallXxDN <= (HS_DISPLAY - BALL_WIDTH - STEP_X/2) + ((HS_DISPLAY - BALL_WIDTH - STEP_X/2) - BallXxDP);
          --   end if;
          -- end if;
        else
          if (BallXxDP + STEP_X + BALL_WIDTH > SmileyXxDN and BallXxDP + STEP_X < SmileyXxDN + SMILEY_WIDTH)
              or (BallXxDP < STEP_X) then
            if DirectionxDP = nXY then
              DirectionxDN <= XY;
            else
              DirectionxDN <= XnY;
            end if;
          else
            BallXxDN <= BallXxDP - STEP_X;
          end if;

          -- if BallXxDP >= BALL_WIDTH + STEP_X then
          --   BallXxDN <= BallXxDP - STEP_X;
          -- else
          --   if DirectionxDP = nXY then
          --     DirectionxDN <= XY;
          --   else
          --     DirectionxDN <= XnY;
          --   end if;
          --   if BallXxDP <= (BALL_WIDTH + STEP_X/2) then
          --     BallXxDN <= (BALL_WIDTH + STEP_X/2) + ((BALL_WIDTH + STEP_X/2) - BallXxDP);
          --   else
          --     BallXxDN <= (BALL_WIDTH + STEP_X/2) + (BallXxDP - (BALL_WIDTH + STEP_X/2));
          --   end if;
          -- end if;
        end if;

        if DirectionxDP = XY or DirectionxDP = nXY then
          if (BallXxDP + BALL_WIDTH - 1) >= PlateXxDP and BallXxDP <= (PlateXxDP + PLATE_WIDTH - 1) then
            if BallYxDP <= (VS_DISPLAY - BALL_HEIGHT - PLATE_HEIGHT - STEP_Y) then
              BallYxDN <= BallYxDP + STEP_Y;
            else
              if DirectionxDP = XY then
                DirectionxDN <= XnY;
              else
                DirectionxDN <= nXnY;
              end if;
              if BallYxDP >= (VS_DISPLAY - BALL_HEIGHT - PLATE_HEIGHT - STEP_Y/2) then
               BallYxDN <= (VS_DISPLAY - BALL_HEIGHT - PLATE_HEIGHT - STEP_Y/2) - (BallYxDP - (VS_DISPLAY - BALL_HEIGHT - PLATE_HEIGHT - STEP_Y/2));
              else
               BallYxDN <= (VS_DISPLAY - BALL_HEIGHT - PLATE_HEIGHT - STEP_Y/2) + ((VS_DISPLAY - BALL_HEIGHT - PLATE_HEIGHT - STEP_Y/2) - BallYxDP);
              end if;
            end if;
          else
            if BallYxDP <= (VS_DISPLAY - BALL_HEIGHT - STEP_Y) then
              BallYxDN <= BallYxDP + STEP_Y;
            else
              StatexDN <= IDLE;
            end if;
          end if;
        else
          if BallYxDP >= BALL_HEIGHT + STEP_Y then
            BallYxDN <= BallYxDP - STEP_Y;
          else
            if DirectionxDP = XnY then
              DirectionxDN <= XY;
            else
              DirectionxDN <= nXY;
            end if;
            if BallYxDP <= (BALL_HEIGHT + STEP_Y/2) then
             BallYxDN <= (BALL_HEIGHT + STEP_Y/2) + ((BALL_HEIGHT + STEP_Y/2) - BallYxDP);
            else
             BallYxDN <= (BALL_HEIGHT + STEP_Y/2) + (BallYxDP - (BALL_HEIGHT + STEP_Y/2));
            end if;
          end if;
        end if;
      when others => null;
    end case;
  end process;

  process(CLKxCI, RSTxRI)
  begin
    if RSTxRI = '1' then
      StatexDP <= IDLE;

      BallXxDP <= to_unsigned((HS_DISPLAY / 2 - 1), COORD_BW);
      BallYxDP <= to_unsigned((VS_DISPLAY / 2 - 1), COORD_BW);

      PlateXxDP <= to_unsigned(((HS_DISPLAY - PLATE_WIDTH) / 2 - 1), COORD_BW);

      SmileyXxDP <= to_unsigned(((HS_DISPLAY - SMILEY_WIDTH) / 2 - 1), COORD_BW);
      SmileyYxDP <= to_unsigned(((VS_DISPLAY - SMILEY_HEIGHT) / 2 - 1), COORD_BW);

      LeftxSP <= LeftxSI;
      RightxSP <= RightxSI;

      VSEdgexSP <= '0';

      DirectionxDP <= XnY;

      SmileyDirectionxDP <= X;

    elsif rising_edge(CLKxCI) then
      StatexDP <= StatexDN;

      BallXxDP <= BallXxDN;
      BallYxDP <= BallYxDN;

      PlateXxDP <= PlateXxDN;

      SmileyXxDP <= SmileyXxDN;
      SmileyYxDP <= SmileyYxDN;

      LeftxSP <= LeftxSI;
      RightxSP <= RightxSI;

      VSEdgexSP <= VSEdgexSI;

      DirectionxDP <= DirectionxDN;

      SmileyDirectionxDP <= SmileyDirectionxDN;

    end if;
  end process;

  BallXxDO <= BallXxDP;
  BallYxDO <= BallYxDP;

  PlateXxDO <= PlateXxDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
