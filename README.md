# floating-point-unit-with-VHDL
This unit does floating point operations.It is almost compatible with IEEE 754 standard,the difference is that denormal numbers flushed to zero in this design.  
the fp_unit is the top level of the hierarchy, and it has a generic for supporting different length of mantissas,exponents as well as operand widths for for flexebility and modularity.
# floating point representation:
 It is a way of representing data that is similar to scientific notation.  
for example:  
 *125*   is the same as  *1.25 10^2*  
in binary the radix is 2 so the for mat is as follows:  
*1001*   is the same as 1.001 2^3  
We can notice that multiplying by 2 in base 2 is **effectively** the same as multiplying by 10 in base 10.  
The representation is as follows:  
1.[**mantissa**] 2^[exponent-**BIAS**]  
**mantissa**: is the fractional part 23 bits in 32 bit representation.
**exponent**: is stored in excess with bias to repreent positive and negative values of exponents.  
the leading one is always present when the numbers are normalized, if the number is not normalozed the the number is **denormal** or subnormal this is the case when the exponent is all zeroes.  
their reepresentation is as follows :  
0.mantissa 2^(-**min exponent**)  
The binary 32 floating point representation is as follows:  
sign eeeeeeee mmmmmmmmmmmmmmmmmmmmmmm  
When all exponents are 1s and the mantissa is zero then the number is **infinity**,
if the mantissa is non-zero then the operand is **NAN (not a number)** used for 0/0 and similar operations.
# The supported operations
OP CODE | OPERATION  
--------|-----------
000     | MULTIPLICATION  
001     | DEVISION  
010     | ADDITION  
011     | MAX  
100     | MIN   
101     | CONVERTION    

**PS** these operations do not support denormal numbers, this way be supported by software by additional code.  
This may lead to higher execution time since operations on denormal numbers may take more time(**up to hundreds of cycles**) but, it is still doable.
