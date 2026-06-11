library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx_tb is
end uart_rx_tb;

architecture sim of uart_rx_tb is
    -- Constants
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz clock
    
    -- Signals to connect to the UUT (Unit Under Test)
    signal clk      : std_logic := '0';
    signal tick     : std_logic := '0';
    signal rx       : std_logic := '1';
    signal reset    : std_logic := '0';
    signal data_out : std_logic_vector(7 downto 0);
    signal rx_done  : std_logic;
    signal busy     : std_logic;

begin

    -- Instantiate the UART Receiver
    UUT: entity work.uart_rx
        port map (
            clk      => clk,
            tick     => tick,
            rx       => rx,
            reset    => reset,
            data_out => data_out,
            rx_done  => rx_done,
            busy     => busy
        );

    -- Clock Generation
    clk <= not clk after CLK_PERIOD / 2;

    -- Tick Generation (Simulating a 16x Baud Tick)
    -- This creates a pulse every 4 clock cycles for simulation speed
    process
    begin
        wait for CLK_PERIOD * 4;
        tick <= '1';
        wait for CLK_PERIOD;
        tick <= '0';
    end process;

    -- Stimulus Process: Sending the byte 0xA5 (10100101)
    process
    begin
        -- Initial State
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;

        -- 1. Start Bit (Logic '0')
        rx <= '0';
        wait for (CLK_PERIOD * 5 * 16); -- Wait for 16 ticks

        -- 2. Data Bits (LSB First: 1, 0, 1, 0, 0, 1, 0, 1)
        -- Bit 0: '1'
        rx <= '1'; wait for (CLK_PERIOD * 5 * 16);
        -- Bit 1: '0'
        rx <= '0'; wait for (CLK_PERIOD * 5 * 16);
        -- Bit 2: '1'
        rx <= '1'; wait for (CLK_PERIOD * 5 * 16);
        -- Bit 3: '0'
        rx <= '0'; wait for (CLK_PERIOD * 5 * 16);
        -- Bit 4: '0'
        rx <= '0'; wait for (CLK_PERIOD * 5 * 16);
        -- Bit 5: '1'
        rx <= '1'; wait for (CLK_PERIOD * 5 * 16);
        -- Bit 6: '0'
        rx <= '0'; wait for (CLK_PERIOD * 5 * 16);
        -- Bit 7: '1'
        rx <= '1'; wait for (CLK_PERIOD * 5 * 16);

        -- 3. Stop Bit (Logic '1')
        rx <= '1';
        wait for (CLK_PERIOD * 5 * 16);

        -- Wait and finish
        wait for 500 ns;
        assert false report "Simulation Finished" severity note;
        wait;
    end process;

end sim;