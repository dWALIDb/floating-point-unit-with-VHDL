--force -freeze sim:/fp_add_sub/clk 1 0, 0 {50 ps} -r 100
--force -freeze sim:/fp_add_sub/rst 1 0
--force -freeze sim:/fp_add_sub/go 1 0
--force -freeze sim:/fp_add_sub/A 01000000101000000000000000000000 0
--force -freeze sim:/fp_add_sub/B 01000000110000000000000000000000 0
--only addition defined so if you want to subtract you gotta set MSB to 1 so the signs are different 
/*
force -freeze sim:/fp_add_sub/clk 1 0, 0 {50 ps} -r 100
force -freeze sim:/fp_add_sub/rst 1 0
force -freeze sim:/fp_add_sub/go 1 0
force -freeze sim:/fp_add_sub/A 11000000001000000000000000000000 0
force -freeze sim:/fp_add_sub/B 01000000000000000000000000000000 0
*/
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp_add_sub is 
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
end fp_add_sub;
architecture arch of fp_add_sub is

component fp_add_sub_control is 
port(
	clk,rst,go,zero_mantissa,mantissa_msb,subtract,zero_exponent1,zero_exponent2,mantissa_msb_for_subtraction:in std_logic;
	ld_larger,ld_smaller,ld_exponent,shift_mantissa,ld_mantissa:out std_logic;
	shift_smaller,exponent_src:out std_logic_vector(1 downto 0);
	done:out std_logic
);
end component;

