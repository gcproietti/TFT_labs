library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lfsr is
    generic(
        NBITS               : integer := 24;
        SEED                : integer := 1);
    port(    
        clk_i, rst_ni, en_i : in std_logic;
        data_o              : out std_logic_vector(NBITS-1 downto 0)
    );    
end entity;

architecture RTL of lfsr is

    signal r_reg, r_next    : std_logic_vector(1 to NBITS);
    signal feedback_value   : std_logic;

begin

    reg: process(clk_i, rst_ni)
    begin
        if( rst_ni='0') then
            r_reg <= std_logic_vector(to_unsigned(SEED,NBITS));
        elsif(clk_i'event and clk_i='1') then 
            if en_i='1' then
                r_reg <= r_next;
            end if;
        end if;
    end process;

    -- Taps from Xilinx XAPP052 (XNOR form: the lock-up state is all ones, not all zeros).
    -- All the polynomials below are primitive: the LFSR has maximum length 2^NBITS - 1.
    assert NBITS = 8 or NBITS = 16 or NBITS = 24 or NBITS = 32 or NBITS = 64
        report "lfsr: NBITS must be 8, 16, 24, 32 or 64 (add the taps of other sizes here)" severity failure;

    feedback64: if NBITS = 64 generate
        feedback_value <= r_reg(64) xnor r_reg(63) xnor r_reg(61) xnor r_reg(60);
    end generate feedback64;

    feedback32: if NBITS = 32 generate
        feedback_value <= r_reg(32) xnor r_reg(22) xnor r_reg(2) xnor r_reg(1);
    end generate feedback32;

    feedback24: if NBITS = 24 generate
        feedback_value <= r_reg(24) xnor r_reg(23) xnor r_reg(22) xnor r_reg(17);
    end generate feedback24;

    feedback16: if NBITS = 16 generate
        feedback_value <= r_reg(16) xnor r_reg(15) xnor r_reg(13) xnor r_reg(4);
    end generate feedback16;

    feedback8: if NBITS = 8 generate
        feedback_value <= r_reg(8) xnor r_reg(6) xnor r_reg(5) xnor r_reg(4);
    end generate feedback8;

    r_next <= feedback_value & r_reg(1 to NBITS-1);

    data_o <= r_reg;

end RTL;
