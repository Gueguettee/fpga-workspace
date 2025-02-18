--=============================================================================
-- @file arbiter.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
--
-- arbiter
--
-- @brief This file specifies a basic arbiter circuit
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR ARBITER
--=============================================================================
entity arbiter is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    Key0xSI : in std_logic;
    Key1xSI : in std_logic;

    GLED0xSO : out std_logic;
    RLED0xSO : out std_logic;
    GLED1xSO : out std_logic;
    RLED1xSO : out std_logic
  );
end arbiter;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of arbiter is

  type ArbiterFSM_T is (WAIT_REQ0, WAIT_REQ1, GRANT_SS0, GRANT_SS1);

  -- constant CNT_TIMEOUT : integer := 250000000; -- Timeout after 2 seconds
  constant CNT_TIMEOUT : integer := 25; -- Timeout after 200ns (for simulation)

  signal STATExSN, STATExSP : ArbiterFSM_T;
  signal CountxDN, CountxDP : unsigned(28-1 downto 0);

  signal CountTimeoutxS : std_logic; -- If 1, counter has timed out (block increments)
  signal CountENxS      : std_logic; -- If 1, allow counter to increment
  signal CountCLRxS     : std_logic; -- If 1, reset the counter

  signal User0StatesxS : std_logic; -- If 1, in a state where user 0 can be served
  signal User1StatesxS : std_logic; -- If 1, in a state where user 1 can be served


--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- STATE AND DATA REGISTERS
-- Processes for updating the state and data registers
--=============================================================================
  process (CLKxCI, RSTxRI) is
  begin
    if (RSTxRI = '1') then
      STATExSP <= WAIT_REQ0;
      CountxDP <= (others => '0');
    elsif (CLKxCI'event and CLKxCI = '1') then
      STATExSP <= STATExSN;
      CountxDP <= CountxDN;
    end if;
  end process;

--=============================================================================
-- FSM
-- Process defining the FSM for the arbiter
--=============================================================================
  process (all) is
  begin
    STATExSN   <= STATExSP;
    CountCLRxS <= '0';

    -- FSM for arbiter. If request is removed or we switch to serving another
    -- user, the counter is cleared to guarantee 2 seconds of access
    case STATExSP is
      -- WAIT_REQ0: Prioritize requests from user 0, otherwise serve user 1
      when WAIT_REQ0 =>
        CountCLRxS <= not Key1xSI or Key0xSI;

        if Key0xSI = '1' then
          STATExSN <= GRANT_SS0;
        elsif Key1xSI = '1' and CountTimeoutxS = '0' then
          STATExSN <= GRANT_SS1;
        end if;

      -- WAIT_REQ1: Prioritize requests from user 1, otherwise serve user 0
      when WAIT_REQ1 =>
        CountCLRxS <= not Key0xSI or Key1xSI;

        if Key1xSI = '1' then
          STATExSN <= GRANT_SS1;
        elsif Key0xSI = '1' and CountTimeoutxS = '0' then
          STATExSN <= GRANT_SS0;
        end if;

      -- GRANT_SS0: Serving user 0 until request is removed or user 1 makes a
      -- request after timeout (in WAIT_REQ1)
      when GRANT_SS0 =>
        CountCLRxS <= not Key0xSI;

        if Key0xSI = '0' or CountTimeoutxS = '1' then
          STATExSN <= WAIT_REQ1;
        end if;

      -- GRANT_SS1: Serving user 1 until request is removed or user 0 makes a
      -- request after timeout (in WAIT_REQ0)
      when GRANT_SS1 =>
        CountCLRxS <= not Key1xSI;

        if Key1xSI = '0' or CountTimeoutxS = '1' then
          STATExSN <= WAIT_REQ0;
        end if;

      when others => NULL;
    end case;
  end process;

--=============================================================================
-- COUNTER LOGIC
--=============================================================================

  -- Enable counter when access has been granted for a guaranteed 2 seconds
  CountENxS      <= '1' when (STATExSP = GRANT_SS0 or STATExSP = GRANT_SS1) else '0';
  CountTimeoutxS <= '1' when (CountxDP = CNT_TIMEOUT) else '0';

  CountxDN <= (others => '0') when CountCLRxS = '1' else
              CountxDP + 1    when (CountENxS = '1' and CountTimeoutxS = '0') else
              CountxDP;

--=============================================================================
-- OUTPUT LOGIC
--=============================================================================

  -- GRANT_SS0 AND WAIT_REQ1 represent states where user 0 can be served
  -- This code could also be in the process for the FSM as this behavious is
  -- represented in your FSM state diagram, but for reasons of clarity, we have
  -- written the assignment of the output LED values outside the FSM process.
  User0StatesxS <= '1' when (STATExSP = GRANT_SS0 or STATExSP = WAIT_REQ1) else '0';
  GLED0xSO      <= '1' when Key0xSI = '1' and     User0StatesxS = '1' else '0';
  RLED0xSO      <= '1' when Key0xSI = '1' and not User0StatesxS = '1' else '0';

  -- GRANT_SS1 AND WAIT_REQ0 represent states where user 1 can be served
  User1StatesxS <= '1' when (STATExSP = GRANT_SS1 or STATExSP = WAIT_REQ0) else '0';
  GLED1xSO      <= '1' when Key1xSI = '1' and     User1StatesxS = '1' else '0';
  RLED1xSO      <= '1' when Key1xSI = '1' and not User1StatesxS = '1' else '0';

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
