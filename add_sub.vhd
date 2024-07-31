library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity add_sub is 
generic(data_width: integer:=24);
port(
	A,B:in std_logic_vector(data_width-1 downto 0);
	sub:in std_logic;
	C:out std_logic_vector(data_width -1 downto 0)
);end add_sub;
architecture arch of add_sub is 

signal addition,subtraction,output:std_logic_vector(data_width-1 downto 0);
begin 

addition<=std_logic_vector(unsigned(A) + unsigned(B));

subtraction<=std_logic_vector(unsigned(A) - unsigned(B));

output<=addition when sub='0' else subtraction;

c<=output;
end arch;