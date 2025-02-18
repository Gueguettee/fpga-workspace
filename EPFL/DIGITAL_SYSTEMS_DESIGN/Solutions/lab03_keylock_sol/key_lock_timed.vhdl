--=============================================================================
-- @file key_lock_timed.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--=============================================================================
--
-- key_lock_timed
--
-- @brief This file specifies the FSM for lab3
--
--=============================================================================

entity key_lock_timed is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    KeyValidxSI : in std_logic;
    KeyxDI      : in unsigned(2-1 downto 0);

    RLEDxSO : out std_logic;
    GLEDxSO : out std_logic
);

end entity key_lock_timed;

architecture rtl of key_lock_timed is

  -- Declare Types for FSM
  type KeyLockFSM_Type is (
    Closed, Wrong1P, Wrong1R, Wrong2P, Wrong2R, Wrong3P,
    OK0P, OK0R, OK2P, OK2R, OK1P,
    Opened
  );

  -- FSM
  signal STATExDN, STATExDP : KeyLockFSM_Type;

  -- Counters
  -- constant DelCntMAX    : integer := 250000; -- High for 2 milliseconds
  constant DelCntMAX    : integer := 250000000; -- High for 2 seconds
  signal CNTxDN, CNTxDP : unsigned(30-1 downto 0);
  signal CountCLRxS     : std_logic;
  signal CountENxS      : std_logic;

begin

  -- FSM
  p_fsm_comb: process (all) is
  begin
    STATExDN   <= STATExDP;
    GLEDxSO    <= '0';  -- default : LED OFF
    RLEDxSO    <= '0';  -- default : LED OFF
    CountCLRxS <= '0';
    CountENxS  <= '0';

    case STATExDP is
      -- Initial state
      when Closed =>
        RLEDxSO <= '1';
        if KeyValidxSI = '1' then
          if KeyxDI = 0 then
            STATExDN <= OK0P;
          else
            STATExDN <= Wrong1P;
          end if;
        end if;

      -- States where code was wrong
      when Wrong1P =>
        if KeyValidxSI = '0' then -- Wait for release
          STATExDN <= Wrong1R;
        end if;
      when Wrong1R =>
        if KeyValidxSI = '1' then
          STATExDN <= Wrong2P;
        end if;
      when Wrong2P =>
        if KeyValidxSI = '0' then
          STATExDN <= Wrong2R;
        end if;
      when Wrong2R =>
        if KeyValidxSI = '1' then
          STATExDN <= Wrong3P;
        end if;
      when Wrong3P =>
        if KeyValidxSI = '0' then
          STATExDN <= Closed;
        end if;

      -- States where code is still OK
      when OK0P =>
        if KeyValidxSI = '0' then -- Wait for release
          STATExDN <= OK0R;
        end if;
      when OK0R =>
        if KeyValidxSI = '1' then
          if KeyxDI = 2 then
            STATExDN <= OK2P;
          else
            STATExDN <= Wrong2P;
          end if;
        end if;
      when OK2P =>
        if KeyValidxSI = '0' then
          STATExDN <= OK2R;
        end if;
      when OK2R =>
        if KeyValidxSI = '1' then
          if KeyxDI = 1 then
            STATExDN <= OK1P;
          else
            STATExDN <= Wrong3P;
          end if;
        end if;
      when OK1P =>
        if KeyValidxSI = '0' then
          STATExDN   <= Opened;
          CountCLRxS <= '1';
          CountENxS  <= '1';
        end if;

      when Opened =>
        GLEDxSO    <= '1';
        CountENxS  <= '1';
        if CNTxDP = DelCntMAX then
          STATExDN <= Closed;
        end if;

      when others => NULL;
    end case;
  end process p_fsm_comb;

  -- FSM Sequential Process
  p_fsm_seq: process (CLKxCI, RSTxRI) is
  begin
    if (RSTxRI = '1') then
      STATExDP <= Closed;
    elsif (CLKxCI'event and CLKxCI = '1') then
      STATExDP <= STATExDN;
    end if;
  end process p_fsm_seq;

  -- Counter
  CNTxDN <= (others => '0') when CountCLRxS = '1' else
            CNTxDP + 1      when CountENxS  = '1' else
            CNTxDP;

  p_cnt: process (CLKxCI, RSTxRI) is
  begin
    if (RSTxRI = '1') then
      CNTxDP <= (others => '0');
    elsif (CLKxCI'event and CLKxCI = '1') then
      CNTxDP <= CNTxDN;
    end if;
  end process p_cnt;

end architecture rtl;
