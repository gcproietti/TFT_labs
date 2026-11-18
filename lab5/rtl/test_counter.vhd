--------------------------------------------------
-- TEST COUNTER
-- Counts the clock cycles of a BIST session.
--   test_started_o  = 1 when count >= START (the ODE can start compacting)
--   test_finished_o = 1 when count >= STOP  (end of the session)
-- 2026: comparisons on unsigned of NBITS bits (the 2025 version compared
-- std_logic_vectors and converted START/STOP on 24 bits, whatever NBITS);
-- reset handled like in the other blocks (asynchronous, active low), so the
-- count is never 'U' and no arithmetic warning is printed.
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_counter is
    generic(
        NBITS : integer := 24;
        START : integer := 4;
        STOP  : integer := 1000
    );
    port(
        clk_i, en_i, rst_ni             : in std_logic;
        test_started_o, test_finished_o : out std_logic
    );
end entity;

architecture RTL of test_counter is

    signal count : unsigned(NBITS-1 downto 0);

begin

    up_counter: process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            count <= (others => '0');
        elsif rising_edge(clk_i) then
            if en_i = '1' then
                count <= count + 1;
            end if;
        end if;
    end process;

    test_started_o  <= '1' when count >= to_unsigned(START, NBITS) else '0';
    test_finished_o <= '1' when count >= to_unsigned(STOP, NBITS)  else '0';

end RTL;
