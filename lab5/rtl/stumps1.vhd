--------------------------------------------------
-- SELF-TEST PER SCAN WITH ONE SCAN CHAIN (a one-chain STUMPS)
--   TPG  : 32-bit LFSR, optional phase shifter (tpg.vhd). Output 0 feeds the
--          scan input, outputs 1..NTPG-1 the functional inputs of the circuit.
--   FSM  : tps_ctrl.vhd: N_PATTERNS x (CHAIN_LEN shift + CAPTURE capture cycles),
--          then CHAIN_LEN unload cycles.
--   ODE  : 32-bit MISR. pos_i(0) must be the scan-out.
--          MISR_MODE = 1 (default, as in STUMPS): in the shift cycles only the
--            scan-out is compacted, after a capture all the outputs.
--          MISR_MODE = 0: all the outputs at every cycle. When two outputs are
--            consecutive cells of the scan chain and enter the MISR in adjacent
--            positions, an error moves along the chain exactly as it moves along
--            the MISR, and the two copies cancel (systematic aliasing).
--   At the end the signature is compared with GOLDEN_SIGNATURE: go_nogo_o = 1
--   (GO) if they are equal, sampled once and held while test_over_o = 1.
-- The circuit under test is outside this block: only its ports are connected.
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stumps1 is
    generic(
        CHAIN_LEN        : positive := 9;
        N_PATTERNS       : positive := 50;
        CAPTURE          : positive := 1;
        NTPG             : positive := 3;      -- scan input + functional inputs
        NPOS             : positive := 6;      -- outputs compacted (scan-out included)
        LFSR_SEED        : integer  := 1234;
        MISR_SEED        : integer  := 1234;
        PHASE_SHIFTER    : integer  := 0;      -- 0: adjacent LFSR bits; 1: phase shifter
        MISR_MODE        : integer  := 1;      -- 1: scan-out when shifting, all outputs after a capture; 0: all, always
        GOLDEN_SIGNATURE : std_logic_vector(31 downto 0) := x"00000000"
    );
    port(
        clk_i       : in  std_logic;
        rst_ni      : in  std_logic;
        start_i     : in  std_logic;
        tpg_o       : out std_logic_vector(NTPG-1 downto 0);   -- 0: scan-in; others: inputs
        scan_en_o   : out std_logic;
        pos_i       : in  std_logic_vector(NPOS-1 downto 0);   -- circuit outputs
        signature_o : out std_logic_vector(31 downto 0);
        testing_o   : out std_logic;
        test_over_o : out std_logic;
        go_nogo_o   : out std_logic                            -- 1 = GO, valid when test_over_o = 1
    );
end entity;

architecture RTL of stumps1 is

    signal testing, done, sampled, capture_cycle : std_logic;
    signal pos_scan_out, pos_compacted : std_logic_vector(NPOS-1 downto 0);
    signal misr_data : std_logic_vector(31 downto 0);
    signal signature : std_logic_vector(31 downto 0);

begin

    assert NPOS <= 32 report "stumps1: at most 32 outputs" severity failure;

    ctrl_i : entity work.tps_ctrl
        generic map (CHAIN_LEN => CHAIN_LEN, N_PATTERNS => N_PATTERNS, CAPTURE => CAPTURE)
        port map (clk_i => clk_i, rst_ni => rst_ni, start_i => start_i,
                  scan_en_o => scan_en_o, capture_o => capture_cycle, testing_o => testing, done_o => done);

    tpg_i : entity work.tpg
        generic map (NPIS => NTPG, LFSR_NBITS => 32, LFSR_SEED => LFSR_SEED, PHASE_SHIFTER => PHASE_SHIFTER)
        port map (clk_i => clk_i, rst_ni => rst_ni, en_i => testing, test_pis_o => tpg_o);

    -- The MISR samples at the end of each cycle the outputs produced by that cycle:
    -- capture_cycle = 1 means that the cycle that is ending was a capture cycle.
    pos_scan_out(0) <= pos_i(0);
    zeros: if NPOS > 1 generate
        pos_scan_out(NPOS-1 downto 1) <= (others => '0');
    end generate;
    pos_compacted <= pos_i when MISR_MODE = 0 or capture_cycle = '1' else pos_scan_out;
    misr_data <= std_logic_vector(resize(unsigned(pos_compacted), 32));

    misr_i : entity work.misr
        generic map (NBITS => 32, SEED => MISR_SEED)
        port map (clk_i => clk_i, en_i => testing, rst_ni => rst_ni,
                  data_i => misr_data, signature_o => signature);

    -- go/nogo: compare once, when the FSM reaches DONE, and hold the result
    process(clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            go_nogo_o <= '0';
            sampled   <= '0';
        elsif rising_edge(clk_i) then
            if done = '1' and sampled = '0' then
                if signature = GOLDEN_SIGNATURE then go_nogo_o <= '1'; else go_nogo_o <= '0'; end if;
                sampled <= '1';
            end if;
        end if;
    end process;

    signature_o <= signature;
    testing_o   <= testing;
    test_over_o <= sampled;

end RTL;
