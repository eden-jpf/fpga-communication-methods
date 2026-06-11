library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx is
    Port (
        clk      : in  std_logic;
        tick     : in  std_logic;  -- 16x baud tick
        rx       : in  std_logic;
        reset    : in  std_logic;
        data_out : out std_logic_vector(7 downto 0);
        rx_done  : out std_logic;
        busy     : out std_logic
    );
end uart_rx;

architecture Behavioral of uart_rx is

    type rx_state_t is (S_IDLE, S_START, S_DATA, S_STOP);
    signal state      : rx_state_t := S_IDLE;
    
    signal shift_reg  : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_count  : unsigned(2 downto 0) := (others => '0');
    signal tick_count : unsigned(3 downto 0) := (others => '0');
    signal rx_done_i  : std_logic := '0';
    
    -- Synchronizer signals (Double Flip-Flop)
    signal rx_sync : std_logic_vector(1 downto 0) := "11";

begin

    -- Connect internal signals to output ports
    data_out <= shift_reg;
    rx_done  <= rx_done_i;

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state <= S_IDLE;
                rx_done_i <= '0';
                busy <= '0';
                rx_sync <= "11";
            else
                -- Synchronize RX input to internal clock to prevent metastability
                rx_sync <= rx_sync(0) & rx;

                if tick = '1' then
                    case state is
                        
                        when S_IDLE =>
                            busy <= '0';
                            rx_done_i <= '0';
                            -- Use synchronized rx_sync(1) instead of raw rx
                            if rx_sync(1) = '0' then
                                tick_count <= (others => '0');
                                state <= S_START;
                                busy <= '1';
                            end if;

                        when S_START =>
                            if tick_count = 7 then
                                if rx_sync(1) = '0' then -- Verify it's still 0 (Glitch Rejection)
                                    tick_count <= (others => '0');
                                    bit_count  <= (others => '0');
                                    state      <= S_DATA;
                                else
                                    state <= S_IDLE; -- It was just noise
                                end if;
                            else
                                tick_count <= tick_count + 1;
                            end if;

                        when S_DATA =>
                            if tick_count = 15 then
                                tick_count <= (others => '0');
                                -- Shift in RX (LSB first)
                                shift_reg <= rx_sync(1) & shift_reg(7 downto 1); 
                                
                                if bit_count = 7 then
                                    state <= S_STOP;
                                else
                                    bit_count <= bit_count + 1;
                                end if;
                            else
                                tick_count <= tick_count + 1;
                            end if;

                        when S_STOP =>
                            if tick_count = 15 then
                                rx_done_i <= '1';
                                state     <= S_IDLE;
                            else
                                tick_count <= tick_count + 1;
                            end if;

                        when others =>
                            state <= S_IDLE;

                    end case;
                end if; -- end tick
            end if; -- end reset
        end if; -- end clk
    end process;

end Behavioral;