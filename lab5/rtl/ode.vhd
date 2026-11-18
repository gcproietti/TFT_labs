--------------------------------------------------
-- OUTPUT DATA EVALUATOR
--------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ode is
    generic(
        NPOS       : integer := 6;
        MISR_NBITS : integer := 32;
        MISR_SEED  : integer := 1234
    );
    port(
        clk_i, rst_ni, en_i : in std_logic;
        data_i              : in std_logic_vector(NPOS-1 downto 0);
        signature_o         : out std_logic_vector(MISR_NBITS-1 downto 0)
    );
end entity;

architecture RTL of ode is

    component misr
        generic(
            NBITS   : integer := MISR_NBITS;
            SEED    : integer := MISR_SEED
        );
        port(
            clk_i, en_i, rst_ni  : in std_logic;
            data_i               : in std_logic_vector(NBITS-1 downto 0);
            signature_o          : out std_logic_vector(NBITS-1 downto 0) );
    end component;

    signal misr_data : std_logic_vector(MISR_NBITS-1 downto 0);
    
begin

    misr_data <= std_logic_vector(resize(unsigned(data_i), MISR_NBITS));

    misr_i: misr generic map( NBITS => MISR_NBITS, SEED => MISR_SEED ) port map
        (   clk_i        => clk_i,
            en_i         => en_i,
            rst_ni       => rst_ni,
            data_i       => misr_data,
            signature_o  => signature_o);
    
end RTL;        
