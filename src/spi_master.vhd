library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_master is
    Port (
        -- System
        clk_i        : in  STD_LOGIC; -- clock signal from FPGA hardware
        tick_i       : in STD_LOGIC; -- Slowed down tick for spi data sending/receiving, Two ticks = one full SCLK wave. *
        reset_n_i    : in  STD_LOGIC;
        
        -- Internal FPGA Interface
        tx_data_i  : in  STD_LOGIC_VECTOR(7 downto 0); -- tx_data_i (IN) : Main FPGA logic pushes data INTO this module for transmission even though it is a tx
        tx_valid_i : in  STD_LOGIC;                    -- Trigger to start sending data, may replace with button
        rx_data_o  : out STD_LOGIC_VECTOR(7 downto 0); -- rx_data_o (OUT): This module pushes received data OUT to the main FPGA logic even though it is a rx
        busy_o     : out STD_LOGIC;
        
        -- Physical SPI Bus
        spi_sclk_o : out STD_LOGIC; -- Physical output pin that sends the serial clock signal to the slave device.
                                    -- This is also a burst clock, unlike clk_i which is always active, this clock is only allowed to tick when CS is pulled low
                            
        spi_mosi_o : out STD_LOGIC;
        spi_miso_i : in  STD_LOGIC;
        spi_cs_n_o : out STD_LOGIC
    );
end spi_master;


architecture Behavioral of spi_master is

    type tx_state_t is (S_IDLE, S_LATCH, S_START, S_SHIFT, S_FINISH);
    signal state : tx_state_t := S_IDLE;
    
    signal tx_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal rx_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_count   : integer range 0 to 7 := 0;
    
    
    signal sclk_int : std_logic := '0';
    
    
    
    
begin


    spi_sclk_o <= sclk_int;
    spi_mosi_o <= tx_reg(7);

    process(clk_i)
    begin
        -- Handle state machine
        if rising_edge(clk_i) then
            if reset_n_i = '1' then
                state      <= S_IDLE;
                spi_cs_n_o <= '1';
                busy_o     <= '0';
                -- spi_mosi_o <= '0';
                sclk_int   <= '0';
                rx_data_o  <= (others => '0');
                tx_reg  <= (others => '0');
                rx_reg  <= (others => '0');
            else
                case state is
                     when S_IDLE =>
                        spi_cs_n_o <= '1';  -- hold spi_cs_n_o high
                        busy_o <= '0';      -- hold busy_o low
                        
                        -- check tx_valid_i for input
                        -- if notice input go into S_LATCH 
                        if tx_valid_i = '1' then
                            state <= S_LATCH;
                        end if;
                        
                        
                     when S_LATCH =>
                        busy_o <= '1';          -- drive busy_o high
                        tx_reg <= tx_data_i; -- latch tx_data_i to shift register
                        bit_count <= 0;
                        state <= S_START;       -- Move onto S_START
                     when S_START =>
                        spi_cs_n_o <= '0';  -- wake the slave by pulling spi_cs_n_o low
                        -- wait half clock cycle to ensure slave is awake
                        state <= S_SHIFT;   -- Move onto S_SHIFT
                    when S_SHIFT =>
                        -- Wait for the pulse from your tick generator
                        if tick_i = '0' then 
                            
                            -- Toggle the clock for the outside world
                            sclk_int <= not sclk_int; 
                            
                            -- Determine which edge this is based on the CURRENT state
                            if sclk_int = '0' then
                                -------------------------------------------------
                                -- RISING EDGE LOGIC (0 -> 1)
                                -------------------------------------------------
                                -- Pull data in from spi_miso_i and put it in the LSB
                                rx_reg <= rx_reg(6 downto 0) & spi_miso_i;
                                
                            else
                                -------------------------------------------------
                                -- FALLING EDGE LOGIC (1 -> 0)
                                -------------------------------------------------
                                -- Check if we are done (bit_count = 7)
                                -- If not done: 
                                --   1. Shift the register left
                                --   2. Push the new MSB to spi_mosi_o
                                --   3. Add 1 to your bit counter
                                
                                if bit_count = 7 then
                                    -- DO NOT SHIFT ON THE 8TH EDGE!
                                    -- The final bit was just sampled on the rising edge.
                                    -- If we shift here, we destroy the data.
                                    state <= S_FINISH;
                                else
                                    -- Shift left and pad with a placeholder '0'
                                    tx_reg <= tx_reg(6 downto 0) & '0';
                                    bit_count <= bit_count + 1;
                                end if;
                                
                            end if;
                        end if;
                        
                     when S_FINISH =>
                        spi_cs_n_o <= '1';      -- spi_cs_n_o goes HIGH
                        rx_data_o <= rx_reg; -- 8 bits pulled from shift register are now put to the rx_data_o output port so user logic can read it
                        busy_o <= '0';          -- drive busy_o low
                        state <= S_IDLE;        -- Return to IDLE state
                end case;
            end if;
        end if;    
            
            
            
        
        
        
    end process;


end Behavioral;


-- * the clock has to transition twice for every bit (once going high to sample, once going low to shift).
    -- If you want a 1 MHz SPI clock, you need to generate a toggle event every half-cycle. 
    -- Therefore, you must set the BAUD_RATE generic of your tick generator to 2 MHz (2x your target SPI frequency).
    -- Two ticks = one full SCLK wave.
    -- DRAWBACK:
        --    The slight drawback: When your main logic pulses tx_valid_i and you move into S_START, you don't know exactly where the tick generator is in its cycle. 
        --    The first tick might arrive immediately (10 nanoseconds later), or it might take the full cycle time to arrive.
