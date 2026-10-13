library IEEE;

use IEEE.std_logic_1164.all;

-- 2-to-1 multiplexer:  F = A when S = '0', F = B when S = '1'
-- Sum of products with the consensus term A.B:
--     F = A.S' + B.S + A.B
-- The consensus term does not change the function: it keeps F stable
-- when S switches while A = B = 1 (no static-1 hazard).

entity mux is
	port (
		A, B, S: in  STD_LOGIC;
		F:       out STD_LOGIC );
end mux;

architecture structural of mux is
	signal sn: STD_LOGIC;   -- S'
	signal x:  STD_LOGIC;   -- A.S'
	signal y:  STD_LOGIC;   -- B.S
	signal z:  STD_LOGIC;   -- A.B   (consensus term)

	component Inv_Gate is
		port ( I1: in STD_LOGIC; O: out STD_LOGIC );
	end component;

	component And_Gate is
		port ( I1, I2: in STD_LOGIC; O: out STD_LOGIC );
	end component;

	component Or3_Gate is
		port ( I1, I2, I3: in STD_LOGIC; O: out STD_LOGIC );
	end component;

begin
	U1: Inv_Gate port map (I1 => S,                     O => sn);
	U2: And_Gate port map (I1 => A,  I2 => sn,          O => x);
	U3: And_Gate port map (I1 => B,  I2 => S,           O => y);
	U4: And_Gate port map (I1 => A,  I2 => B,           O => z);
	U5: Or3_Gate port map (I1 => x,  I2 => y,  I3 => z, O => F);
end structural;
