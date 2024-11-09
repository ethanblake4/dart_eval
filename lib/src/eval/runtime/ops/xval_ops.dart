/*
%a -> alu acc, %b -> alu 2
%l -> loop counter
%f -> fpu acc, %g -> fpu 2
%u -> string acc, %v -> string 2
%e -> bool / flag, %x -> bool 2
%r -> gpr1/acc, %s -> gpr2, %c -> gpr3 / collection
*/
class Xops {
  static const int i16Max = 0x7fff;
  static const int i16Half = 0x4000;

/*
jump
ret
try @offset
popcatch @offset
finally @tryOffset
call @offset
tailcall @offset
pushnullargs (u8 count)
fillnullargs (u8 count)
pop n
movs Sx Sx
newbr -> %r
newbss -> %c
parentbss
newcls %r (super %c)
newcls %c (super %c)
lg -> %s
lc %r
lc %s
lcf %f
lcf %g
lcs %u
lcs %v
jf %e
jt %e
jnn %r
jnn %s
jn %r
jn %s
push %a
push %b
push %f
push %g
push %e
push %r
push %s
push %c
push %u
load %a *Sx
load %b *Sx
load %f *Sx
load %g *Sx
load %r *Sx
load %s *Sx
load %c *Sx
load %u *Sx
load %v *Sx
load %e *Sx
load %x *Sx
save %a *Sx
save %f *Sx
save %r *Sx
save %s *Sx
save %c *Sx
save %u *Sx
save %e *Sx
imm %a i16
imm %b i16
imm %l i16
mov %ab
mov %ra
mov %sa
mov %rb
mov %sb
mov %rf
mov %sf
mov %ar
mov %sr
mov %as
mov %fr
mov %fs
mov %er
mov %es
mov %ur
swap %ab
swap %er
swap %rs
swap %ex
swap %fg
ltrue %e
lfalse %e
ltrue %x
lfalse %x
lnull %r
lnull %s
lnull %c
ineg %a
ineg %b
fneg %f
fneg %g
nneg %r
bnot %e
bnot %x
unbox %r
unbox %s
unboxs %r -> %u
unboxi %r -> %a
unboxf %r -> %f
box %r [3bit type][5bit *Sx?]
box %s [3bit type][5bit *Sx?]
invokexf %ar imm24 [6bit box, 18-bit idx]
invokexf %fr imm24 [6bit box, 18-bit idx]
invokexf %er imm24 [6bit box, 18-bit idx]
invokexf %rs imm24 [6bit box, 18-bit idx]
istype %r u16 -> %e
istype %s u16 -> %e
istype %c u16 -> %e
istypej %r u16 @target
istypej %s u16 @target
istypej %c u16 @target
newmap %c
newlist %c
newset %c
mapset %c[%s] = %r
mapset %c[%r] = %s
mapset %c[%u] = %r
mapset %c[%u] = %a
listset %c[%s] = %r
listset %c[%a] = %r
listset %c[%a] = %s
setadd %c [box] = %r
setadd %c [box] = %s
setadd %c [box] = %a
setcontains %c %r
listappend %c %r
listappend %c %s
listindex %r = %c[%a]
listindex %s = %c[%a]
mapindex %r = %c[%s]
mapindex %s = %c[%r]
eq %r %s -> %e
eq %r %s -> %x
band %e %x
bor %e %x
beq %e %x
lpropi %r [u8] -> %r
lpropi %c [u8] -> %s
lpropi %r [u8] -> %a
lpropi %c [u8] -> %a
lpropi %r [u8] -> %f
lpropi %c [u8] -> %f
lpropi %r [u8] -> %e
lpropi %c [u8] -> %e
lpropi %r [u8] -> %u
lpropi %c [u8] -> %u
spropi %r [u8] = %s
spropi %r [u8] = %a
spropi %r [u8] = %f
spropi %r [u8] = %e
spropi %r [u8] = %u
spropi %c [u8] = %r
spropi %c [u8] = %a
spropi %c [u8] = %f
spropi %c [u8] = %e
spropi %c [u8] = %u
super %r -> %r
super %r -> %c
super %c -> %c
iinc %a
iinc %l
idec %l
itoa %a -> %u
itoa %a -> %v
add %a %b
add %a imm
add %l imm
sub %a %b
sub %b %a
sub %a imm
mul %a %b
mul %a imm
div %a %b -> %f
idiv %a %b
idiv %b %a
ilt %a %b -> %e
ilt %a %b -> %x
iltj %l %a
ilteq %a %b -> %e
ilteq %a %b -> %x
ilteqj %l %a
igt %a %b -> %e
igt %a %b -> %x
igtj %l %a
igteq %a %b -> %e
igteq %a %b -> %x
igteqj %l %a
ieq %a %b -> %e
ieq %a %b -> %x
ineq %a %b -> %e
ineq %a %b -> %x
iand %a %b
iand %a imm
ior %a %b
ior %a imm
ixor %a %b
ixor %a imm
imod %a %b
imod %a imm
ishl %a %b
ishl %a imm
ishr %a %b
ishr %a imm
dadd %f %g
dsub %f %g
dsub %g %f
dmul %f %g
ddiv %f %g
ddiv %g %f
dtoa %f -> %v
dlt %f %g -> %e
dlt %f %g -> %x
dlteq %f %g -> %e
dlteq %f %g -> %x
deq %f %g -> %e
deq %f %g -> %x
pushargb %a
pushargb %f
pushargb %u
pushargb %r
pushargb %s
pushargb %e
sgl %r Gx
tostring %r -> %u
tostring %s -> %u
tostring %c -> %u
tostring %r -> %v
tostring %s -> %v
tostring %c -> %v
concat %uv -> %u
concat %ur -> %u
strlen %u -> %a
strlen %u -> %b
switch %a
switch %f
switch %u
switch %r
switch %s
*/

