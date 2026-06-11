library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_top_tb is
end uart_top_tb;

architecture sim of uart_top_tb is

    -- DUT signals
    signal clk        : std_logic := '0';
    signal btnc       : std_logic := '0';
    signal uart_tx    : std_logic;
    signal led        : std_logic_vector(1 downto 0);

    constant CLK_PERIOD : time := 10 ns; -- 100 MHz

begin

    --------------------------------------------------------------------
    -- Clock generation
    --------------------------------------------------------------------
    clk <= not clk after CLK_PERIOD / 2;

    --------------------------------------------------------------------
    -- DUT instantiation
    --------------------------------------------------------------------
    dut : entity work.top_uart_tx
        port map (
            CLK100MHZ   => clk,
            BTNC        => btnc,
            UART_TXD_IN => uart_tx,
            LED         => led
        );

    --------------------------------------------------------------------
    -- Stimulus
    --------------------------------------------------------------------
    stim_proc : process
    begin
        -- initial reset time
        wait for 1 us;

        -- press button
        btnc <= '1';
        wait for 20 ms;     -- long press (debouncer friendly)
        btnc <= '0';

        -- let UART run
        wait for 100 ms;

        -- stop simulation
        assert false report "End of simulation" severity failure;
    end process;

end architecture;
