--normalize the result with FSM
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity float_toint_control is 
port (
	clk,rst,go,zero_exponent,too_large,too_small:in std_logic;
	ld_shifter,shift,ld_exponent,exponent_src:out std_logic;
	done:out std_logic

);
end float_toint_control;
architecture arch of float_toint_control is
signal state_counter:std_logic_vector(1 downto 0):=(others=>'0');
signal control:std_logic_vector(3 downto 0);
begin

process(clk,rst,go)
begin
if(rst='1') then state_counter<=(others=>'0');done<='0';
elsif(clk'event and clk='0') then if(go='1') then 
				if(state_counter="11")then done<='1';
			  elsif(state_counter="10" and zero_exponent='1') then state_counter<="11";
			  elsif(state_counter="01" and too_large='1') then state_counter<="11";
			  elsif(state_counter="01" and too_small='1') then state_counter<="11";
			  elsif(state_counter="10") then state_counter<=state_counter;
			  else state_counter<=std_logic_vector(unsigned(state_counter)+1);
			end if;end if;
end if;
end process;
--ld_shifter,shift,ld_exponent,exponent_src
control<="1011" when state_counter="01" else --load data
		 "0110" when state_counter="10" else --shift untill exponent is 0
		 "0000";

ld_shifter<=control(3);
shift<=control(2);
ld_exponent<=control(1);
exponent_src<=control(0);

end arch;