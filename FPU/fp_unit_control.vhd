--special cases handeled according to ieee754 where only infinities or NAN result to NAN
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity fp_unit_control is 
port(
	clk:in std_logic;
	op:in std_logic_vector(3 downto 0);
	infinity1,infinity2,zero1,zero2,equal_ops:in std_logic;
	output_control:out std_logic_vector(3 downto 0);
	div,go_add,go_mul,go_conv_int_tofloat,go_conv_float_toint:out std_logic;
	control_done:out std_logic
);
end fp_unit_control;
architecture arch of fp_unit_control is 
signal output:std_logic_vector(3 downto 0);
signal go_addition,go_multiplication,go_conversion1,go_conversion2:std_logic;
-- op=0000 mult 
-- op=0001 div
-- op=0010 add 
-- op=0011 max
-- op=0100 min
-- op=0101 conversion(int to float)
-- op=0110 conversion(float to int)
-- op=0111 absolute value
-- op=1000 negative
signal equal,div_byinf,div_byzero,mul_byzero,mul_byinf,add_inf,zero_by_zero,inf_by_inf,inf_mul_zero:std_logic;
begin 
--special cases that require special solutions (modern problems require modern solutions xD )
equal<='1' when (op="0010" and equal_ops='1')else '0';
div_byinf<='1' when (op="0001" and infinity2='1')else '0';
div_byzero<='1' when (op="0001" and zero2='1')else '0';
mul_byzero<='1' when (op="0000" and (zero2='1' or zero1='1'))else '0';
mul_byinf<='1' when (op="0000" and (infinity1='1' or infinity2='1'))else '0';
add_inf<='1' when (op="0010" and (infinity1='1' or infinity2='1'))else '0';
zero_by_zero<='1' when (op="0001" and (zero2='1' and zero1='1'))else '0';
inf_by_inf<='1' when (op="0001" and (infinity1='1' and infinity2='1'))else '0';
inf_mul_zero<='1' when (op="0000" and (zero2='1' or zero1='1') and (infinity2='1' or infinity1='1'))else '0';


div<='1' when op="0001" else '0';

control_done<='1' when op="0100" or op="0011" or op="1000" or op="0111"  else '0';--force the done signal for another unit that might be used.

go_addition<='1' when op="0010" else '0';--to enable only the desired unit

go_conversion1<='1' when op="0101" else '0';--to enable only desired unit

go_conversion2<='1' when op="0110" else '0';--to enable only desired unit

go_multiplication<='1' when op="0000" or op="0001" else '0';--to enable only the desired unit

process(clk,op)
begin 
if(clk'event and clk='0') then 
	if(equal or div_byinf or mul_byzero) then output<="0010";
	elsif(add_inf or div_byzero or mul_byinf) then output<="0011";
	elsif(zero_by_zero or inf_by_inf or inf_mul_zero) then output<="0100";
	elsif(op="0011") then output<="0101";
	elsif(op="0100") then output<="0110";
	elsif(op="0101") then output<="0111";
	elsif(op="0000" or op="001") then output<="0000";
	elsif(op="0010") then output<="0001";
	elsif(op="0110") then output<="1000";
	elsif(op="0111") then output<="1001";
	elsif(op="1000") then output<="1010";
	else output<="1011";

--output<="000" when op="000" or op="001" else --mult or div
--		"001" when op="010" else --add/sub
--		"010" when (equal or div_byinf or mul_byzero) else --for 0 for A-A or A/inf
--		"011" when (add_inf or div_byzero or mul_byinf) else --for inf
--		"100"  when (zero_by_zero or inf_by_inf or inf_mul_zero) else --
--		"101" when op="011" else --max
--		"110" when op="100" else --min
--		"111" when op="101";--convert
end if;end if;

end process;

go_mul<=go_multiplication;

go_add<=go_addition;

go_conv_int_tofloat<=go_conversion1;

go_conv_float_toint<=go_conversion2;

output_control<=output;
end arch;