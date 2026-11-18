library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity misr is
    generic (
        NBITS : integer := 64;
        SEED  : integer := 1
    );
    port (
        clk_i, en_i, rst_ni : in std_logic;
        data_i              : in std_logic_vector(NBITS-1 downto 0);
        signature_o         : out std_logic_vector(NBITS-1 downto 0)
    );
end entity;

architecture RTL of misr is
    signal xnors, r_reg: std_logic_vector(NBITS downto 0);

begin

    -- Taps for 32 and 64 bits only (any other size would silently get the 32-bit taps).
    -- r_reg(0) is not a stage of the MISR: the stages are r_reg(NBITS downto 1).
    assert NBITS = 32 or NBITS = 64
        report "misr: NBITS must be 32 or 64" severity failure;

    process (clk_i, rst_ni)
    begin
        if rst_ni = '0' then
            r_reg <= std_logic_vector(to_unsigned(SEED,NBITS+1));
        elsif(clk_i'event and clk_i = '1') then 
            if en_i = '1' then
                r_reg(NBITS downto 1) <= xnors(NBITS-1 downto 0);
            end if;
        end if;
    end process;

    process (data_i, r_reg)
    begin
        for i in 0 to NBITS-1 loop 
            if(i = 0) then
                xnors(i)<= r_reg(NBITS) xnor data_i(i);
            else
                xnors(i) <= r_reg(i) xnor data_i(i);
                case NBITS is
                    when 64 =>
                        if(i = 60 or i = 61 or i = 63) then
                            xnors(i) <= r_reg(NBITS) xnor data_i(i) xnor r_reg(i);
                        end if;
                    when others => -- 32 bit
                        if(i = 22 or i = 2 or i = 1) then
                            xnors(i) <= r_reg(NBITS) xnor data_i(i) xnor r_reg(i);
                        end if;
                end case;
            end if;
        end loop;
    end process;
    
    signature_o <= r_reg(NBITS downto 1);

end architecture RTL;