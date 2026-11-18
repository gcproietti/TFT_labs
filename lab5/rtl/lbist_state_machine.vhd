--------------------------------------------------
-- LBIST STATE MACHINE
--   RESET -> IDLE -> START_TEST -> TEST -> EVALUATION -> FLUSHP_1..3 -> DONE
--   IDLE       : normal mode, waits for normal_test_i = 1
--   START_TEST : TPG running, ODE off (the first COUNTER_START responses are not compacted)
--   TEST       : TPG and ODE running, until the test counter reaches COUNTER_STOP
--   EVALUATION : signature compared with the golden one, result stored in go_nogo_o
--   DONE       : test over; go_nogo_o and the signature stay valid until
--                normal_test_i returns to 0 (then back to IDLE)
-- 2026 changes w.r.t. the 2025 version:
--   * ieee.numeric_std only (no std_logic_arith / std_logic_unsigned);
--   * go_nogo_o is sampled only in EVALUATION and held (in 2025 it followed the
--     comparison at every clock, so it was valid only for a few cycles);
--   * new DONE state: in 2025 FLUSHP_3 went back to RESET, which cleared the
--     MISR, and the session restarted by itself while normal_test_i was 1.
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity lbist_state_machine is
    port(
        clk_i               : in  std_logic;    -- Clock
        rst_ni              : in  std_logic;    -- Reset: active low

        -- INPUTS
        normal_test_i       : in std_logic;     -- 0 for normal mode, 1 for test mode
        signature_check_i   : in std_logic;     -- 1 when the signature equals the golden one
        test_finished_i     : in std_logic;
        test_started_i      : in std_logic;

        -- OUTPUTS
        test_mux_sel_o      : out std_logic;    -- primary input mux selector
        ode_en_o            : out std_logic;    -- output evaluator enable
        tpg_en_o            : out std_logic;    -- test pattern generator enable
        count_enable_o      : out std_logic;    -- enables the test counter
        rst_test_counter_no : out std_logic;
        rst_tpg_no          : out std_logic;
        rst_ode_no          : out std_logic;

        go_nogo_o           : out std_logic;    -- 1 = go (pass), 0 = nogo; valid when test_over_o = 1
        test_over_o         : out std_logic;
        testing_o           : out std_logic
    );
end entity;

architecture RTL of lbist_state_machine is

    type state_t is (
        RESET, IDLE, START_TEST, TEST, EVALUATION, FLUSHP_1, FLUSHP_2, FLUSHP_3, DONE
    );
    signal current_state : state_t := RESET;
    signal next_state    : state_t := IDLE;

begin

    p_state : process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            current_state <= RESET;
            go_nogo_o     <= '0';
        elsif rising_edge(clk_i) then
            current_state <= next_state;
            if current_state = START_TEST then
                go_nogo_o <= '0';                   -- clear the result of a previous session
            elsif current_state = EVALUATION then
                go_nogo_o <= signature_check_i;     -- sample the comparison once, and hold it
            end if;
        end if;
    end process p_state;

    p_next_state : process(current_state, normal_test_i, test_started_i, test_finished_i)
    begin
        case current_state is
            when RESET =>
                next_state <= IDLE;
            when IDLE =>
                if normal_test_i = '1' then next_state <= START_TEST; else next_state <= IDLE; end if;
            when START_TEST =>
                if test_started_i = '1' then next_state <= TEST; else next_state <= START_TEST; end if;
            when TEST =>
                if test_finished_i = '1' then next_state <= EVALUATION; else next_state <= TEST; end if;
            when EVALUATION =>
                next_state <= FLUSHP_1;
            when FLUSHP_1 =>
                next_state <= FLUSHP_2;
            when FLUSHP_2 =>
                next_state <= FLUSHP_3;
            when FLUSHP_3 =>
                next_state <= DONE;
            when DONE =>
                if normal_test_i = '0' then next_state <= IDLE; else next_state <= DONE; end if;
        end case;
    end process p_next_state;

    p_outputs : process(current_state)
    begin
        -- defaults: normal mode, BIST blocks idle but not in reset
        test_mux_sel_o      <= '0';
        ode_en_o            <= '0';
        tpg_en_o            <= '0';
        count_enable_o      <= '0';
        rst_test_counter_no <= '1';
        rst_tpg_no          <= '1';
        rst_ode_no          <= '1';
        testing_o           <= '0';
        test_over_o         <= '0';

        case current_state is
            when RESET =>
                rst_test_counter_no <= '0';
                rst_tpg_no          <= '0';
                rst_ode_no          <= '0';
            when IDLE =>
                null;
            when START_TEST =>
                test_mux_sel_o <= '1';
                tpg_en_o       <= '1';
                count_enable_o <= '1';
                testing_o      <= '1';
            when TEST =>
                test_mux_sel_o <= '1';
                ode_en_o       <= '1';
                tpg_en_o       <= '1';
                count_enable_o <= '1';
                testing_o      <= '1';
            when EVALUATION | FLUSHP_1 | FLUSHP_2 | FLUSHP_3 =>
                testing_o   <= '1';
                test_over_o <= '1';
            when DONE =>
                test_over_o <= '1';
        end case;
    end process p_outputs;

end RTL;
