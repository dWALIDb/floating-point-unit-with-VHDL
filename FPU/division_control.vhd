--inputs are of the form 1.rest and we need to iterate as much as the 
--mantissa length of our design plus one more iteration to aid with the rounding
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity division_control is 
--desired_length is for the iterations that need to be done, 24 for mantissa that is larger by one spot to round
generic(desired_length: integer:=23);
port (
	clk,rst,go,negative_result:in std_logic;
	ld_A,A_src,ld_B,shift,take_quotient:out std_logic;
	DONE:out std_logic
);
end division_control;
architecture arch of division_control is 
signal control:std_logic_vector(4 downto 0);
signal state_counter:std_logic_vector(1 downto 0):=(others=>'0');
--00 for reset 01 to get operands 10 for division then 11 when done 
signal iterations: integer range 0 to desired_length; 
begin 

process(clk,rst,go)
begin 
if(rst='1') then state_counter<=(others=>'0');iterations<=0;done<='0';
elsif(clk'event and clk='0') then 
					if go='1' then 
								if state_counter="11" then done<='1';
								elsif state_counter="10" and iterations<desired_length then iterations<=iterations+1;
								else state_counter<=state_counter+'1';
					end if;end if;
end if;
end process;
--ld_A,A_src,ld_B,shift,take_quotient
control<="11100" when (state_counter="01") else  --load operands
		 "00011" when (state_counter="10" and negative_result='1')else --shift left in A when A<B quotient gets 0
		 "10001" when (state_counter="10" and negative_result='0')else --take differencex2 in A when A>B quotient gets 1
		 "00000";
ld_A<=control(4);
A_src<=control(3);
ld_B<=control(2);
shift<=control(1);
take_quotient<=control(0);
end arch;