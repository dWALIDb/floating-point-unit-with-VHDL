--add wave -position insertpoint sim:/fp_mul_div/*
--force -freeze sim:/fp_mul_div/clk 1 0, 0 {50 ps} -r 100
--force -freeze sim:/fp_mul_div/rst 1 0
--force -freeze sim:/fp_mul_div/go 1 0
--force -freeze sim:/fp_mul_div/div 0 0
--force -freeze sim:/fp_mul_div/B 00000001011100000000000000000000 0
--force -freeze sim:/fp_mul_div/A 01000000101000000000000000000000 0
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp_mul_div is 
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
);end fp_mul_div;
architecture arch of fp_mul_div is 

component add_sub is 
generic(data_width: integer:=24);
port(
	A,B:in std_logic_vector(data_width-1 downto 0);
	sub:in std_logic;
	C:out std_logic_vector(data_width -1 downto 0)
);
end component;

component mul_div is 
generic(data_width: integer:=24);
port(
	clk,rst,go,div:in std_logic;
	A,B:in std_logic_vector(data_width-1 downto 0);
	DIVISION_DONE:out std_logic;
	C:out std_logic_vector(2*data_width -1 downto 0)
);end component;

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

component fp_mul_div_control
port(
	clk,rst,go,div,division_done:in std_logic;
	zero_mantissa,mantissa_msb:in std_logic;
	ld_exponent,ld_mantissa,shift_mantissa:out std_logic;
	exponent_src:out std_logic_vector(1 downto 0);
	normalization_done:out std_logic 
);
end component;
--control signals
signal division_done,zero_mantissa,mantissa_msb,ld_exponent,ld_mantissa,shift_mantissa:std_logic;
signal exponent_src:std_logic_vector(1 downto 0);
--exponent signals
signal initial_exponent,offset_exponent,registered_exponent,adjusted_exponent:std_logic_vector(exponent_width-1 downto 0);
constant offset:std_logic_vector(exponent_width-1 downto 0):=(exponent_width-1=>'0',others=>'1');
constant zero_exponent:std_logic_vector(exponent_width-1 downto 0):=(others=>'0');
--mantissa signals
signal rounded_mantissa:std_logic_vector(mantissa_width-1 downto 0);
signal initial_mantissa,normalized_mantissa:std_logic_vector(2*mantissa_width+1 downto 0);
constant ZERO:std_logic_vector(2*mantissa_width+1 downto 0):=(others=>'0');
--sign bit
signal sign:std_logic;

begin 

sign<=A(operand_width-1) xor B(operand_width-1);

EXPONENT_CALCULATION:add_sub generic map(exponent_width) port map(A(operand_width-2 downto operand_width-exponent_width-1),B(operand_width-2 downto operand_width-exponent_width -1),div,initial_exponent);

EXPONENT_OFFSET:add_sub generic map(exponent_width) port map(initial_exponent,offset,not(div),offset_exponent);

adjusted_exponent<=offset_exponent when exponent_src="00" else 
				std_logic_vector(unsigned(registered_exponent) - 1) when exponent_src="01" 
				else std_logic_vector(unsigned(registered_exponent) + 1) ;

EXPONENT_holder:generic_reg generic map(exponent_width) port map(clk,rst,ld_exponent,adjusted_exponent,registered_exponent);

MANTISSA_CALCULATION:mul_div generic map(mantissa_width+1) port map(clk,rst,go,div,'1'&a(mantissa_width-1 downto 0),'1'&b(mantissa_width-1 downto 0),division_done,initial_mantissa);

NORMALIZATION:generic_SL_reg generic map(2*mantissa_width +2) port map(clk,rst,ld_mantissa,shift_mantissa,initial_mantissa,normalized_mantissa);

zero_mantissa<='1' when normalized_mantissa=ZERO else '0';

mantissa_msb<=normalized_mantissa(2*mantissa_width+1);

CONTROL:fp_mul_div_control port map(clk,rst,go,div,division_done,zero_mantissa,mantissa_msb,ld_exponent,ld_mantissa,shift_mantissa,exponent_src,done);

rounded_mantissa<=std_logic_vector(unsigned(normalized_mantissa(2*mantissa_width downto mantissa_width+1))+unsigned(normalized_mantissa(mantissa_width downto mantissa_width)));

C<=sign& registered_exponent & rounded_mantissa;

end arch;