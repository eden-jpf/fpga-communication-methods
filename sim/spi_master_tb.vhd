library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_master_tb is
end entity;

architecture sim of spi_master_tb is

    -- DUT signals
    signal clk      : std_logic := '0';
    signal tick     : std_logic := '0';
    signal start    : std_logic := '0';
    signal reset    : std_logic := '0';
    signal busy     : std_logic;
    signal data_in  : std_logic_vector(7 downto 0);
    signal data_out : std_logic_vector(7 downto 0);
    signal sclk     : std_logic := '0';
    signal mosi     : std_logic;
    signal miso     : std_logic;
    signal cs     : std_logic;
    

    -- Clock period (100 MHz)
    constant CLK_PERIOD : time := 10 ns;

    -- Baud tick generation
    constant TICKS_PER_BIT : integer := 16;
    signal tick_count : integer := 0;

begin

    -- ============================
    -- DUT instantiation
    -- ============================
    dut : entity work.spi_master
        port map (
            clk_i      => clk,
            tick_i     => tick,
            reset_i    => reset,
            tx_data_i  => data_in,
            tx_valid_i => start,
            rx_data_o  => data_out,
            busy_o     => busy,
            spi_sclk_o => sclk,       
            spi_mosi_o => mosi,
            spi_miso_i => miso,
            spi_cs_n_o => cs
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


end architecture;
