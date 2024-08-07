--FSM to normalize the mantissa and control the internal registers according to current  state
--multiplication output can have a carry so output could be 1x.1100101 so we increment the exponent 
--this is the special case that is dealt with in state "011" and no need to shift mantissa right or left
--because the normalization stops when MSB is 1 and we take all the 23 bits exept MSB 
--example  after multiplication =>  10.11111000 we get a one so we do not decrement nor shift and we move to state 011 to increment and then we are done
--division doesn't have this problem
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--normalization of the mantissa
entity fp_mul_div_control is
port(
	clk,rst,go,div,division_done:in std_logic;
	zero_mantissa,mantissa_msb:in std_logic;
	ld_exponent,ld_mantissa,shift_mantissa:out std_logic;
	exponent_src:out std_logic_vector(1 downto 0);
	normalization_done:out std_logic
);
end fp_mul_div_control;
architecture arch of fp_mul_div_control is 

signal state_counter:std_logic_vector(2 downto 0);
signal control:std_logic_vector(4 downto 0);

begin 

process(clk,rst,go,division_done)
begin
if(rst='1') then state_counter<=(others=>'0');normalization_done<='0';
elsif(clk'event and clk='0') then 
	if(go='1' and ((division_done='1' and div='1') or div='0')) then
		if(state_counter="100")then normalization_done<='1';
		elsif(div='0' and mantissa_msb='1' and state_counter="010") then state_counter<="011";
		elsif(div='1' and mantissa_msb='1' and state_counter="010") then state_counter<="100";
		elsif(zero_mantissa='1' and state_counter="010") then state_counter<="100";
		else state_counter<=std_logic_vector(unsigned(state_counter)+1);
	end if;end if;
end if;
end process;
--mantissa division is already done so we load directly
--ld_exponent,exponent_src[],ld_mantissa,shift_mantissa
control<="00000" when state_counter="000" else --reset
		 "10010" when state_counter="001" else --load exponent and mantissa
		 "10101" when state_counter="010" and mantissa_msb='0' else --shift_mantissa and dec exponent
		 "11000" when state_counter="011" else -- increment expo without shifting mantisSa to avoid special case when there is overflow
		 "00000";

ld_exponent<=control(4);
exponent_src<=control(3 downto 2);
ld_mantissa<=control(1);
shift_mantissa<=control(0);
 
end arch;