library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity fp_unit_control is 
port(
	clk:in std_logic;
	op:in std_logic_vector(2 downto 0);
	infinity1,infinity2,zero1,zero2,equal_ops:in std_logic;
	output_control:out std_logic_vector(3 downto 0);
	div,go_add,go_mul,go_converter:out std_logic;
	control_done:out std_logic
);
end fp_unit_control;
architecture arch of fp_unit_control is 
signal output:std_logic_vector(3 downto 0);
signal go_addition,go_multiplication,go_conversion:std_logic;
-- op=000 mult 
-- op=001 div
-- op=010 add 
-- op=011 max
-- op=100 min
-- op=101 conversion
signal equal,div_byinf,div_byzero,mul_byzero,mul_byinf,add_inf,zero_by_zero,inf_by_inf,inf_mul_zero:std_logic;
begin 
--special cases that require special solutions (modern problems require modern solutions xD )
equal<='1' when (op="010" and equal_ops='1')else '0';
div_byinf<='1' when (op="001" and infinity2='1')else '0';
div_byzero<='1' when (op="001" and zero2='1')else '0';
mul_byzero<='1' when (op="000" and (zero2='1' or zero1='1'))else '0';
mul_byinf<='1' when (op="000" and (infinity1='1' or infinity2='1'))else '0';
add_inf<='1' when (op="010" and (infinity1='1' or infinity2='1'))else '0';
zero_by_zero<='1' when (op="001" and (zero2='1' and zero1='1'))else '0';
inf_by_inf<='1' when (op="001" and (infinity1='1' and infinity2='1'))else '0';
inf_mul_zero<='1' when (op="000" and (zero2='1' or zero1='1') and (infinity2='1' or infinity1='1'))else '0';

div<='1' when op="001" else '0';

control_done<='1' when op="100" or op="011" else '0';--force the done signal for another unit that might be used.

go_addition<='1' when op="010" else '0';--to enable only the desired unit

go_conversion<='1' when op="101" else '0';

go_multiplication<='1' when op="000" or op="001" else '0';--to enable only the desired unit

process(clk,op)
begin 
if(clk'event and clk='0') then 
	if(equal or div_byinf or mul_byzero) then output<="0010";
	elsif(add_inf or div_byzero or mul_byinf) then output<="0011";
	elsif(zero_by_zero or inf_by_inf or inf_mul_zero) then output<="0100";
	elsif(op="011") then output<="0101";
	elsif(op="100") then output<="0110";
	elsif(op="101") then output<="0111";
	elsif(op="000" or op="001") then output<="0000";
	elsif(op="010") then output<="0001";
	else output<="1000";
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

go_converter<=go_conversion;

go_mul<=go_multiplication;

go_add<=go_addition;

output_control<=output;
end arch;