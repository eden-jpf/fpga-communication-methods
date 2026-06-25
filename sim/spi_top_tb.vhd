library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_top_tb is
end entity;

architecture sim of spi_top_tb is

    -- system signals
    signal clk     : std_logic := '0';
    signal reset_n : std_logic := '0';
    signal tick    : std_logic := '0';

    -- master interface
    signal m_tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal m_tx_valid : std_logic := '0';
    signal m_rx_data  : std_logic_vector(7 downto 0);
    signal m_busy     : std_logic;

    -- slave interface
    signal s_tx_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_tx_valid : std_logic := '0';
    signal s_rx_valid : std_logic;
    signal s_rx_data  : std_logic_vector(7 downto 0);
    signal s_busy     : std_logic;

    -- physical spi bus
    signal spi_sclk : std_logic;
    signal spi_mosi : std_logic;
    signal spi_miso : std_logic;
    signal spi_cs_n : std_logic;

    -- constants
    constant CLK_PERIOD           : time := 10 ns;
    constant SYS_CLK_FREQ         : integer := 100_000_000; -- 100 MHz
    constant SPI_CLK_FREQ         : integer := 1_000_000;   -- 1 MHz
    constant TICKS_PER_HALF_CYCLE : integer := SYS_CLK_FREQ / (2 * SPI_CLK_FREQ);
    signal tick_count             : integer := 0;

begin


    master_inst : entity work.spi_master
        port map (
            clk_i      => clk,
            tick_i     => tick,
            reset_n_i  => reset_n,
            
            tx_data_i  => m_tx_data,
            tx_valid_i => m_tx_valid,
            rx_data_o  => m_rx_data,
            busy_o     => m_busy,
            
            spi_sclk_o => spi_sclk,
            spi_mosi_o => spi_mosi,
            spi_miso_i => spi_miso,
            spi_cs_n_o => spi_cs_n
        );


    slave_inst : entity work.spi_slave
        port map (
            clk_i      => clk,
            reset_n_i  => reset_n,
            
            tx_data_i  => s_tx_data,
            tx_valid_i => s_tx_valid,
            rx_valid_o => s_rx_valid,
            rx_data_o  => s_rx_data,
            busy_o     => s_busy,
            
            spi_sclk_i => spi_sclk,
            spi_mosi_i => spi_mosi,
            spi_miso_o => spi_miso,
            spi_cs_n_i => spi_cs_n
        );


    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    tick_process : process(clk)
    begin
        if rising_edge(clk) then
            if tick_count = TICKS_PER_HALF_CYCLE - 1 then
                tick <= '1';
                tick_count <= 0;
            else
                tick <= '0';
                tick_count <= tick_count + 1;
            end if;
        end if;
    end process;


    stim_process : process
    begin
        -- reset
        reset_n <= '1';
        wait for 100 ns;
        reset_n <= '0';
        wait for 200 ns;

        -- load data into slave
        s_tx_data <= x"CA"; 

        wait for 1 us;

        -- load data into master
        m_tx_data  <= x"5A";
        
        -- trigger master to start communication
        m_tx_valid <= '1';
        wait for CLK_PERIOD;
        m_tx_valid <= '0';

        -- wait for the transaction to finish
        wait until m_busy = '1'; -- Master starts
        wait until m_busy = '0'; -- Master finishes

        -- Give it some breathing room
        wait for 2 us;

        -- End the simulation cleanly
        assert false report "Integration Simulation Finished!" severity failure;
    end process;

end architecture;