# floating-point-unit-with-VHDL:
This unit does floating point operations.It is almost compatible with IEEE 754 standard,the difference is that denormal numbers flushed 
to zero in this design.  
The fp_unit is the top level of the hierarchy, and it has a generic for supporting different length of mantissas,exponents as well as 
operand widths for for flexebility and modularity.  
Code is written for **VHDL2008**.  
SPECIAL THANKS FOR THE YOUTUBE PLAYLIST "BUILDING AN FPU IN VERILOG" FROM CRISS LARSEN(@FPUniversity), the videos are very clear and 
go indepth to how the floating point operations are done.  
# floating point representation:
 It is a way of representing data that is similar to scientific notation.  
for example:  
 *125*   is the same as  *1.25 10^2*  
In binary the radix is 2 so the for mat is as follows:  
*1001*   is the same as 1.001 2^3  
We can notice that multiplying by 2 in base 2 is **effectively** the same as multiplying by 10 in base 10.  
The representation is as follows:  
1.[**mantissa**] 2^[exponent-**BIAS**]  
**mantissa**: is the fractional part 23 bits in 32 bit representation.
**exponent**: is stored in excess with bias to repreent positive and negative values of exponents.  
The leading one is always present when the numbers are normalized, if the number is not normalozed the the number is **denormal** or subnormal this is the case when the exponent is all zeroes.  
Their reepresentation is as follows :  
0.mantissa 2^(-**min exponent**)  
The binary 32 floating point representation is as follows:  
sign eeeeeeee mmmmmmmmmmmmmmmmmmmmmmm  
When all exponents are 1s and the mantissa is zero then the number is **infinity**,
If the mantissa is non-zero then the operand is **NAN (not a number)** used for 0/0 and similar operations.
# Code structure:
Floating point operations could be done alone without the top level design, but the do not come with the detection of infinity or zero.  
This means for example:dividing 0 by 0 would yield a wrong result instead of NAN, so additional code must be written.  
Mostly these operations need normalization so we need loops especially non-parallel operations as division, each quotient needs to be computed after the previous quotient and so on,
this means that we need to test values for normalization each clock cycle.  
For-loops are quite special in VHDL especially with std_logic signals, these signals update after the loop ends which may lead to unsynthesisable code, hence each unit has its control 
unit that takes care of the normalization process.  
The generics provide means to use the unit for 64-bit floeating point representation or even a custom made one. you just need to 
give it the operand , mantissa and exponent lengths. If the fields do not add up to the operand's width then the program will 
throw an error.  
This module operates on upto **127Mhz** on altera's quartusII 13 software(CycloneII with balenced settings), and consumes **1229 logic elements** and **356 registers**. 
# The supported operations:
OP CODE | OPERATION  
--------|-----------
0000     | MULTIPLICATION  
0001     | DEVISION  
0010     | ADDITION  
0011     | MAX  
0100     | MIN   
0101     | CONV SIGNED INT TO FLOAT    
0110     | CONV FLOAT TO SIGNED INT
0111     | TAKE ABSOLUTE VALUE
1000     | MAKE NEGATIVE  

**PS** these operations do not support denormal numbers, this way be supported by software by additional code.  
This may lead to higher execution time since operations on denormal numbers may take more time(**up to hundreds of cycles**) but, it is still doable.
