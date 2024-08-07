--normalizes the result using FSM
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int_tofloat_control is 
port(
	clk,rst,go,ZERO,mantissa_msb:std_logic;
	ld_shifter,shift,ld_exponent:out std_logic;
	done:out std_logic
);
end int_tofloat_control;
architecture arch of int_tofloat_control is 
signal state_counter:std_logic_vector(1 downto 0):=(others=>'0');
signal control:std_logic_vector(2 downto 0);
begin 
process(clk,rst,go,mantissa_msb,zero)
begin
if(rst='1') then done<='0';state_counter<=(others=>'0');
elsif(clk'event and clk='0') then  if(go='1') then
		if(state_counter="11") then done<='1';
		elsif(zero='1' and state_counter="01") then state_counter<="11";
		elsif(state_counter="10" and mantissa_msb='1') then state_counter<="11";
		elsif(state_counter="10" and mantissa_msb='0') then state_counter<="10";
		else state_counter<=std_logic_vector(unsigned(state_counter)+1);
		end if;end if;
end if;
		end process;
--ld_shifter,shift,ld_exponent
control<="000" when state_counter="00" else 
		 "100" when state_counter="01" else --load mantissa
		 "011" when state_counter="10" and mantissa_msb='0' else --normalize untill the MSB is 1
		 "000";
ld_shifter<=control(2);
shift<=control(1);
ld_exponent<=control(0);
end arch;