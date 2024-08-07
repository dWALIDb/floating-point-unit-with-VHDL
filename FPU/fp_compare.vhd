--module determines if  A exponent is greater when A is positive
--or A exponent is less when both A and B are negative, this leads to determining by exponent 
--else compare mantissa in similar manner to determine the larger mantissa and getting the output 
-- the min is done the other way around 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp_compare is 
generic(
	operand_width:integer:=32;
	mantissa_width:integer:=23;
	exponent_width:integer:=8
);
port(
	A,B:in std_logic_vector(operand_width-1 downto 0);
	max,min:out std_logic_vector(operand_width-1 downto 0)
);
end fp_compare;
architecture arch of fp_compare is
signal larger_positive,larger_negative,larger_mantissa_positive,larger_mantissa_negative:std_logic;
signal equal_exponent,greater_exponent,greater_mantissa,exponent_decision,mantissa_decision:std_logic; --assuming for A else we output B
signal output_max,output_min:std_logic_vector(operand_width-1 downto 0);
begin 
larger_positive<='1' when (greater_exponent='1' and A(operand_width-1)='0') else '0';

larger_negative<='1' when (greater_exponent='0' and A(operand_width-1)='1' and B(operand_width-1)='1') else '0';

larger_mantissa_positive<='1' when (equal_exponent='1' and greater_mantissa='1' and A(operand_width-1)='0') else '0';

larger_mantissa_negative<='1' when (equal_exponent='1' and greater_mantissa='0' and A(operand_width-1)='1' and B(operand_width-1)='1') else '0';

equal_exponent<='1' when a(operand_width-2 downto operand_width-exponent_width-1)=B(operand_width-2 downto operand_width-exponent_width-1) else '0';

greater_exponent<='1' when a(operand_width-2 downto operand_width-exponent_width-1)>B(operand_width-2 downto operand_width-exponent_width-1) else '0';

greater_mantissa<='1' when a(mantissa_width-1 downto 0)>B(mantissa_width-1 downto 0) else '0';

exponent_decision<='1' when ((larger_negative='1' or larger_positive='1') and equal_exponent='0') else '0';

mantissa_decision<='1' when ((larger_mantissa_negative='1' OR larger_mantissa_positive='1') and equal_exponent='1') else '0';

output_max<=A when exponent_decision='1' or (mantissa_decision='1' AND exponent_decision='0') or A(operand_width-1)='0' else B;

output_min<=A when exponent_decision='0' and  mantissa_decision='0' and A(operand_width-1)='1' else B;

min<=output_min;

max<=output_max;
end arch;