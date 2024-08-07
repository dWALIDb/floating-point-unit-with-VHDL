--used for normalization
library ieee;
use ieee.std_logic_1164.all;
--this reg shifts left only :)
entity generic_SL_reg is 
generic(data_width:integer :=8);
port (
	clk,rst,ld,shift:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end generic_SL_reg;
architecture arch of generic_SL_reg is 
signal data:std_logic_vector(data_width-1 downto 0);
begin 

process(clk,rst,ld,shift)
begin 
if(rst='1') then data<=(others=>'0');
elsif(clk'event and clk='1') then 
	if(ld='1') then data<=D;
	elsif(shift='1') then data<=data(data_width-2 downto 0)&'0'; 
	end if;
end if;
end process;

Q<=data;

end arch;