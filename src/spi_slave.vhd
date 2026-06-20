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
end Behavioral;
