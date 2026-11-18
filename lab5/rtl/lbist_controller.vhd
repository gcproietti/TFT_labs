library ieee;
use ieee.std_logic_1164.all;

entity lbist_controller is
    generic(
        COUNTER_NBITS    : integer := 24;
        COUNTER_START    : integer := 4;
        COUNTER_STOP     : integer := 1000;
        MISR_NBITS       : integer := 32;
        GOLDEN_SIGNATURE : std_logic_vector(31 downto 0) := x"0000_0000"
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
end entity;

architecture RTL of lbist_controller is 


    -- BIST CONTROLLER STATE MACHINE
    component lbist_state_machine
        port(
            clk_i                : in  std_logic;    -- Clock
            rst_ni               : in  std_logic;    -- Reset:Active-Low
            
            -- INPUTS
            normal_test_i        : in std_logic;    -- 0 for normal mode, 1 for test mode
            signature_check_i    : in std_logic;    -- receives result of comparison between signatures (true vs gold)
            test_finished_i      : in std_logic;
            test_started_i       : in std_logic;
            
            --OUTPUTS
            test_mux_sel_o       : out std_logic;    -- primary input mux selector
            ode_en_o             : out std_logic;    -- output evaluator enable
            tpg_en_o             : out std_logic;    -- Test Pattern Generator enable
            count_enable_o       : out std_logic;    -- enables the Test Counter
            rst_test_counter_no  : out std_logic;
            rst_tpg_no           : out std_logic;
            rst_ode_no           : out std_logic;
            
            test_over_o          : out std_logic;
            go_nogo_o            : out std_logic;
            testing_o            : out std_logic
        ); 
    end component;

    -- TEST COUNTER
    component test_counter is
        generic( 
            NBITS : integer := COUNTER_NBITS;
            START : integer := COUNTER_START;
            STOP  : integer := COUNTER_STOP
        );
        port
        (   clk_i, en_i, rst_ni                : in std_logic;
            test_started_o, test_finished_o    : out std_logic
        );
    end component;


    -- From STATE MACHINE to TEST COUNTER
    signal count_enable          : std_logic;    -- enables the Test Counter
    signal rst_test_counter_n    : std_logic;    -- resets the Test Counter

    -- from TEST COUNTER to STATE MACHINE
    signal test_started          : std_logic;
    signal test_finished         : std_logic;

    signal signature_check          : std_logic;
    

begin

    -- STATE MACHINE
    sm_i: lbist_state_machine port map(
        clk_i                => clk_i,
        rst_ni                => rst_ni,
        normal_test_i        => normal_test_i,
        
        
        signature_check_i    => signature_check,
        test_finished_i      => test_finished,
        test_started_i       => test_started,
        
        -- OUTPUTS
        test_mux_sel_o       => test_mux_sel_o,
        ode_en_o             => ode_en_o,
        tpg_en_o             => tpg_en_o,
        count_enable_o       => count_enable,
        rst_test_counter_no => rst_test_counter_n,
        rst_tpg_no          => rst_tpg_no,
        rst_ode_no          => rst_ode_no,

        test_over_o          => test_over_o,
        go_nogo_o            => go_nogo_o,
        testing_o            => testing_o    ); 

    -- TEST COUNTER
    test_counter_i: test_counter generic map( NBITS => COUNTER_NBITS, START => COUNTER_START, STOP => COUNTER_STOP ) port map (
        clk_i           => clk_i,
        rst_ni          => rst_test_counter_n,
        en_i            => count_enable,
        test_started_o  => test_started,
        test_finished_o => test_finished    );

    -- The golden signature is a 32-bit generic: the comparison makes sense only with a 32-bit MISR
    -- (with vectors of different lengths, "=" is simply false, and the BIST would always say nogo).
    assert MISR_NBITS = 32
        report "lbist_controller: GOLDEN_SIGNATURE has 32 bits, MISR_NBITS must be 32" severity failure;

    check_signature: signature_check <= '1' when signature_i = GOLDEN_SIGNATURE else '0';

end RTL;
