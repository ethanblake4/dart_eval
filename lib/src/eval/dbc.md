# Op Codes

0. JumpConstant - Jump to constant position
   * Args:
      - position (i32) - Constant program offset
1. Exit - Exit program with value
   * Args:
      - location (i16) - Exit code stack offset
2. Unbox - Unbox boxed value and push
   * Args:
      - location (i16) - Boxed value stack offset
   * Push: (any) the unboxed value
3. PushReturnValue - Push the last return value onto the stack
   * No args
4. AddInts - Add two unboxed ints together and push
   * Args:
      - location1 (i16) - first int to add stack offset
      - location2 (i16) - second int to add stack offset
5. JumpIfNonZero - Jump to constant location if return register is non-zero
   * Args:
      - offset (i32) - Constant program offset
 
AddConstantToIntStored