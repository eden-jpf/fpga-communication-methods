library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_slave is
    Port (
        clk_i        : in  STD_LOGIC; 
        reset_n_i    : in  STD_LOGIC;
        
        -- Internal FPGA Interface
        tx_data_i  : in  STD_LOGIC_VECTOR(7 downto 0); 
        tx_valid_i : in  STD_LOGIC;                    
        rx_valid_o : out STD_LOGIC;                    
        rx_data_o  : out STD_LOGIC_VECTOR(7 downto 0); 
        busy_o     : out STD_LOGIC;
        
        -- Physical SPI Bus
        spi_sclk_i : in  STD_LOGIC; 
        spi_mosi_i : in  STD_LOGIC;
        spi_miso_o : out STD_LOGIC;
        spi_cs_n_i : in  STD_LOGIC
    );
end spi_slave;

architecture Behavioral of spi_slave is

    -- Internal Data Registers
    signal tx_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_count : integer range 0 to 7 := 0;

    -- Synchronizer registers
    signal sclk_sync : std_logic_vector(2 downto 0) := "000";
    signal cs_sync   : std_logic_vector(2 downto 0) := "111"; 
    signal mosi_sync : std_logic_vector(1 downto 0) := "00";
    
    -- Edge detection flags
    signal sclk_rising_edge  : std_logic;
    signal sclk_falling_edge : std_logic;
    signal cs_falling_edge   : std_logic;

begin


    sclk_rising_edge  <= '1' when (sclk_sync(2 downto 1) = "01") else '0';
    sclk_falling_edge <= '1' when (sclk_sync(2 downto 1) = "10") else '0';
    cs_falling_edge   <= '1' when (cs_sync(2 downto 1)   = "10") else '0';

    -- Physical MISO pin constantly driven by the MSB of the TX register
    spi_miso_o <= tx_reg(7);


    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if reset_n_i = '0' then
                sclk_sync  <= "000";
                cs_sync    <= "111"; 
                mosi_sync  <= "00";
                tx_reg     <= (others => '0');
                rx_reg     <= (others => '0');
                rx_data_o  <= (others => '0');
                rx_valid_o <= '0';
                busy_o     <= '0';
                bit_count  <= 0;
            else
                -- Shift Register Synchronizers (taking our 100MHz snapshots)
                sclk_sync <= sclk_sync(1 downto 0) & spi_sclk_i;
                cs_sync   <= cs_sync(1 downto 0)   & spi_cs_n_i;
                mosi_sync <= mosi_sync(0)          & spi_mosi_i;
                
                -- Default the valid pulse to 0 so it only spikes for 1 clock cycle
                rx_valid_o <= '0';


                if cs_falling_edge = '1' then
                    -- Start of communication
                    bit_count <= 0;           
                    tx_reg    <= tx_data_i;
                    busy_o    <= '1';         

                -- check SCLK while CS is low
                elsif cs_sync(1) = '0' then
                    
                    if sclk_rising_edge = '1' then
                        -- Start sampling
                        rx_reg <= rx_reg(6 downto 0) & mosi_sync(1);
                        
                    elsif sclk_falling_edge = '1' then
                        -- Start shifting
                        if bit_count = 7 then
                            rx_data_o  <= rx_reg;
                            rx_valid_o <= '1';
                            busy_o     <= '0';
                        else
                            tx_reg <= tx_reg(6 downto 0) & '0';
                            bit_count <= bit_count + 1;
                        end if;
                    end if;
                    
                else
                    -- Chip Select is High (Idle)
                    busy_o <= '0';
                end if;
                
            end if;
        end if;
    end process;

end Behavioral;