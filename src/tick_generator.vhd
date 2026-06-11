library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tick_generator is
    generic (
        CLOCK_FREQ : integer := 100_000_000; -- Hz
        BAUD_RATE  : integer := 115200
    );
    port ( 
        clk  : in  std_logic;
        tick : out std_logic
    );
end tick_generator;

architecture Behavioral of tick_generator is

    constant TICK_LIMIT : integer := CLOCK_FREQ / BAUD_RATE - 1;
    signal tick_count   : integer range 0 to TICK_LIMIT := 0;

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if tick_count = TICK_LIMIT then
                tick_count <= 0;
                tick <= '1';          -- 1-clock-wide pulse
            else
                tick_count <= tick_count + 1;
                tick <= '0';
            end if;
        end if;
    end process;

end Behavioral;