component generic_reg is 
generic(data_width:integer :=8);
port (
	clk,rst,ld:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component;

component add_sub is 
generic(data_width: integer:=24);
port(
	A,B:in std_logic_vector(data_width-1 downto 0);
	sub:in std_logic;
	C:out std_logic_vector(data_width -1 downto 0)
);end component;

component shift_reg is 
generic(data_width:integer :=8;
		shift_amount_field: integer:=8
);
port (
	clk,rst,ld:in std_logic;
	shift:in std_logic_vector(1 downto 0);
	shamt:std_logic_vector(shift_amount_field-1 downto 0);
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component;

component generic_SL_reg is 
generic(data_width:integer :=8);
port (
	clk,rst,ld,shift:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component;
--some conditions to determine the larger or smaller values 
signal equal_exponent,greater_exponent,equal_mantissa,greater_mantissa:std_logic;
-- control signals 
signal sign,mantissa_msb_for_subtraction,zero_exponent1,zero_exponent2,sub_mantissa,zero_mantissa,ld_larger,ld_smaller,ld_exponent,shift_mantissa,ld_mantissa,mantissa_msb: std_logic;
signal shift_smaller,exponent_src:std_logic_vector(1 downto 0);
--exponent signals 
signal exponent_difference,shift_amount,larger_exponent,adjusted_exponent,registered_exponent:std_logic_vector(exponent_width-1 downto 0);
--mantissa signals 
signal larger,smaller,rounded_mantissa:std_logic_vector(mantissa_width-1 downto 0);
signal A_mantissa:std_logic_vector(mantissa_width+exponent_width-1 downto 0);
signal B_mantissa:std_logic_vector(mantissa_width+exponent_width downto 0);
signal resulting_mantissa,normalized_mantissa:std_logic_vector(mantissa_width+exponent_width+1 downto 0);
constant zero:std_logic_vector(mantissa_width+exponent_width+1 downto 0):=(others=>'0');
begin

zero_exponent1<='1' when A(operand_width-2 downto operand_width-exponent_width-1)=zero(exponent_width-1 downto 0) else '0';

zero_exponent2<='1' when B(operand_width-2 downto operand_width-exponent_width-1)=zero(exponent_width-1 downto 0) else '0';

equal_exponent<='1' when A(operand_width-2 downto operand_width-exponent_width-1)=B(operand_width-2 downto operand_width-exponent_width-1) else '0';

greater_exponent<='1' when A(operand_width-2 downto operand_width-exponent_width-1)>B(operand_width-2 downto operand_width-exponent_width-1) else '0';

--equal_mantissa<='1' when A(mantissa_width-1 downto 0)=B(mantissa_width-1 downto 0) else '0';

greater_mantissa<='1' when A(mantissa_width-1 downto 0)>B(mantissa_width-1 downto 0) else '0';


exponent_difference<=std_logic_vector(unsigned(A(operand_width-2 downto operand_width-exponent_width-1))-unsigned(B(operand_width-2 downto operand_width-exponent_width-1)));

--either larger by exponent or equal exponent and larger mantissa
sign<=A(operand_width-1) when (greater_exponent='1' or (greater_exponent='0' and equal_exponent='1' and greater_mantissa='1')) else B(operand_width-1);

larger_exponent<=A(operand_width-2 downto operand_width-exponent_width-1) when (greater_exponent='1' or (greater_exponent='0' and equal_exponent='1' and greater_mantissa='1')) else B(operand_width-2 downto operand_width-exponent_width-1);

adjusted_exponent<=larger_exponent when exponent_src="00" else 
				std_logic_vector(unsigned(registered_exponent) +1) when exponent_src="01" else
				std_logic_vector(unsigned(registered_exponent) -1);

EXPONENT:generic_reg generic map(exponent_width) port map(clk,rst,ld_exponent,adjusted_exponent,registered_exponent);

shift_amount<=exponent_difference when A(operand_width-2 downto operand_width-exponent_width-1)>B(operand_width-2 downto operand_width-exponent_width-1) else std_logic_vector(unsigned(not(exponent_difference))+1);

larger<=A(mantissa_width-1 downto 0) when (greater_exponent='1' or (greater_exponent='0' and equal_exponent='1' and greater_mantissa='1')) else B(mantissa_width-1 downto 0);

smaller<=A(mantissa_width-1 downto 0) when not (greater_exponent='1' or (greater_exponent='0' and equal_exponent='1' and greater_mantissa='1')) else B(mantissa_width-1 downto 0);

LARGER_OPERAND:generic_reg generic map(mantissa_width+exponent_width) port map(clk,rst,ld_larger,larger&zero(exponent_width-1 downto 0),A_mantissa); 

SMALLER_OPERAND:shift_reg generic map(mantissa_width+exponent_width+1,exponent_width) port map(clk,rst,ld_smaller,shift_smaller,shift_amount,'1'&smaller&zero(exponent_width-1 downto 0),B_mantissa);

sub_mantissa<=A(operand_width-1) xor B(operand_width-1);

OPERATION_ON_MANTISSA: add_sub generic map(mantissa_width+exponent_width+2) port map("01"&A_mantissa,'0'&B_mantissa,sub_mantissa,resulting_mantissa); 

NORMALIZATION:generic_SL_reg generic map(mantissa_width+exponent_width+2) port map(clk,rst,ld_mantissa,shift_mantissa,resulting_mantissa,normalized_mantissa);

zero_mantissa<='1' when normalized_mantissa=zero else '0';

mantissa_msb<=normalized_mantissa(mantissa_width+exponent_width+1);
mantissa_msb_for_subtraction<=normalized_mantissa(mantissa_width+exponent_width);

CONTROL:fp_add_sub_control port map(clk,rst,go,zero_mantissa,mantissa_msb,sub_mantissa,zero_exponent1,zero_exponent2,mantissa_msb_for_subtraction,ld_larger,ld_smaller,ld_exponent,shift_mantissa,ld_mantissa,shift_smaller,exponent_src,done);

rounded_mantissa<=std_logic_vector(unsigned(normalized_mantissa(mantissa_width+exponent_width downto exponent_width+1)) );-- + unsigned(normalized_mantissa(exponent_width downto exponent_width)));

C<=sign&registered_exponent&rounded_mantissa;
end arch;
