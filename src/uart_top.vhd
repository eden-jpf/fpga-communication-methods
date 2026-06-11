library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_top is
    Port (
        CLK100MHZ    : in  std_logic;
        BTNC         : in  std_logic;
        UART_TXD_IN  : out std_logic;  -- FPGA TX → USB UART RX
        UART_RXD_OUT : in  std_logic;  -- USB UART TX → FPGA RX
        LED          : out std_logic_vector(15 downto 0)
    );
end uart_top;

architecture Behavioral of uart_top is

    ------------------------------------------------------------------
    -- Baud ticks
    ------------------------------------------------------------------
    signal uart_tick_1x  : std_logic;  -- TX tick (115200)
    signal uart_tick_16x : std_logic;  -- RX tick (16× baud)

    ------------------------------------------------------------------
    -- TX signals
    ------------------------------------------------------------------
    signal tx_start  : std_logic := '0';
    signal tx_busy   : std_logic;
    signal tx_done   : std_logic;
    signal tx_data   : std_logic_vector(7 downto 0);

    ------------------------------------------------------------------
    -- RX signals
    ------------------------------------------------------------------
    signal rx_data   : std_logic_vector(7 downto 0);
    signal rx_done   : std_logic;
    signal rx_busy   : std_logic;

    ------------------------------------------------------------------
    -- Message ROM: "HELLO\r\n"
    ------------------------------------------------------------------
    type msg_t is array (0 to 6) of std_logic_vector(7 downto 0);
    constant MESSAGE : msg_t := (
        x"48", -- H
        x"45", -- E
        x"4C", -- L
        x"4C", -- L
        x"4F", -- O
        x"0D", -- CR
        x"0A"  -- LF
    );

    signal msg_index : integer range 0 to 6 := 0;

    ------------------------------------------------------------------
    -- TX FSM
    ------------------------------------------------------------------
    type send_state_t is (S_IDLE, S_LOAD, S_START, S_WAIT_DONE);
    signal send_state : send_state_t := S_IDLE;

    ------------------------------------------------------------------
    -- Button
    ------------------------------------------------------------------
    signal btn_rising : std_logic;
    signal btn_clean  : std_logic;

begin

    ------------------------------------------------------------------
    -- Baud generators
    ------------------------------------------------------------------
    baud_tx : entity work.tick_generator
        generic map (
            CLOCK_FREQ => 100_000_000,
            BAUD_RATE  => 115200
        )
        port map (
            clk  => CLK100MHZ,
            tick => uart_tick_1x
        );

    baud_rx : entity work.tick_generator
        generic map (
            CLOCK_FREQ => 100_000_000,
            BAUD_RATE  => 115200 * 16
        )
        port map (
            clk  => CLK100MHZ,
            tick => uart_tick_16x
        );

    ------------------------------------------------------------------
    -- UART TX
    ------------------------------------------------------------------
    uart_tx_inst : entity work.uart_tx
        port map (
            clk     => CLK100MHZ,
            tick    => uart_tick_1x,
            start   => tx_start,
            reset   => '0',
            data_in => tx_data,
            tx      => UART_TXD_IN,
            busy    => tx_busy,
            tx_done => tx_done
        );

    ------------------------------------------------------------------
    -- UART RX (16× oversampled)
    ------------------------------------------------------------------
    uart_rx_inst : entity work.uart_rx
        port map (
            clk      => CLK100MHZ,
            tick     => uart_tick_16x,
            rx       => UART_RXD_OUT,
            reset    => '0',
            data_out => rx_data,
            rx_done  => rx_done,
            busy     => rx_busy
        );

    ------------------------------------------------------------------
    -- Button debouncer
    ------------------------------------------------------------------
    debouncer : entity work.button_debouncer
        port map (
            clk          => CLK100MHZ,
            btn_raw      => BTNC,
            clean_level  => btn_clean,
            btn_rising   => btn_rising
        );

    ------------------------------------------------------------------
    -- TX state machine
    ------------------------------------------------------------------
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            tx_start <= '0';

            case send_state is

                when S_IDLE =>
                    if btn_rising = '1' and tx_busy = '0' then
                        msg_index  <= 0;
                        send_state <= S_LOAD;
                    end if;

                when S_LOAD =>
                    tx_data    <= MESSAGE(msg_index);
                    send_state <= S_START;

                when S_START =>
                    tx_start <= '1';
                    if tx_busy = '1' then
                        send_state <= S_WAIT_DONE;
                    end if;

                when S_WAIT_DONE =>
                    if tx_busy = '0' then
                        if msg_index = 6 then
                            send_state <= S_IDLE;
                        else
                            msg_index  <= msg_index + 1;
                            send_state <= S_LOAD;
                        end if;
                    end if;

            end case;
        end if;
    end process;

    ------------------------------------------------------------------
    -- RX display: show last received byte on LEDs[15:8]
    ------------------------------------------------------------------
    process(CLK100MHZ)
    begin
        if rising_edge(CLK100MHZ) then
            if rx_done = '1' then
                LED(15 downto 8) <= rx_data;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Status LEDs
    ------------------------------------------------------------------
    LED(0) <= tx_busy;
    LED(1) <= rx_busy;

end Behavioral;


