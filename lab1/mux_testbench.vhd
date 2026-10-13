
library std;
use std.env.all;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

entity tb_mux is
	generic (
		-- test patterns, one per line, as "A B S" bits (e.g. "101");
		-- empty lines and lines starting with '#' are ignored.
		-- The path is relative to the run/ directory.
		PATTERN_FILE : string := "../mux_patterns.txt" );
end tb_mux;


architecture tb of tb_mux is

    component mux
        port (A : in std_logic;
              B : in std_logic;
              S : in std_logic;
              F : out std_logic);
    end component;

	constant clock_t1      : time := 50 ns;
	constant clock_t2      : time := 30 ns;
	constant clock_t3      : time := 20 ns;
	constant apply_offset  : time := 0 ns;
	constant apply_period  : time := 100 ns;
	constant strobe_offset : time := 40 ns;
	constant strobe_period : time := 100 ns;


	signal tester_clock : std_logic := '0';

    signal A : std_logic;
    signal B : std_logic;
    signal S : std_logic;
    signal F : std_logic;

begin

    u_mux : mux
    port map (A => A,
              B => B,
              S => S,
              F => F);

-- ***** CLOCK ***********************************

	clock_generation : process
	begin
		loop
			wait for clock_t1; tester_clock <= '1';
			wait for clock_t2; tester_clock <= '0';
			wait for clock_t3;
		end loop;
	end process;

-- ***** STIMULI (read from PATTERN_FILE) ********

    stimuli : process
		file     pfile   : text open READ_MODE is PATTERN_FILE;
		variable pline   : line;
		variable pattern : std_logic_vector(2 downto 0);   -- A & B & S
		variable ok      : boolean;
    begin

		wait for apply_offset;

		while not endfile(pfile) loop
			readline(pfile, pline);
			-- skip empty lines and comments
			if pline'length > 0 then
				if pline(pline'low) /= '#' then
					read(pline, pattern, ok);
					assert ok
						report "Malformed line in " & PATTERN_FILE & ": " & pline.all
						severity failure;
					A <= pattern(2);
					B <= pattern(1);
					S <= pattern(0);
					wait for apply_period;
				end if;
			end if;
		end loop;

		-- Stop the simulation after the last pattern
		finish(0);
    end process;

-- ****** MONITOR ************************************

	monitor : process
		variable counter  : integer := 0;
		variable pis      : std_logic_vector(2 downto 0);
		variable pos      : std_logic_vector(0 downto 0);
		file     outfile  : text open WRITE_MODE is "monitor.txt";
		variable outline  : line;

		function vec2str( input : std_logic_vector ) return string is
			variable rline : line;
		begin
			write( rline, input );
			return rline.all;
		end vec2str;

	begin
		wait for strobe_offset;

		loop
			pis := A & B & S;
			pos := (0 => F);
			write(outline, "pattern:" & integer'image(counter) & " PIs:" &  vec2str(pis) & " POs:" &  vec2str(pos));
			tee(outfile, outline);
			counter := counter + 1;
			wait for strobe_period;
		end loop;

	end process;

-- ****************************************************

end tb;



configuration cfg_tb_mux of tb_mux is
    for tb
    end for;
end cfg_tb_mux;
