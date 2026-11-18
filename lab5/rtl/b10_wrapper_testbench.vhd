-- Testbench of b10 with its functional self-test (b10_wrapper = b10 + lbist).
-- It applies a reset, keeps the circuit in normal mode for a while, then sets
-- normal_test to 1 (test mode) and waits for the end of the self-test session.
-- At the end it prints the length of the session, the golden signature and the
-- GO/NOGO result (the signature itself is printed by func_bist.tcl).
-- Every generic can be changed from the vsim command line with -G<name>=<value>:
-- func_bist.sh does it for you.

library ieee;
use ieee.std_logic_1164.all;

entity tb_b10_wrapper is
    generic (
        COUNTER_STOP     : integer := 1000;            -- end of the session (counter value)
        LFSR_SEED        : integer := 1234;
        MISR_SEED        : integer := 1234;
        PHASE_SHIFTER    : integer := 0;               -- 0: adjacent LFSR bits; 1: phase shifter
        GOLDEN_SIGNATURE : std_logic_vector(31 downto 0) := x"A88DEC5B"   -- for the default generics
    );
end tb_b10_wrapper;

architecture tb of tb_b10_wrapper is
    constant clock_t1     : time := 50 ns;
    constant clock_t2     : time := 30 ns;
    constant clock_t3     : time := 20 ns;
    constant clock_period : time := 100 ns;

    signal clock, reset, normal_test : std_logic := '0';
    signal r_button, g_button, key, start, test, rts, rtr : std_logic := '0';
    signal v_in  : std_logic_vector(3 downto 0) := "0000";
    signal v_out : std_logic_vector(3 downto 0);
    signal cts, ctr : std_logic;
    signal go_nogo, test_over, testing : std_logic;
begin

    u_b10_wrapper : entity work.b10_wrapper
        generic map (
            COUNTER_NBITS => 24, COUNTER_START => 4, COUNTER_STOP => COUNTER_STOP,
            GOLDEN_SIGNATURE => GOLDEN_SIGNATURE,
            LFSR_NBITS => 32, LFSR_SEED => LFSR_SEED,
            MISR_NBITS => 32, MISR_SEED => MISR_SEED,
            PHASE_SHIFTER => PHASE_SHIFTER)
        port map (
            r_button => r_button, g_button => g_button, key => key, start => start,
            reset => reset, test => test, cts => cts, ctr => ctr, rts => rts, rtr => rtr,
            clock => clock, v_in => v_in, v_out => v_out,
            normal_test_i => normal_test, go_nogo_o => go_nogo,
            test_over_o => test_over, testing_o => testing);

    -- clock: rises 50 ns into each 100 ns cycle; functional inputs held at 0
    process begin
        loop
            wait for clock_t1; clock <= '1';
            wait for clock_t2; clock <= '0';
            wait for clock_t3;
        end loop;
    end process;

    reset       <= '0', '1' after 25 ns, '0' after 100 ns;
    normal_test <= '0', '1' after 200 ns;              -- test mode from here on

    -- report: test_over rises in EVALUATION, go_nogo is sampled at the end of that
    -- cycle; the session is over when testing falls (state DONE)
    process
        variable t_start, t_end : time;
    begin
        wait until testing = '1';  t_start := now;
        wait until test_over = '1'; t_end := now;
        wait until testing = '0';
        report "BIST: session of " & integer'image((t_end - t_start) / clock_period)
             & " clock cycles (COUNTER_STOP = " & integer'image(COUNTER_STOP) & ")";
        report "BIST: golden    = " & to_hstring(GOLDEN_SIGNATURE);
        if go_nogo = '1' then report "BIST: result = GO"; else report "BIST: result = NOGO"; end if;
        std.env.stop;
    end process;

end tb;
