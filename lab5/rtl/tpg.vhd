--------------------------------------------------
-- TEST PATTERNS GENERATOR
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



entity tpg is
    generic(
        NPIS       : integer := 11;
        LFSR_NBITS : integer := 32;
        LFSR_SEED  : integer := 1234;
        PHASE_SHIFTER : integer := 0    -- 0: none; 1: every output = XOR of 3 LFSR bits
    );
    port(
        clk_i, rst_ni, en_i : in std_logic;
        test_pis_o          : out std_logic_vector(NPIS-1 downto 0)
    );
end entity;

architecture RTL of tpg is
    
    signal    tmp_dout    : std_logic_vector(LFSR_NBITS-1 downto 0);
    signal    ps_out      : std_logic_vector(NPIS-1 downto 0);     -- after the phase shifter

    -- taps of the phase shifter (PHASE_SHIFTER = 1): output i = XOR of the three LFSR bits PS_TAPS(i)
    type taps_t is array (0 to 2) of natural;
    type ps_taps_t is array (0 to 15) of taps_t;
    constant PS_TAPS : ps_taps_t := (
        (0, 7, 19), (3, 12, 29), (5, 14, 26), (1, 17, 30), (9, 20, 27), (2, 11, 23),
        (6, 15, 31), (4, 18, 25), (8, 13, 28), (10, 21, 24), (3, 16, 22),
        (11, 18, 27), (4, 13, 30), (2, 9, 20), (7, 16, 29), (1, 12, 25));

    component lfsr
        generic(
            NBITS               : integer := LFSR_NBITS;
            SEED                : integer := LFSR_SEED);
        port(    
            clk_i, rst_ni, en_i : in std_logic;
            data_o              : out std_logic_vector(NBITS-1 downto 0)
        );    
    end component;

    
begin    
    
    lfsr_i : lfsr generic map( NBITS => LFSR_NBITS, SEED => LFSR_SEED ) port map(    
        clk_i   => clk_i,
        rst_ni  => rst_ni,
        en_i    => en_i,
        data_o  => tmp_dout);

    assert NPIS <= LFSR_NBITS
        report "tpg: the LFSR must have at least NPIS bits" severity failure;

    -- PHASE_SHIFTER = 0: the NPIS least significant bits of the LFSR, i.e. adjacent stages of
    -- the same shift register: output i is output i+1 delayed by one clock cycle.
    no_ps: if PHASE_SHIFTER = 0 generate
        ps_out <= tmp_dout(NPIS-1 downto 0);
    end generate;

    -- PHASE_SHIFTER = 1: every output is the XOR of three LFSR bits (slides LBIST 55-56).
    -- The spacing of the three bits changes from output to output: with the same spacing
    -- for all outputs, output i would still be output i+1 delayed by one cycle.
    ps_xor: if PHASE_SHIFTER = 1 generate
        assert NPIS <= 16 and LFSR_NBITS = 32
            report "tpg: the phase shifter is written for at most 16 outputs and a 32-bit LFSR" severity failure;
        ps: for i in 0 to NPIS-1 generate
            ps_out(i) <= tmp_dout(PS_TAPS(i)(0)) xor tmp_dout(PS_TAPS(i)(1)) xor tmp_dout(PS_TAPS(i)(2));
        end generate;
    end generate;

    test_pis_o <= ps_out;

end RTL;
