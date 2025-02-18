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
    SmileyYxDO : out unsigned(COORD_BW - 1 downto 0);
    Smiley2XxDO : out unsigned(COORD_BW - 1 downto 0);
    Smiley2YxDO : out unsigned(COORD_BW - 1 downto 0);

    RunningStatexSO : out std_logic
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
  signal BallXxDS, BallYxDS : unsigned(COORD_BW - 1 downto 0) := (others => '0');
  signal SmileyXxDN, SmileyXxDP, SmileyYxDN, SmileyYxDP : unsigned(COORD_BW - 1 downto 0) := (others => '0');
  signal Smiley2XxDN, Smiley2XxDP, Smiley2YxDN, Smiley2YxDP : unsigned(COORD_BW - 1 downto 0) := (others => '0');
  signal PlateXxDN, PlateXxDP : unsigned(COORD_BW - 1 downto 0) := (others => '0');
  signal LeftxSP, RightxSP : std_logic;
  signal VSEdgexSP: std_logic;
  signal DirectionxDN, DirectionxDP : Direction_t := XY;
  signal SmileyDirectionxDN, SmileyDirectionxDP : SmileyDirection_t := X;
  signal CollisionSmileyxS : std_logic;
  signal CollisionSmileyYxS : std_logic;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  CollisionSmileyxS <= '1' when ((BallXxDS + BALL_WIDTH > SmileyXxDN and BallXxDS < SmileyXxDN + SMILEY_WIDTH) and (BallYxDS + BALL_HEIGHT > SmileyYxDN and BallYxDS < SmileyYxDN + SMILEY_HEIGHT)) 
    or ((BallXxDS + BALL_WIDTH > Smiley2XxDN and BallXxDS < Smiley2XxDN + SMILEY_WIDTH) and (BallYxDS + BALL_HEIGHT > Smiley2YxDN and BallYxDS < Smiley2YxDN + SMILEY_HEIGHT))
    else '0';
  CollisionSmileyYxS <= '1' when ((BallXxDS > SmileyXxDN and BallXxDS + BALL_WIDTH < SmileyXxDN + SMILEY_WIDTH) or (BallXxDS > Smiley2XxDN and BallXxDS + BALL_WIDTH < Smiley2XxDN + SMILEY_WIDTH)) else '0';

  process(all)
  begin
    StatexDN <= StatexDP;

    DirectionxDN <= DirectionxDP;
    SmileyDirectionxDN <= SmileyDirectionxDP;

    BallXxDN <= BallXxDP;
    BallYxDN <= BallYxDP;

    BallXxDS <= BallXxDP;
    BallYxDS <= BallYxDP;

    PlateXxDN <= PlateXxDP;

    SmileyXxDN <= SmileyXxDP;
    Smiley2XxDN <= Smiley2XxDP;
    SmileyYxDN <= SmileyYxDP;
    Smiley2YxDN <= Smiley2YxDP;

    RunningStatexSO <= '1';

    if LeftxSP = '0' and LeftxSI = '1' then
      if PlateXxDP >= PLATE_STEP_X then
        PlateXxDN <= PlateXxDP - PLATE_STEP_X;
      else
        PlateXxDN <= to_unsigned(0, COORD_BW);
      end if;
    end if;

    if RightxSP = '0' and RightxSI = '1' then
      if PlateXxDP <= (HS_DISPLAY - PLATE_STEP_X - PLATE_WIDTH) then
        PlateXxDN <= PlateXxDP + PLATE_STEP_X;
      else
        PlateXxDN <= to_unsigned((HS_DISPLAY - PLATE_WIDTH - 1), COORD_BW);
      end if;
    end if;

    case StatexDP is
      when IDLE =>
        BallXxDN <= VgaXxDI;
        BallYxDN <= VgaYxDI;

        PlateXxDN <= to_unsigned(((HS_DISPLAY - PLATE_WIDTH) / 2 - 1), COORD_BW);

        SmileyXxDN <= to_unsigned((HS_DISPLAY / 4 - SMILEY_WIDTH / 2 - 1), COORD_BW);
        Smiley2XxDN <= to_unsigned(HS_DISPLAY - HS_DISPLAY / 4 - SMILEY_WIDTH / 2 - 1, COORD_BW);
        SmileyYxDN <= to_unsigned((VS_DISPLAY / 4 - SMILEY_HEIGHT / 2 - 1), COORD_BW);
        Smiley2YxDN <= to_unsigned(VS_DISPLAY - VS_DISPLAY / 4 - SMILEY_HEIGHT / 2 - 1, COORD_BW);

        DirectionxDN <= XnY;

        if LeftxSP = '1' and RightxSP = '1' then
          StatexDN <= WAITING;
        end if;

        RunningStatexSO <= '0';

      when WAITING =>
        if VSEdgexSP = '0' and VSEdgexSI = '1' then
          StatexDN <= CALCULATION;
        end if;

      when CALCULATION =>
        StatexDN <= WAITING;

        case DirectionxDP is
          when XY =>
            BallXxDS <= BallXxDP + STEP_X;
            BallYxDS <= BallYxDP + STEP_Y;
          when nXY =>
            BallXxDS <= BallXxDP - STEP_X;
            BallYxDS <= BallYxDP + STEP_Y;
          when nXnY =>
            BallXxDS <= BallXxDP - STEP_X;
            BallYxDS <= BallYxDP - STEP_Y;
          when XnY =>
            BallXxDS <= BallXxDP + STEP_X;
            BallYxDS <= BallYxDP - STEP_Y;
        end case;
        
        case SmileyDirectionxDP is
          when X =>
            if SmileyXxDP + SMILEY_STEP_X < to_unsigned((HS_DISPLAY - HS_DISPLAY / 4 - SMILEY_WIDTH / 2 - 1), COORD_BW) then
              SmileyXxDN <= SmileyXxDP + SMILEY_STEP_X;
              Smiley2XxDN <= Smiley2XxDP - SMILEY_STEP_X;
            else
              SmileyDirectionxDN <= Y;
            end if;
          when Y =>
            if SmileyYxDP + SMILEY_STEP_Y < to_unsigned(VS_DISPLAY - VS_DISPLAY / 4 - SMILEY_HEIGHT / 2, COORD_BW) then
              SmileyYxDN <= SmileyYxDP + SMILEY_STEP_Y;
              Smiley2YxDN <= Smiley2YxDP - SMILEY_STEP_Y;
            else
              SmileyDirectionxDN <= nX;
            end if;
          when nX =>
            if SmileyXxDP - SMILEY_STEP_X > to_unsigned((HS_DISPLAY / 4 - SMILEY_WIDTH / 2 - 1), COORD_BW) then
              SmileyXxDN <= SmileyXxDP - SMILEY_STEP_X;
              Smiley2XxDN <= Smiley2XxDP + SMILEY_STEP_X;
            else
              SmileyDirectionxDN <= nY;
            end if;
          when nY =>
            if SmileyYxDP - SMILEY_STEP_Y > to_unsigned((VS_DISPLAY / 4 - SMILEY_HEIGHT / 2 - 1), COORD_BW) then
              SmileyYxDN <= SmileyYxDP - SMILEY_STEP_Y;
              Smiley2YxDN <= Smiley2YxDP + SMILEY_STEP_Y;
            else
              SmileyDirectionxDN <= X;
            end if;
        end case;
        
        if DirectionxDP = XY or DirectionxDP = XnY then
          if (CollisionSmileyxS = '1' and CollisionSmileyYxS = '0')
              or (BallXxDP + STEP_X > HS_DISPLAY - BALL_WIDTH) then
            if DirectionxDP = XY then
              DirectionxDN <= nXY;
            else
              DirectionxDN <= nXnY;
            end if;
            BallXxDN <= BallXxDP - STEP_X;
          else
            BallXxDN <= BallXxDP + STEP_X;
          end if;
        else
          if (CollisionSmileyxS = '1' and CollisionSmileyYxS = '0')
              or (BallXxDP < STEP_X) then
            if DirectionxDP = nXY then
              DirectionxDN <= XY;
            else
              DirectionxDN <= XnY;
            end if;
            BallXxDN <= BallXxDP + STEP_X;
          else
            BallXxDN <= BallXxDP - STEP_X;
          end if;
        end if;

        if DirectionxDP = XY or DirectionxDP = nXY then
          if (CollisionSmileyxS = '1' and CollisionSmileyYxS = '1') 
              or ((BallXxDP + BALL_WIDTH - 1) >= PlateXxDP and BallXxDP <= (PlateXxDP + PLATE_WIDTH - 1)
              and BallYxDP + STEP_Y > (VS_DISPLAY - BALL_HEIGHT - PLATE_HEIGHT)) then
            if DirectionxDP = XY then
              DirectionxDN <= XnY;
            else
              DirectionxDN <= nXnY;
            end if;
            BallYxDN <= BallYxDP - STEP_Y;
          elsif BallYxDP + STEP_Y > (VS_DISPLAY - BALL_HEIGHT) then
            StatexDN <= IDLE;
          else
            BallYxDN <= BallYxDP + STEP_Y;
          end if;
        else
          if (CollisionSmileyxS = '1' and CollisionSmileyYxS = '1') or BallYxDP < STEP_Y then
            if DirectionxDP = XnY then
              DirectionxDN <= XY;
            else
              DirectionxDN <= nXY;
            end if;
            BallYxDN <= BallYxDP + STEP_Y;
          else
            BallYxDN <= BallYxDP - STEP_Y;
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
      Smiley2XxDP <= to_unsigned(HS_DISPLAY - (HS_DISPLAY - SMILEY_WIDTH) / 2, COORD_BW);
      Smiley2YxDP <= to_unsigned(VS_DISPLAY - (VS_DISPLAY - SMILEY_HEIGHT) / 2, COORD_BW);

      LeftxSP <= '0';
      RightxSP <= '0';

      VSEdgexSP <= '0';

      DirectionxDP <= XnY;

      SmileyDirectionxDP <= X;

    elsif rising_edge(CLKxCI) then
      StatexDP <= StatexDN;

      BallXxDP <= BallXxDN;
      BallYxDP <= BallYxDN;

      PlateXxDP <= PlateXxDN;

      SmileyXxDP <= SmileyXxDN;
      Smiley2XxDP <= Smiley2XxDN;
      SmileyYxDP <= SmileyYxDN;
      Smiley2YxDP <= Smiley2YxDN;

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

  SmileyXxDO <= SmileyXxDP;
  SmileyYxDO <= SmileyYxDP;
  Smiley2XxDO <= Smiley2XxDP;
  Smiley2YxDO <= Smiley2YxDP;

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
