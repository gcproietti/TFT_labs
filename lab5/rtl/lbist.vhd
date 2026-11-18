--------------------------------
-- Logic BIST block for B10 
--------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lbist is
    generic(
        NPIS : integer := 11;
        NPOS : integer := 6;

        COUNTER_NBITS    : integer := 24;
        COUNTER_START    : integer := 4;
        COUNTER_STOP     : integer := 1000;
        GOLDEN_SIGNATURE : std_logic_vector(31 downto 0) := x"0000_0000";

        LFSR_NBITS       : integer := 32;
        LFSR_SEED        : integer := 1234;

        MISR_NBITS       : integer := 32;
        MISR_SEED        : integer := 1234;
        PHASE_SHIFTER    : integer := 0     -- 0: TPG outputs = adjacent LFSR bits; 1: phase shifter

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
end entity;


architecture RTL of lbist is 

    -- BIST CONTROLLER
    component lbist_controller
        generic(
            COUNTER_NBITS    : integer := COUNTER_NBITS;
            COUNTER_START    : integer := COUNTER_START;
            COUNTER_STOP     : integer := COUNTER_STOP;
            MISR_NBITS       : integer := MISR_NBITS;
            GOLDEN_SIGNATURE : std_logic_vector(31 downto 0) := GOLDEN_SIGNATURE
        );
        port(
            clk_i            : in  std_logic;
            rst_ni           : in  std_logic;
                                  
            -- INPUTS                  
            normal_test_i    : in std_logic;                      -- 0 for normal mode, 1 for test mode
            signature_i      : in std_logic_vector(MISR_NBITS-1 downto 0);  -- from output data evaluator
            
            -- OUTPUTS
            test_mux_sel_o   : out std_logic;        -- primary input mux selector
            ode_en_o         : out std_logic;        -- output evaluator enable
            tpg_en_o         : out std_logic;        -- Test Pattern Generator enable
            
            rst_tpg_no       : out std_logic;
            rst_ode_no       : out std_logic; 
            
            go_nogo_o        : out std_logic;
            test_over_o      : out std_logic;
            testing_o        : out std_logic
        ); 
    end component;

    -- MULTIPLEXER
    component mux2to1_n
        generic(
            N     : integer := NPIS
        );
        port(
            sel_i      : in std_logic;
            d0_i, d1_i : in std_logic_vector(N-1 downto 0);
            data_o     : out std_logic_vector(N-1 downto 0)
        );
    end component;

    -- TEST PATTERN GENERATOR (TPG)
    component tpg
        generic(
            NPIS       : integer := NPIS;
            LFSR_NBITS : integer := LFSR_NBITS;
            LFSR_SEED  : integer := LFSR_SEED;
            PHASE_SHIFTER : integer := PHASE_SHIFTER
        );
        port(
            clk_i, rst_ni, en_i : in std_logic;
            test_pis_o          : out std_logic_vector(NPIS-1 downto 0)
        );
    end component;

    -- OUTPUT DATA EVALUATOR (ODE)
    component ode
        generic(
            NPOS       : integer := NPOS;
            MISR_NBITS : integer := MISR_NBITS;
            MISR_SEED  : integer := MISR_SEED
        );
        port(
            clk_i, rst_ni, en_i : in std_logic;
            data_i              : in std_logic_vector(NPOS-1 downto 0);
            signature_o         : out std_logic_vector(MISR_NBITS-1 downto 0)
        );
    end component;

    -- CONNECTION SIGNALS
    
    -- Data
    signal test_pis         : std_logic_vector(NPIS-1 downto 0);
    signal signature        : std_logic_vector(MISR_NBITS-1 downto 0);
       
    -- Test Pattern selection & generation
    signal test_mux_sel     : std_logic;
    signal tpg_en           : std_logic;
    signal rst_tpg_n        : std_logic;
    
    -- Output evaluation
    signal ode_en           : std_logic;
    signal rst_ode_n        : std_logic;

begin

    -- BIST CONTROLLER
    controller_i: lbist_controller generic map(
        COUNTER_NBITS    => COUNTER_NBITS,
        COUNTER_START    => COUNTER_START,
        COUNTER_STOP     => COUNTER_STOP,
        MISR_NBITS       => MISR_NBITS,
        GOLDEN_SIGNATURE => GOLDEN_SIGNATURE
    )port map(
        clk_i            => clk_i,
        rst_ni           => rst_ni,
        normal_test_i    => normal_test_i,
        signature_i      => signature,
        
        test_mux_sel_o   => test_mux_sel,
        ode_en_o         => ode_en,
        tpg_en_o         => tpg_en,

        rst_tpg_no       => rst_tpg_n,
        rst_ode_no       => rst_ode_n,

        go_nogo_o        => go_nogo_o,
        test_over_o      => test_over_o,
        testing_o        => testing_o   ); 

    -- MULTIPLEXER
    mux_i: mux2to1_n generic map( N => NPIS ) port map(
        sel_i    => test_mux_sel,
        d0_i     => pis_i,
        d1_i     => test_pis,
        data_o   => pis_o     );

    -- TEST PATTERN GENERATOR
    tpg_i: tpg  generic map( 
        NPIS => NPIS, 
        LFSR_NBITS => LFSR_NBITS, 
        LFSR_SEED => LFSR_SEED,
        PHASE_SHIFTER => PHASE_SHIFTER
    ) port map(
        clk_i      => clk_i, 
        rst_ni     => rst_tpg_n,
        en_i       => tpg_en,
        test_pis_o => test_pis );

    -- OUTPUT DATA EVALUATOR
    ode_i: ode generic map( 
        NPOS => NPOS,
        MISR_NBITS => MISR_NBITS,
        MISR_SEED => MISR_SEED
    ) port map(
        clk_i       => clk_i,
        rst_ni      => rst_ode_n,
        en_i        => ode_en,
        data_i      => pos_i,
        signature_o => signature );
        
end RTL;
