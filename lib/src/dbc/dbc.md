# Op Codes

0. JumpConstant - Jump to constant position
   Args:
    - position (i32) - Constant program offset
1. Exit - Exit program with value
   Args:
    - location (i16) - Exit code stack offset
2. CompareInt - Compare integers
   Args:
    - location1 (i16) - First int stack offset
    - location2 (i16) - Second int stack offset
   Return: (i16) 0 if equal, positive if 1 is greater, negative if 2 is greater
3. SetReturnValue - Set value to return register
   Args: 
    - location (i16) - value stack offset
4. AddIntsAndReturn - Add two values together and store the result in the return register
   Args:
    - location1 (i16) - first value to add stack offset
    - location1 (i16) - second value to add stack offset
5. JumpIfNonZero - Jump to constant location if return register is non-zero
   Args:
    - offset (i32) - Constant program offset
 
AddConstantToIntStored