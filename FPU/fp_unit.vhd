--force -freeze sim:/fp_unit/clk 1 0, 0 {50 ps} -r 100
--force -freeze sim:/fp_unit/rst 1 0
--force -freeze sim:/fp_unit/op 000 0
--force -freeze sim:/fp_unit/A 01000000101000000000000000000000 0
--force -freeze sim:/fp_unit/B 11000000101000000000000000000000 0

--works only on normal numbers because i dont have the IQ to implement denormals, might use software for that
-- for denormals the are treated as ZERO :) 
--special cases are treated directly by additional logic like multiplication of 0 by infinity and so on
--conversions are signed

--could outMIN outMAX add mul div conv to int or to float subtraction done by adding positive to negative 
--special cases handeled in control unit
library ieee;
use ieee.std_logic_1164.all;

entity fp_unit is 
generic(
operand_width:integer:=32;
mantissa_width:integer:=23;
exponent_width:integer:=8
);
port(
	clk,rst:in std_logic;
	op:in std_logic_vector(3 downto 0);
	A,B:in std_logic_vector(operand_width-1 downto 0);
	done:out std_logic;
	C:out std_logic_vector(operand_width-1 downto 0)
);
end fp_unit;
architecture arch of fp_unit is 

component int_tofloat is 
generic(
	operand_width:integer:=32;
	mantissa_width:integer:=23;
	exponent_width:integer:=8
);
port (
	clk,rst,go:in std_logic;
	A:in std_logic_vector(operand_width-1 downto 0);
	done:out std_logic;
	C:out std_logic_vector(operand_width-1 downto 0)
);
end component;

component fp_compare is 
generic(
	operand_width:integer:=32;
	mantissa_width:integer:=23;
	exponent_width:integer:=8
);
port(
	A,B:in std_logic_vector(operand_width-1 downto 0);
	max,min:out std_logic_vector(operand_width-1 downto 0)
);
end component;

component fp_mul_div is 
generic(
operand_width: integer:=32;
mantissa_width: integer:=23;
exponent_width: integer:=8
);
port(
	clk,rst,go,div:in std_logic;
	A,B:in std_logic_vector(operand_width-1 downto 0);
	done:out std_logic;
	C:out std_logic_vector(operand_width-1 downto 0)
);end component;

component fp_add_sub is 
generic(
	operand_width: integer:=32;
	mantissa_width: integer:=23;
	exponent_width: integer:=8
);
port(
	clk,rst,go:in std_logic;
	A,B:in std_logic_vector(operand_width-1 downto 0);
	done: out std_logic;
	C:out std_logic_vector(operand_width-1 downto 0)
);
end component;

component fp_unit_control is 
port(
	clk:std_logic;
	op:in std_logic_vector(3 downto 0);
	infinity1,infinity2,zero1,zero2,equal_ops:in std_logic;
	output_control:out std_logic_vector(3 downto 0);
	div,go_add,go_mul,go_conv_int_tofloat,go_conv_float_toint:out std_logic;
	control_done:out std_logic
);
end component;

component float_toint is 
generic(
	operand_width:integer:=32;
	mantissa_width:integer:=23;
	exponent_width:integer:=8
);
port (
	clk,rst,go:in std_logic;
	A:in std_logic_vector(operand_width-1 downto 0);
	done:out std_logic;
	C:out std_logic_vector(operand_width-1 downto 0)
);
end component;

procedure check_correct_length(operand_length:in integer;mantissa_length:in integer;exponent_length:in integer) is 
begin 
--the mantissa + exponent fields must add up to operand_width-1 the last one is the sign bit 
-- else the lengths do not add up
assert(operand_length-1=exponent_length+mantissa_length)
report "the mantissa and exponent fields do not add up to "&integer'image(operand_length-1)
severity failure;

end procedure;

signal mult,add,conved_float_toint,conved_int_tofloat,operation,MIN,MAX:std_logic_vector(operand_width-1 downto 0);
constant zero:std_logic_vector(operand_width-1 downto 0):=(others=>'0');
constant NAN:std_logic_vector(operand_width-1 downto 0):=x"7fc00000";
constant all_ones:std_logic_vector(exponent_width-1 downto 0):=(others=>'1');
signal conv_int_tofloat_done,mult_done,add_done,go_mul,go_add,div,infinity1,infinity2,zero1,zero2,equal_ops,control_done,go_conv_int_tofloat,conv_float_toint_done,go_conv_float_toint:std_logic;
signal output_control:std_logic_vector(3 downto 0);
begin 

check_correct_length(operand_width,mantissa_width,exponent_width);

equal_ops<='1' when (A(operand_width-2 downto 0)=B(operand_width-2 downto 0) and A(operand_width-1)/=B(operand_width-1)) else '0';

infinity1<='1' when A(operand_width-2 downto operand_width-exponent_width-1)=all_ones else '0';

infinity2<='1' when B(operand_width-2 downto operand_width-exponent_width-1)=all_ones else '0';

zero1<='1' when A(operand_width-2 downto operand_width-exponent_width-1)=not all_ones else '0';

zero2<='1' when B(operand_width-2 downto operand_width-exponent_width-1)=not all_ones else '0';

MULTIPLICATION:fp_mul_div generic map(operand_width,mantissa_width,exponent_width) port map(clk,rst,go_mul,div,A,B,mult_done,mult);

ADDITION:fp_add_sub generic map(operand_width,mantissa_width,exponent_width) port map(clk,rst,go_add,A,B,add_done,add);

CONTROL:fp_unit_control port map(clk,op,infinity1,infinity2,zero1,zero2,equal_ops,output_control,div,go_add,go_mul,go_conv_int_tofloat,go_conv_float_toint,control_done);

operation<=mult when output_control="0000" else
		add when output_control="0001" else 
		zero when output_control="0010"else
		(A(operand_width-1)xor B(operand_width-1))&"111"&x"F800000" when output_control="0011" else --inf
		NAN when output_control="0100" else
		MAX when output_control="0101" else
		MIN when output_control="0110" else
		conved_int_tofloat when output_control="0111" else 
		conved_float_toint when output_control="1000" else
		'0'&A(operand_width-2 downto 0) when output_control="1001" else
		'1'&A(operand_width-2 downto 0) when output_control="1010" else
		(others=>'0');

C<=operation;

done<=add_done or mult_done or control_done or conv_int_tofloat_done or conv_float_toint_done;

COMPARATOR:fp_compare generic map(operand_width,mantissa_width,exponent_width) port map(A,B,MAX,MIN);

CONV_tofloat:int_tofloat generic map(operand_width,mantissa_width,exponent_width) port map(clk,rst,go_conv_int_tofloat,A,conv_int_tofloat_done,conved_int_tofloat);

CONV_toint:float_toint generic map(operand_width,mantissa_width,exponent_width) port map(clk,rst,go_conv_float_toint,A,conv_float_toint_done,conved_float_toint);
end arch;