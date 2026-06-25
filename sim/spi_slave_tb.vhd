library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_slave_tb is
end entity;

architecture sim of spi_slave_tb is

    -- system signals
    signal clk        : std_logic := '0';
    signal reset_n    : std_logic := '0';
    
    -- slave signals
    signal tx_data    : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_valid   : std_logic := '0';
    signal rx_valid   : std_logic;
    signal rx_data    : std_logic_vector(7 downto 0);
    signal busy       : std_logic;
    
    -- spi bus signals
    signal sclk       : std_logic := '0';
    signal mosi       : std_logic := '0';
    signal miso       : std_logic;
    signal cs_n       : std_logic := '1';

    -- tb variables to track what the master receives
    signal master_rx_byte : std_logic_vector(7 downto 0) := (others => '0');
    signal master_tx_byte : std_logic_vector(7 downto 0) := x"5A"; -- Master sends 0x5A

    -- consts
    constant CLK_PERIOD      : time := 10 ns;   -- 100 MHz System Clock
    constant SPI_HALF_PERIOD : time := 500 ns;  -- 1 MHz SPI Clock (500ns low, 500ns high)

begin


    dut : entity work.spi_slave
        port map (
            clk_i      => clk,
            reset_n_i  => reset_n,
            tx_data_i  => tx_data,
            tx_valid_i => tx_valid,
            rx_valid_o => rx_valid,
            rx_data_o  => rx_data,
            busy_o     => busy,
            spi_sclk_i => sclk,
            spi_mosi_i => mosi,
            spi_miso_o => miso,
            spi_cs_n_i => cs_n
        );


    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;


    stim_process : process
    begin
        -- reset
        reset_n <= '1';
        wait for 100 ns;
        reset_n <= '0';
        wait for 100 ns;

        -- load data for slave to send
        tx_data <= x"3C"; 
        
        wait for 500 ns;

        
        -- master pulls chip select low to wake up the slave
        cs_n <= '0';
        
        -- give slave time to wake
        wait for SPI_HALF_PERIOD;

        -- Loop through all 8 bits (MSB first, so index 7 down to 0)
        for i in 7 downto 0 loop
            
            -- Master places its bit on MOSI
            mosi <= master_tx_byte(i);
            
            -- Wait for data to stabilize
            wait for SPI_HALF_PERIOD / 2; 
            
            -- Master pulls SCLK HIGH (RISING EDGE)
            -- The Slave will sample MOSI right here!
            sclk <= '1';
            
            -- The Master samples MISO right here!
            master_rx_byte(i) <= miso;
            
            wait for SPI_HALF_PERIOD;
            
            -- Master pulls SCLK LOW (FALLING EDGE)
            -- The Slave will shift its register and push the next bit to MISO!
            sclk <= '0';
            
            wait for SPI_HALF_PERIOD / 2;
            
        end loop;

        -- Master pulls Chip Select HIGH to end the transaction
        wait for SPI_HALF_PERIOD;
        cs_n <= '1';
        

        -- Wait a few clock cycles to let the Slave pulse rx_valid_o
        wait for 500 ns;

        assert false report "Simulation finished!" severity failure;

    end process;

end architecture;