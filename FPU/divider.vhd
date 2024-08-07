library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--all inputs are made as 1.xxxxxxxxxxx
--example:9 is 1.001 x2^3 :) and 3 is 1.1 x2^1
--no special cases are handeled 
entity divider is 
generic(
	data_width:integer :=23
);
port (
	clk,rst,go:in std_logic;
	A,B:in std_logic_vector(data_width-1 downto 0);
	DONE:out std_logic;
	C:out std_logic_vector(data_width downto 0)
);
end divider;
architecture arch of divider is 

component division_control is 
generic(
desired_length:integer :=23
);
port (
	clk,rst,go,negative_result:in std_logic;
	ld_A,A_src,ld_B,shift,take_quotient:out std_logic;
	DONE:out std_logic
);
end component;

component generic_SL_reg is 
generic(
data_width:integer :=8
);
port (
	clk,rst,ld,shift:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component;

component generic_reg is 
generic(
data_width:integer :=8
);
port (
	clk,rst,ld:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component;
-- control and status signals
signal ld_A,A_src,ld_B,shift,take_quotient:std_logic;
signal negative_result:std_logic;
--force -freeze sim:/divider/rst 0 0
--force -freeze sim:/divider/go 0 0
--force -freeze sim:/divider/A 10010000000000000000000 0
--force -freeze sim:/divider/B 11000000000000000000000 0
signal registered_B:std_logic_vector(data_width-1 downto 0);
signal difference,to_A_reg,registered_A:std_logic_vector(data_width downto 0);
signal quotient:std_logic_vector(data_width downto 0);
begin 
--either shift A and put 0 in quotient a<b
--or.. take (a-b)x2 and 1 in quotient  a>b 
--this is determined by msb of the diffrence
negative_result<=difference(data_width);

to_A_reg<= difference(data_width-1 downto 0)&'0' when A_src='0' else '0'&A ;

OPERAND1:generic_SL_reg generic map (data_width+1) port map(clk,rst,ld_A,shift,to_A_reg,registered_A);

OPERAND2:generic_reg generic map(data_width) port map(clk,rst,ld_B,B,registered_B);

difference<=std_logic_vector(unsigned(registered_A) - unsigned(registered_B)); 

CONTROL:division_control generic map(data_width) port map(clk,rst,go,negative_result,ld_A,A_src,ld_B,shift,take_quotient,DONE);

quotient_evaluation:process(clk,take_quotient,rst,negative_result)
begin
if(rst='1') then quotient<=(others=>'0');
elsif(clk'event and clk='1')then 
	if(take_quotient='1') then quotient<=quotient(data_width-1 downto 0)&not(negative_result);
	end if;
end if;
end process;
C<=quotient;
end arch;