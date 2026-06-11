--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

--entity uart_tx is
--    port (
--        CLK100MHZ : in  std_logic;
--        LED : out std_logic
--    );
--end uart_tx;

--architecture rtl of uart_tx is
--    -- Signal to hold the current LED state
--    signal r_LED   : std_logic := '0';
--    -- Counter capable of holding up to 50,000,000
--    signal r_Count : integer range 0 to 50000000 := 0; 
--begin

--    process(CLK100MHZ)
--    begin
--        -- This triggers exactly once every clock cycle (on the rising edge)
--        if rising_edge(CLK100MHZ) then
            
--            -- If we hit 50 million (0.5 seconds at 100MHz)
--            if r_Count = 50000000 then
--                r_LED   <= not r_LED; -- Flip the LED state
--                r_Count <= 0;         -- Reset the counter
--            else
--                r_Count <= r_Count + 1; -- Keep counting
--            end if;

--        end if;
--    end process;

--    -- Wire the internal register to the physical output pin
--    LED <= r_LED;

--end rtl;