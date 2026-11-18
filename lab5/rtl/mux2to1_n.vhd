

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mux2to1_n is
    generic(
        N : integer := 1 
    );
    port(
        sel_i	   : in std_logic;
        d0_i, d1_i : in std_logic_vector(N-1 downto 0);
        data_o     : out std_logic_vector(N-1 downto 0)
    );
end entity;

architecture RTL of mux2to1_n is

begin

    mux: process( d0_i, d1_i, sel_i )
    begin
        if sel_i = '0' then
            data_o <= d0_i;
        else	
            data_o <= d1_i;
        end if;
    end process;
    
end RTL;
