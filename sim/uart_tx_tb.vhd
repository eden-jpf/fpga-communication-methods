library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx_tb is
end entity;

architecture sim of uart_tx_tb is

    -- DUT signals
    signal clk      : std_logic := '0';
    signal tick     : std_logic := '0';
    signal start    : std_logic := '0';
    signal reset    : std_logic := '0';
    signal tx       : std_logic;
    signal busy     : std_logic;
    signal data_in  : std_logic_vector(7 downto 0);
    signal tx_done  : std_logic;

    -- Clock period (100 MHz)
    constant CLK_PERIOD : time := 10 ns;

    -- Baud tick generation
    constant TICKS_PER_BIT : integer := 16;
    signal tick_count : integer := 0;

begin

    -- ============================
    -- DUT instantiation
    -- ============================
    dut : entity work.uart_tx
        port map (
            clk      => clk,
            tick     => tick,
            start    => start,
            reset    => reset,
            data_in  => data_in,
            tx       => tx,
            busy     => busy,
            tx_done  => tx_done
        );

    -- ============================
    -- Clock generator
    -- ============================
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- ============================
    -- Baud tick generator
    -- ============================
    tick_process : process(clk)
    begin
        if rising_edge(clk) then
            if tick_count = TICKS_PER_BIT - 1 then
                tick <= '1';
                tick_count <= 0;
            else
                tick <= '0';
                tick_count <= tick_count + 1;
            end if;
        end if;
    end process;

    -- ============================
    -- Stimulus
    -- ============================
    stim_process : process
    begin
        -- Apply reset
        reset <= '1';
        wait for 100 ns;
        reset <= '0';

        wait for 200 ns;

        -- ========= Send 'A' =========
        data_in <= x"41"; -- 'A'
        start   <= '1';
        wait for CLK_PERIOD;
        start   <= '0';

        wait until busy = '1';
        
        
        wait until busy = '0';
        
        wait for 200 ns;

        -- ========= Send 'B' =========
        data_in <= x"42"; -- 'B'
        start   <= '1';
        wait for CLK_PERIOD;
        start   <= '0';

        wait until busy = '1';
        wait until busy = '0';

        wait for 1 ms;

        assert false report "Simulation finished" severity failure;
    end process;

end architecture;