  static const int jump = 0;
  static const int ret = 1;
  static const int try_ = 2;
  static const int popcatch = 3;
  static const int finally_ = 4;
  static const int call = 5;
  static const int tailcall = 6;
  static const int pushnullargs = 7;
  static const int fillnullargs = 8;
  static const int pop = 9;
  static const int movs = 10;
  static const int newbr = 11;
  static const int newbss = 12;
  static const int parentbss = 13;
  static const int newcls0 = 14;
  static const int newcls1 = 15;
  static const int lg = 16;
  static const int lc0 = 17;
  static const int lc1 = 18;
  static const int lcf0 = 19;
  static const int lcf1 = 20;
  static const int lcs0 = 21;
  static const int lcs1 = 22;
  static const int jf = 23;
  static const int jt = 24;
  static const int jnn0 = 25;
  static const int jnn1 = 26;
  static const int jn0 = 27;
  static const int jn1 = 28;
  static const int push0 = 29;
  static const int push1 = 30;
  static const int push2 = 31;
  static const int push3 = 32;
  static const int push4 = 33;
  static const int push5 = 34;
  static const int push6 = 35;
  static const int push7 = 36;
  static const int push8 = 174;
  static const int load0 = 37;
  static const int load1 = 38;
  static const int load2 = 39;
  static const int load3 = 40;
  static const int load4 = 41;
  static const int load5 = 42;
  static const int load6 = 43;
  static const int load7 = 44;
  static const int load8 = 45;
  static const int load9 = 46;
  static const int load10 = 47;
  static const int save0 = 48;
  static const int save1 = 49;
  static const int save2 = 50;
  static const int save3 = 51;
  static const int save4 = 52;
  static const int save5 = 53;
  static const int save6 = 54;
  static const int imm0 = 55;
  static const int imm1 = 56;
  static const int imm2 = 57;
  static const int mov0 = 58;
  static const int mov1 = 59;
  static const int mov2 = 60;
  static const int mov3 = 61;
  static const int mov4 = 62;
  static const int mov5 = 63;
  static const int mov6 = 64;
  static const int mov7 = 65;
  static const int mov8 = 66;
  static const int mov9 = 67;
  static const int mov10 = 68;
  static const int mov11 = 69;
  static const int mov12 = 70;
  static const int mov13 = 71;
  static const int mov14 = 72;
  static const int mov15 = 73;
  static const int swap0 = 74;
  static const int swap1 = 75;
  static const int swap2 = 76;
  static const int swap3 = 77;
  static const int swap4 = 78;
  static const int swap5 = 79;
  static const int ltrue0 = 80;
  static const int ltrue1 = 81;
  static const int lfalse0 = 82;
  static const int lfalse1 = 83;
  static const int lnull0 = 84;
  static const int lnull1 = 85;
  static const int ineg0 = 86;
  static const int ineg1 = 87;
  static const int fneg0 = 88;
  static const int fneg1 = 89;
  static const int nneg0 = 90;
  static const int bnot0 = 91;
  static const int bnot1 = 92;
  static const int unbox0 = 93;
  static const int unbox1 = 94;
  static const int unboxs = 95;
  static const int unboxi = 96;
  static const int unboxf = 97;
  static const int box0 = 98;
  static const int box1 = 99;
  static const int invokexf0 = 100;
  static const int invokexf1 = 101;
  static const int invokexf2 = 102;
  static const int invokexf3 = 103;
  static const int istype0 = 104;
  static const int istype1 = 105;
  static const int istype2 = 106;
  static const int istypej0 = 107;
  static const int istypej1 = 108;
  static const int istypej2 = 109;
  static const int newmap = 110;
  static const int newlist = 111;
  static const int newset = 112;
  static const int mapset0 = 113;
  static const int mapset1 = 114;
  static const int mapset2 = 115;
  static const int mapset3 = 116;
  static const int listset0 = 117;
  static const int listset1 = 118;
  static const int listset2 = 119;
  static const int setadd0 = 120;
  static const int setadd1 = 121;
  static const int setadd2 = 122;
  static const int setcontains = 123;
  static const int listappend0 = 124;
  static const int listappend1 = 125;
  static const int listindex0 = 126;
  static const int listindex1 = 127;
  static const int mapindex0 = 128;
  static const int mapindex1 = 129;
  static const int eq0 = 130;
  static const int eq1 = 131;
  static const int eq2 = 132;
  static const int band = 133;
  static const int bor = 134;
  static const int beq = 135;
  static const int lpropi0 = 136;
  static const int lpropi1 = 137;
  static const int lpropi2 = 138;
  static const int lpropi3 = 139;
  static const int lpropi4 = 140;
  static const int lpropi5 = 141;
  static const int lpropi6 = 142;
  static const int lpropi7 = 143;
  static const int lpropi8 = 144;
  static const int lpropi9 = 145;
  static const int spropi0 = 146;
  static const int spropi1 = 147;
  static const int spropi2 = 148;
  static const int spropi3 = 149;
  static const int spropi4 = 150;
  static const int spropi5 = 151;
  static const int spropi6 = 152;
  static const int spropi7 = 153;
  static const int spropi8 = 154;
  static const int spropi9 = 155;
  static const int super0 = 156;
  static const int super1 = 157;
  static const int super2 = 158;
  static const int iinc0 = 159;
  static const int iinc1 = 160;
  static const int idec = 161;
  static const int itoa0 = 162;
  static const int itoa1 = 163;
  static const int add0 = 164;
  static const int add1 = 165;
  static const int add2 = 166;
  static const int sub0 = 167;
  static const int sub1 = 168;
  static const int sub2 = 169;
  static const int mul0 = 170;
  static const int mul1 = 171;
  static const int div0 = 172;
  static const int div1 = 173;
  // 174 is push8
}
