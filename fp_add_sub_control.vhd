library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp_add_sub_control is 
port(
	clk,rst,go,zero_mantissa,mantissa_msb,subtract:in std_logic;
	ld_larger,ld_smaller,ld_exponent,shift_mantissa,ld_mantissa:out std_logic;
	shift_smaller,exponent_src:out std_logic_vector(1 downto 0);
	done:out std_logic
);
end fp_add_sub_control;
architecture arch of fp_add_sub_control is 
signal state_counter:std_logic_vector(2 downto 0):=(others=>'0');
signal control:std_logic_vector(8 downto 0);

begin 

process(clk,rst,go,zero_mantissa,subtract)
begin
if(rst='1') then state_counter<=(others=>'0');done<='0';
elsif(clk'event and clk='0') then if(go='1') then 
				if(state_counter="110") then done<='1';
				elsif(state_counter="100" and subtract='1') then state_counter<="110"; 
				elsif(zero_mantissa='1' and state_counter="011") then state_counter<="110";
				elsif(mantissa_msb='1' and state_counter="100") then state_counter<="101";
				
				else state_counter<=std_logic_vector(unsigned(state_counter)+1);
			end if;end if;
end if;
end process;
--ld_larger,ld_smaller,shift_smaller[],ld_exponent,exponent_src[],ld_mantissa,shift_mantissa
control<="000000000" when state_counter="000" else
		 "110010000" when state_counter="001" else --get operands and exponent
		 "000100000" when state_counter="010" else --shift the smaller mantissa right
		 "000000010" when state_counter="011" else --ld shifter for normalization
		 "000011101" when state_counter="100" and mantissa_msb='0' else --normalize by shifting left and decrementing exponent
		 "000010100" when state_counter="101" else --increment exponent to avoid special case 
		 "000000000";

ld_larger<=control(8);
ld_smaller<=control(7);
shift_smaller<=control(6 downto 5);
ld_exponent<=control(4);
exponent_src<=control(3 downto 2);
ld_mantissa<=control(1);
shift_mantissa<=control(0);
end arch;