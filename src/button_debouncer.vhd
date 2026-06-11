library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity button_debouncer is
    Port (
        clk          : in  std_logic;          -- system clock
        btn_raw      : in  std_logic;          -- noisy button
        clean_level  : out std_logic;          -- debounced level
        btn_rising  : out std_logic           -- 1-cycle pulse
    );
end button_debouncer;

architecture Behavioral of button_debouncer is

    signal sync_0, sync_1 : std_logic := '0';
    signal last_stable     : std_logic := '0';
    signal counter         : unsigned(19 downto 0) := (others => '0');

    signal level_clean_i   : std_logic := '0';
    signal last_clean      : std_logic := '0';

begin

    process(clk)
    begin
        if rising_edge(clk) then

            -- 1. Synchronizer
            sync_0 <= btn_raw;
            sync_1 <= sync_0;

            -- 2. Debounce counter
            if sync_1 /= last_stable then
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;

            -- update last stable sample
            last_stable <= sync_1;

            -- 3. Accept stable value
            if counter = (counter'range => '1') then
                level_clean_i <= sync_1;
            end if;

            -- 4. Rising-edge output
            btn_rising <= level_clean_i AND (NOT last_clean);
            last_clean  <= level_clean_i;

        end if;
    end process;

    clean_level <= level_clean_i;

end Behavioral;
