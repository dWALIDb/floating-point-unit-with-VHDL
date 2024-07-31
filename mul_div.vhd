library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- mantissa length is 23 bits but we need extra 1 in front of mantissa 
-- because the leading 1 is not stored
entity mul_div is 
generic(data_width: integer:=24);
port(
	clk,rst,go,div:in std_logic;
	A,B:in std_logic_vector(data_width-1 downto 0);
	DIVISION_DONE:out std_logic;
	C:out std_logic_vector(2*data_width -1 downto 0)
);end mul_div;
architecture arch of mul_div is 
--we need to get more bits somehow xD
function reverse(x: std_logic_vector) return std_logic_vector is
variable y: std_logic_vector (x'range);
begin
for i in x'range loop
y(i) := x (x'left - i);
end loop;
return y;
end function;

component divider is 
generic(
	data_width:integer :=23
);
port (
	clk,rst,go:in std_logic;
	A,B:in std_logic_vector(data_width-1 downto 0);
	DONE:out std_logic;
	C:out std_logic_vector(data_width downto 0)
);
end component;

signal multiplication,output:std_logic_vector(2*data_width -1 downto 0);
signal division,reversed_bus:std_logic_vector(data_width downto 0);
begin 

multiplication<=std_logic_vector(unsigned(A) * unsigned(B));

division_unit:divider generic map(data_width)port map(clk,rst,go,a,b,DIVISION_DONE,division);
reversed_bus<=reverse(division);
output<=multiplication when div='0' else division & reversed_bus(data_width-2 downto 0);

c<=output;
end arch;