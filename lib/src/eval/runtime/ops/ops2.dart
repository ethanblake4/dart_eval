class Ops {
  static const i16Max = 0x7fff;

  /*
scope
asyncscope
popscope
pushc
pushcboxstr
pushprop
jump
jumpf
jumpnnull
copy
copytop
pushii
pushiibox
pushid
pushidbox
pushtrue
pushtruebox
pushfalse
pushfalsebox
pushnull
pushctype
pushret
swap
pushglobal
setglobal
incsp
iadd
iinc
isub
imul
idiv
ilt
ilteq
iltj
ilteqj
ieq
ieqj
iand
ior
ixor
imod
ishl
ishr
itoa
dadd
dsub
dmul
ddiv
dlt
dltj
dlteq
dlteqj
deq
deqj
dmod
dtoa
nadd
nsub
nmul
nidiv
ndiv
nneg
nlt
nltj
nlteq
nlteqj
numeq
numeqj
nmod
ntoa
bnot
beq
beqj
bneqj
band
bor
unbox
boxi
boxd
boxn
boxs
boxb
boxl
boxm
boxnullq
newcls
newbridge
newshim
linkshim
call
wcall
invoke
invokeexternal
invokesm
invokeexternalsm
invokethis
invokethissm
pop
ret
retc
retasync
retcasync
newlist
itlen
listset
listappend
listindex
listaddall
newmap
mapset
mapindex
newfuncptr
await
istype
istypej
try
throw
popcatch
assert
finally
typeof0
strlen
concat
eq
eqj
neqj
tostring
index
pusharg
*/

  /// Push a scope frame
  static const scope = 0x00;

  /// Push an async scope frame
  static const asyncscope = 0x01;

  /// Pop a scope frame
  static const popscope = 0x02;

  /// Push a constant
  static const pushc = 0x03;

  /// Push a constant and box as string
  static const pushcboxstr = 0x04;

  /// Push a property
  static const pushprop = 0x05;

  /// Jump (constant) to address
  static const jump = 0x06;

  /// Jump (constant) to address if false
  static const jumpf = 0x07;

  /// Jump (constant) to address if non-null
  static const jumpnnull = 0x08;

  /// Copy a value
  static const copy = 0x09;

  /// Copy the top value
  static const copytop = 0x0a;

  /// Push immediate 16-bit integer
  static const pushii = 0x0b;

  /// Push immediate 16-bit integer and box
  static const pushiibox = 0x0c;

  /// Push immediate 16-bit float
  static const pushid = 0x0d;

  /// Push immediate 16-bit float and box
  static const pushidbox = 0x0e;

  /// Push true
  static const pushtrue = 0x0f;

  /// Push true and box
  static const pushtruebox = 0x10;

  /// Push false
  static const pushfalse = 0x11;

  /// Push false and box
  static const pushfalsebox = 0x12;

  /// Push null
  static const pushnull = 0x13;

  /// Push constant type
  static const pushctype = 0x14;

  /// Push return value
  static const pushret = 0x15;

  /// Swap the top two values
  static const swap = 0x16;

  /// Push a global variable
  static const pushglobal = 0x17;

  /// Set a global variable
  static const setglobal = 0x18;

  /// Increment the stack pointer
  static const incsp = 0x19;

  /// Add two integers
  static const iadd = 0x1a;

  /// Increment an integer
  static const iinc = 0x1b;

  /// Subtract two integers
  static const isub = 0x1c;

  /// Multiply two integers
  static const imul = 0x1d;

  /// Divide two integers
  static const idiv = 0x1e;

  /// Compare two integers a < b
  static const ilt = 0x1f;

  /// Compare two integers and jump if less than
  static const iltj = 0x20;

  /// Compare two integers a <= b
  static const ilteq = 0x21;

  /// Compare two integers and jump if less than or equal
  static const ilteqj = 0x22;

  /// Compare two integers for equality
  static const ieq = 0x23;

  /// Compare two integers for equality and jump if equal
  static const ieqj = 0x24;

  /// Bitwise AND two integers
  static const iand = 0x25;

  /// Bitwise OR two integers
  static const ior = 0x26;

  /// Bitwise XOR two integers
  static const ixor = 0x27;

  /// Modulus of two integers
  static const imod = 0x28;

  /// Shift left two integers
  static const ishl = 0x29;

  /// Shift right two integers
  static const ishr = 0x2a;

  /// Convert an integer to a string
  static const itoa = 0x2b;

  /// Add two doubles
  static const dadd = 0x2c;

  /// Subtract two doubles
  static const dsub = 0x2d;

  /// Multiply two doubles
  static const dmul = 0x2e;

  /// Divide two doubles
  static const ddiv = 0x2f;

  /// Compare two doubles a < b
  static const dlt = 0x30;

  /// Compare two doubles and jump if less than
  static const dltj = 0x31;

  /// Compare two doubles a <= b
  static const dlteq = 0x32;

  /// Compare two doubles and jump if less than or equal
  static const dlteqj = 0x33;

  /// Compare two doubles for equality
  static const deq = 0x34;

  /// Compare two doubles for equality and jump if equal
  static const deqj = 0x35;

  /// Modulus of two doubles
  static const dmod = 0x36;

  /// Convert a double to a string
  static const dtoa = 0x37;

  /// Add two numbers
  static const nadd = 0x38;

  /// Subtract two numbers
  static const nsub = 0x39;

  /// Multiply two numbers
  static const nmul = 0x3a;

  /// Integer divide two numbers
  static const nidiv = 0x3b;

  /// Divide two numbers
  static const ndiv = 0x3c;

  /// Negate a number
  static const nneg = 0x3d;

  /// Compare two numbers a < b
  static const nlt = 0x3e;

  /// Compare two numbers and jump if less than
  static const nltj = 0x3f;

  /// Compare two numbers a <= b
  static const nlteq = 0x40;

  /// Compare two numbers and jump if less than or equal
  static const nlteqj = 0x41;

  /// Compare two numbers for equality
  static const numeq = 0x42;

  /// Compare two numbers for equality and jump if equal
  static const numeqj = 0x43;

  /// Modulus of two numbers
  static const nmod = 0x44;
}
