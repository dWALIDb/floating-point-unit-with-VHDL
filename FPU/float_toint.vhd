--conversion to signed ineger values 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity float_toint is 
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
end float_toint;
architecture arch of float_toint is

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

component float_toint_control is 
port (
	clk,rst,go,zero_exponent,too_large,too_small:in std_logic;
	ld_shifter,shift,ld_exponent,exponent_src:out std_logic;
	done:out std_logic
);
end component;

--control
signal zero_exponent,too_large,too_small,ld_shifter,shift,ld_exponent,exponent_src:std_logic;

signal offset_exponent,registered_exponent,adjusted_exponent:std_logic_vector(exponent_width-1 downto 0);
constant OFFSET:std_logic_vector(exponent_width-1 downto 0):=(exponent_width-1=>'0', others=>'1'); 
constant largest_exponent:std_logic_vector(exponent_width-1 downto 0):=std_logic_vector(to_unsigned(operand_width-2,exponent_width));--30
constant ZERO:std_logic_vector(exponent_width-1 downto 0):=(others=>'0');
constant ZERO_operand:std_logic_vector(operand_width-2 downto 0):=(others=>'0');
signal signed_out:std_logic_vector(operand_width-1 downto 0);
signal int,shifter_input:std_logic_vector(operand_width+mantissa_width downto 0);
constant largest_positive_int:std_logic_vector(operand_width+mantissa_width downto 0):=(operand_width+mantissa_width=>'0',others=>'1');
constant largest_negative_int:std_logic_vector(operand_width+mantissa_width downto 0):=(operand_width+mantissa_width=>'1',others=>'0');
constant smallest_possible_int:std_logic_vector(operand_width+mantissa_width downto 0):=(others=>'0');
begin

offset_exponent<=std_logic_vector(unsigned(A(operand_width-2 downto operand_width-1-exponent_width))-unsigned(OFFSET));

adjusted_exponent<=offset_exponent when exponent_src='1' else std_logic_vector(unsigned(registered_exponent)-1);

zero_exponent<='1' when registered_exponent=ZERO else '0';

too_small<='1' when A(operand_width-2 downto operand_width-1-exponent_width)<offset else '0';

too_large<='1' when A(operand_width-2 downto operand_width-1-exponent_width)>std_logic_vector(unsigned(largest_exponent)+unsigned(offset)) else '0';
--if numbers are too large or too small give according largest number or 0
shifter_input<=largest_positive_int  when (too_large='1' and too_small='0' and A(operand_width-1)='0') else
			   largest_negative_int  when (too_large='1' and too_small='0' and A(operand_width-1)='1') else
			   smallest_possible_int when (too_large='0' and too_small='1') else
			   ZERO_operand&'1'&A(mantissa_width-1 downto 0)&'0';--neither too small nor too large 

EXPONENT_EVAL:generic_reg generic map(exponent_width) port map(clk,rst,ld_exponent,adjusted_exponent,registered_exponent);

INT_FORMATION:generic_SL_reg generic map(operand_width+mantissa_width+1) port map(clk,rst,ld_shifter,shift,shifter_input,int);

--mux to select 2s compolement or directly output
signed_out<=int(operand_width+mantissa_width downto mantissa_width+1) when A(operand_width-1)='0' else std_logic_vector(unsigned(not(int(operand_width+mantissa_width downto mantissa_width+1)))+1);

C<=signed_out;

CONTROL:float_toint_control port map(clk,rst,go,zero_exponent,too_large,too_small,ld_shifter,shift,ld_exponent,exponent_src,done);

end arch;