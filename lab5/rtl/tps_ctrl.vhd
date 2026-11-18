--------------------------------------------------
-- TEST-PER-SCAN CONTROLLER (one scan chain)
-- For every pattern: CHAIN_LEN shift cycles (scan_en_o = 1), then CAPTURE
-- capture cycles (scan_en_o = 0). The shift of a pattern also unloads the
-- response captured for the previous one. After the last capture, one more
-- shift (unload only), then done_o = 1.
--   test time = N_PATTERNS * (CHAIN_LEN + CAPTURE) + CHAIN_LEN  clock cycles
-- CAPTURE = 1 for stuck-at faults, 2 for transition faults (launch and capture
-- in functional mode).
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tps_ctrl is
    generic(
        CHAIN_LEN  : positive := 9;
        N_PATTERNS : positive := 100;
        CAPTURE    : positive := 1
    );
    port(
        clk_i      : in  std_logic;
        rst_ni     : in  std_logic;     -- active low
        start_i    : in  std_logic;     -- 1: start the test (sampled in IDLE)
        scan_en_o  : out std_logic;     -- to the scan enable of the circuit
        capture_o  : out std_logic;     -- 1 in the capture cycles
        testing_o  : out std_logic;     -- 1 from the first shift to the end of the unload
        done_o     : out std_logic
    );
end entity;

architecture RTL of tps_ctrl is

    type state_t is (IDLE, SHIFT, CAPT, UNLOAD, DONE);
    signal state   : state_t;
    signal cycle   : natural range 0 to CHAIN_LEN;      -- cycle inside a shift or capture
    signal pattern : natural range 0 to N_PATTERNS;     -- patterns already captured

begin

    process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            state   <= IDLE;
            cycle   <= 0;
            pattern <= 0;
        elsif rising_edge(clk_i) then
            case state is
                when IDLE =>
                    if start_i = '1' then
                        state <= SHIFT; cycle <= 0; pattern <= 0;
                    end if;
                when SHIFT =>
                    if cycle = CHAIN_LEN - 1 then
                        state <= CAPT; cycle <= 0;
                    else
                        cycle <= cycle + 1;
                    end if;
                when CAPT =>
                    if cycle = CAPTURE - 1 then
                        cycle <= 0;
                        pattern <= pattern + 1;
                        if pattern = N_PATTERNS - 1 then
                            state <= UNLOAD;
                        else
                            state <= SHIFT;
                        end if;
                    else
                        cycle <= cycle + 1;
                    end if;
                when UNLOAD =>
                    if cycle = CHAIN_LEN - 1 then
                        state <= DONE;
                    else
                        cycle <= cycle + 1;
                    end if;
                when DONE =>
                    null;
            end case;
        end if;
    end process;

    scan_en_o <= '1' when state = SHIFT or state = UNLOAD else '0';
    capture_o <= '1' when state = CAPT else '0';
    testing_o <= '1' when state = SHIFT or state = CAPT or state = UNLOAD else '0';
    done_o    <= '1' when state = DONE else '0';

end RTL;
