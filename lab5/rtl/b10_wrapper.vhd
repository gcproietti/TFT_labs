
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity b10_wrapper is
    generic(
        COUNTER_NBITS    : integer := 24;
        COUNTER_START    : integer := 4;
        COUNTER_STOP     : integer := 1000;
        GOLDEN_SIGNATURE : std_logic_vector(31 downto 0) := x"0000_0000";

        LFSR_NBITS       : integer := 32;
        LFSR_SEED        : integer := 1234;

        MISR_NBITS       : integer := 32;
        MISR_SEED        : integer := 1234;
        PHASE_SHIFTER    : integer := 0
    );

    port(
		r_button : in  std_logic ;
		g_button : in  std_logic ;
		key      : in  std_logic ;
		start    : in  std_logic ;
		reset    : in  std_logic ;
		test     : in  std_logic ;
		cts      : out std_logic ;
		ctr      : out std_logic ;
		rts      : in  std_logic ;
		rtr      : in  std_logic ;
		clock    : in  std_logic ;
		v_in     : in  std_logic_vector(3 downto 0) ;
		v_out    : out std_logic_vector(3 downto 0) ;

        normal_test_i : in std_logic;
        go_nogo_o     : out std_logic;
        test_over_o   : out std_logic;
        testing_o     : out std_logic);
end entity;

architecture RTL of b10_wrapper is 

    -- DUT (b10)
    component b10
        port (
            r_button : in  std_logic ;
            g_button : in  std_logic ;
            key      : in  std_logic ;
            start    : in  std_logic ;
            reset    : in  std_logic ;
            test     : in  std_logic ;
            cts      : out std_logic ;
            ctr      : out std_logic ;
            rts      : in  std_logic ;
            rtr      : in  std_logic ;
            clock    : in  std_logic ;
            v_in     : in  std_logic_vector(3 downto 0) ;
            v_out    : out std_logic_vector(3 downto 0)
            ) ;
    end component;

    -- LOGIC BIST
    component lbist
        generic(
            NPIS : integer := 11;
            NPOS : integer := 6;
    
            COUNTER_NBITS    : integer := COUNTER_NBITS;
            COUNTER_START    : integer := COUNTER_START;
            COUNTER_STOP     : integer := COUNTER_STOP;
            GOLDEN_SIGNATURE : std_logic_vector(31 downto 0) := GOLDEN_SIGNATURE;
    
            LFSR_NBITS       : integer := LFSR_NBITS;
            LFSR_SEED        : integer := LFSR_SEED;
    
            MISR_NBITS       : integer := MISR_NBITS;
            MISR_SEED        : integer := MISR_SEED;
            PHASE_SHIFTER    : integer := PHASE_SHIFTER
        );
        port(
            clk_i         : in std_logic;
            rst_ni        : in std_logic;
            normal_test_i : in std_logic;
            pis_i         : in std_logic_vector(NPIS-1 downto 0);
            pos_i         : in std_logic_vector(NPOS-1 downto 0);
            pis_o         : out std_logic_vector(NPIS-1 downto 0);
            go_nogo_o     : out std_logic;
            test_over_o   : out std_logic;
            testing_o     : out std_logic);
    end component;
    
    -- CONNECTION SIGNALS
    signal rst_n     : std_logic;
    signal lbist_pis : std_logic_vector(10 downto 0);
    signal pis       : std_logic_vector(10 downto 0);
    signal pos       : std_logic_vector(5 downto 0);
    signal b10_pis   : std_logic_vector(10 downto 0);

    -- Simulation only (synthesis ignores "after"): the inputs of b10 change 50 ns after
    -- the rising edge of the clock, i.e. at the beginning of the next tester cycle, as in
    -- the testbenches of Part A. Without this delay the TPG outputs would change in the
    -- same instant as the clock edge: in the eVCD written for TestMAX the input changes
    -- and the clock pulse could not be ordered (warning M197) and no fault is detected.
    constant TPG_DELAY : time := 50 ns;
    
begin

    rst_n <= not reset;
    b10_pis <= transport lbist_pis after TPG_DELAY;
    -- Same bit order as the port map of u_b10 below (bit 0 = r_button ... bits 10:7 = v_in):
    -- in normal mode every functional input must reach the b10 input with the same name.
    -- (2025 version: r_button & ... & v_in, which sent v_in(0) to r_button in normal mode.)
    pis <= v_in & rtr & rts & test & start & key & g_button & r_button;

    u_b10 : b10 port map(
        r_button => b10_pis(0),
        g_button => b10_pis(1),
        key      => b10_pis(2),
        start    => b10_pis(3),
        reset    => reset,
        test     => b10_pis(4),
        cts      => pos(0),
        ctr      => pos(1),
        rts      => b10_pis(5),
        rtr      => b10_pis(6),
        clock    => clock,
        v_in     => b10_pis(10 downto 7),
        v_out    => pos(5 downto 2)
    );

    lbist_i : lbist generic map (
        NPIS => 11,
        NPOS => 6,
        COUNTER_NBITS => COUNTER_NBITS,
        COUNTER_START => COUNTER_START,
        COUNTER_STOP => COUNTER_STOP,
        GOLDEN_SIGNATURE => GOLDEN_SIGNATURE,
        LFSR_NBITS => LFSR_NBITS,
        LFSR_SEED => LFSR_SEED,
        MISR_NBITS => MISR_NBITS,
        MISR_SEED => MISR_SEED,
        PHASE_SHIFTER => PHASE_SHIFTER
    )
    port map (
        clk_i         => clock,
        rst_ni        => rst_n,
        normal_test_i => normal_test_i,
        pis_i         => pis,
        pos_i         => pos,
        pis_o         => lbist_pis,
        go_nogo_o     => go_nogo_o,
        test_over_o   => test_over_o,
        testing_o     => testing_o
    );

    cts <= pos(0);
    ctr <= pos(1);
    v_out <= pos(5 downto 2);

end RTL;