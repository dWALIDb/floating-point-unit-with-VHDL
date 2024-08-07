--used for aligning mantissas according to difference of exponents 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity shift_reg is 
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
end shift_reg;
architecture arch of shift_reg is 
signal data:std_logic_vector(data_width-1 downto 0);
begin 

process(clk,rst,ld,shift)
begin 
if(rst='1') then data<=(others=>'0');
elsif(clk'event and clk='1') then 
	if(ld='1') then data<=D;
	else case shift is 
		when"00"=>data<=data;
		when"01"=>data<=std_logic_vector(shift_right(unsigned(data),to_integer(unsigned(shamt))));
		when"10"=>data<=std_logic_vector(shift_left(unsigned(data),to_integer(unsigned(shamt))));
		when"11"=>data<=data;
		when others=>null;
	end case;
	end if;
end if;
end process;
Q<=data;
end arch;