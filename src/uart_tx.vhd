library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_tx is
    Port (
        clk      : in  std_logic;
        tick     : in  std_logic;
        start    : in  std_logic;
        reset    : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        tx       : out std_logic;
        busy     : out std_logic;
        tx_done  : out std_logic
    );
end uart_tx;

architecture Behavioral of uart_tx is

    type tx_state_t is (S_IDLE, S_START, S_DATA, S_STOP);
    signal state : tx_state_t := S_IDLE;

    signal shift_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal bit_count : unsigned(2 downto 0) := (others => '0');

    signal tx_i : std_logic := '1';

    signal start_sync    : std_logic := '0';
    signal start_prev    : std_logic := '0';
    signal start_pending : std_logic := '0';
    signal start_accept  : std_logic := '0';

    signal tx_done_i : std_logic := '0';

begin

    busy <= '0' when state = S_IDLE else '1';
    tx <= tx_i;
    tx_done <= tx_done_i;

    -- Start synchroniser / edge detect
    process(clk)
    begin
        if rising_edge(clk) then
            start_sync <= start;
            start_prev <= start_sync;

            if start_sync = '1' and start_prev = '0' then
                start_pending <= '1';
            elsif start_accept = '1' then
                start_pending <= '0';
            end if;
        end if;
    end process;

    -- UART TX state machine
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                state        <= S_IDLE;
                tx_i         <= '1';
                shift_reg    <= (others => '0');
                bit_count    <= (others => '0');
                start_accept <= '0';
                tx_done_i    <= '0';
            else
                start_accept <= '0';

                if tick = '1' then
                    tx_done_i <= '0';

                    case state is
                        when S_IDLE =>
                            tx_i <= '1';
                            bit_count <= (others => '0');

                            if start_pending = '1' then
                                start_accept <= '1';
                                shift_reg <= data_in;
                                state <= S_START;
                            end if;

                        when S_START =>
                            tx_i <= '0';
                            state <= S_DATA;

                        when S_DATA =>
                            tx_i <= shift_reg(0);
                            shift_reg <= '0' & shift_reg(7 downto 1);

                            if bit_count = to_unsigned(7, bit_count'length) then
                                state <= S_STOP;
                            else
                                bit_count <= bit_count + 1;
                            end if;

                        when S_STOP =>
                            tx_i <= '1';
                            tx_done_i <= '1';
                            state <= S_IDLE;
                    end case;
                end if;
            end if;
        end if;
    end process;

end Behavioral;
