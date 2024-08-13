--special case when adding 
-- the result may give a carry so the exponent must be incremented
-- no need to shift mantissa when incrementing because its already in the msb thus it perfectly aligns with the design
--if in subtraction then shift and decrement untill 1 in mantissa_msb_for_subtraction='1' then shift once without affecting mantissa
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fp_add_sub_control is 
port(
	clk,rst,go,zero_mantissa,mantissa_msb,subtract,zero_exponent1,zero_exponent2,mantissa_msb_for_subtraction:in std_logic;
	ld_larger,ld_smaller,ld_exponent,shift_mantissa,ld_mantissa:out std_logic;
	shift_smaller,exponent_src:out std_logic_vector(1 downto 0);
	done:out std_logic
);
end fp_add_sub_control;
architecture arch of fp_add_sub_control is 
signal state_counter:std_logic_vector(2 downto 0):=(others=>'0');
signal control:std_logic_vector(8 downto 0);
signal operands_arezero:std_logic;
begin 

operandS_arezero<=zero_exponent1 and zero_exponent2;

process(clk,rst,go,zero_mantissa,subtract)
begin
if(rst='1') then state_counter<=(others=>'0');done<='0';
elsif(clk'event and clk='0') then if(go='1') then 
				if(state_counter="111") then done<='1';
				elsif(state_counter="100" and subtract='1' and mantissa_msb_for_subtraction='1') then state_counter<="110"; 
				elsif(zero_mantissa='1' and state_counter="011") then state_counter<="111";
				elsif(mantissa_msb='1' and state_counter="100") then state_counter<="101";
				elsif(state_counter="101") then state_counter<="111";
				else state_counter<=std_logic_vector(unsigned(state_counter)+1);
			end if;end if;
end if;
end process;
--ld_larger,ld_smaller,shift_smaller[],ld_exponent,exponent_src[],ld_mantissa,shift_mantissa
control<="000000000" when state_counter="000" else
		 "110010000" when state_counter="001" else --get operands and exponent
		 "000100000" when state_counter="010" else --shift the smaller mantissa right
		 "000000010" when state_counter="011" else --ld shifter for normalization
		 "000011101" when (state_counter="100" and ((mantissa_msb='0' and subtract='0')or(mantissa_msb_for_subtraction='0' and subtract='1'))) else --normalize by shifting left and decrementing exponent
		 "000010100" when (state_counter="101" and operands_arezero='0') else --increment exponent to avoid special case when there is overflow unless we have zero+zero
		 "000000001" when (state_counter="110") else --shift only exponent not affected
		 "000000000";

ld_larger<=control(8);
ld_smaller<=control(7);
shift_smaller<=control(6 downto 5);
ld_exponent<=control(4);
exponent_src<=control(3 downto 2);
ld_mantissa<=control(1);
shift_mantissa<=control(0);
end arch;