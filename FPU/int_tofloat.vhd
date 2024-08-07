--integers converted are signed
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int_tofloat is 
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
end int_tofloat;
architecture arch of int_tofloat is 

component int_tofloat_control is 
port(
	clk,rst,go,ZERO,mantissa_msb:std_logic;
	ld_shifter,shift,ld_exponent:out std_logic;
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

component generic_SL_reg is 
generic(data_width:integer :=8);
port (
	clk,rst,ld,shift:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component;

signal ld_exponent,ld_shifter,shift,zero,mantissa_msb:std_logic;
signal chosen_value,normalized_value:std_logic_vector(operand_width-1 downto 0);
signal adjusted_exponent,registered_exponent,final_exponent:std_logic_vector(exponent_width-1 downto 0);
CONSTANT offset:std_logic_vector(exponent_width-1 downto 0):=(exponent_width-1=>'0',others=>'1');
CONSTANT largest_exponent:std_logic_vector(exponent_width-1 downto 0):=std_logic_vector(to_unsigned((operand_width-1),offset'length));
CONSTANT absolute_zero:std_logic_vector(operand_width-1 downto 0):=(others=>'0');
begin
chosen_value<=A when A(operand_width-1)='0' else std_logic_vector(unsigned(not(A))+1);

NORMALIZE:generic_SL_reg generic map(operand_width) port map(clk,rst,ld_shifter,shift,chosen_value,normalized_value);

GET_exponent:generic_reg generic map(exponent_width) port map(clk,rst,ld_exponent,adjusted_exponent,registered_exponent);

mantissa_msb<=normalized_value(operand_width-1);

adjusted_exponent<=std_logic_vector(unsigned(registered_exponent)-1);

final_exponent<=std_logic_vector(unsigned(largest_exponent)+unsigned(offset)+unsigned(registered_exponent));

zero<='1' when A=absolute_zero else '0';

CONTROL:int_tofloat_control port map(clk,rst,go,zero,mantissa_msb,ld_shifter,shift,ld_exponent,done);

C<=A(operand_width-1)&final_exponent&normalized_value(operand_width-2 downto operand_width-mantissa_width-1);
end arch;
