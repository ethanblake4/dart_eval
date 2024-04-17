class Xops {
  static const int i16Max = 0x7fff;
  static const int i16Half = 0x4000;

/*
scope
asyncscope
popscope
lc0
lc1
lc0boxs
lc1boxs
lc0p
lc1p
lcf0
lcf1
lcd0
lcd1
lcf0box
lcf1box
lcf0p
lcf1p
lci0
lci1
lci0p
lci1p
lcl0
lcl1
ls0
ls1
lprop0i
lprop1i
jump
jumpf
jumpt
jumpnnil
push0
push1
push2
sets0
sets1
lii0
lii1
lii0b
lii1b
lii0p
lii1p
lii0bp
lii1bp
ltrue0
ltrue1
lfalse0
lfalse1
ltrue0b
ltrue1b
lfalse0b
lfalse1b
lnull0
lnull1
lnull0b
lnull1b
lctype0
lctype1
ltrue0p
ltrue1p
lfalse0p
lfalse1p
lnull0p
lnull1p
ltrue0bp
ltrue1bp
lfalse0bp
lfalse1bp
lnull0bp
lnull1bp
swap01
swap12
swap02
dup0
dup1
lg0
sg0
isp
iadd
iadds
iaddsp
iinc0
iinc1
isinc
isub
isubs
isubsp
imul
imuls
imulsp
idiv
idivs
idivsp
iidiv
iidivs
iidivsp
ilt
iltj
ilteq
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
dadds
daddsp
dsub
dsubs
dsubsp
dmul
dmuls
dmulsp
ddiv
ddivs
ddivsp
dlt
dltj
dlteq
dlteqj
deq
deqj
dmod
dtoa
nadd
nadds
naddsp
nsub
nsubs
nsubsp
nmul
nmuls
nmulsp
nidiv
nidivs
nidivsp
ndiv
ndivs
ndivsp
nneg0
nneg1
nnegs
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
beqs
beqsj
beqsp
bneqj
bneqsj
band
bor
unbox0
unbox1
boxi0
boxd0
boxn0
boxs0
boxb0
boxl0
boxm0
boxnilq0
boxi1
boxd1
boxn1
boxs1
boxb1
boxl1
boxm1
boxnilq1
newcls
newbr
newbss
linkbss
call
wcall
tailcall
wtailcall
invoke
invokex
invokex1
lprop0
lprop1
pop
ret
retc
retf
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
mapremove
mapcontainskey
newset
setadd
setcontains
setremove
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
typeof1
strlen
strlens
concat
concats
eq
eqj
neqj
tostring
hashcode
index
pusharg0
pusharg1
pushargs
switch
*/

  static const int scope = 0x00;
  static const int asyncscope = 0x01;
  static const int popscope = 0x02;
  static const int lc0 = 0x03;
  static const int lc1 = 0x04;
  static const int lc0boxs = 0x05;
  static const int lc1boxs = 0x06;
  static const int lc0p = 0x07;
  static const int lc1p = 0x08;
  static const int lcf0box = 0x09;
  static const int lcf1box = 0x0a;
  static const int lcf0p = 0x0b;
  static const int lcf1p = 0x0c;
  static const int ls0 = 0x0d;
  static const int ls1 = 0x0e;
  static const int lprop0i = 0x0f;
  static const int lprop1i = 0x10;
  static const int jump = 0x11;
  static const int jumpf = 0x12;
  static const int jumpt = 0x13;
  static const int jumpnnil = 0x14;
  static const int push0 = 0x15;
  static const int push1 = 0x16;
  static const int sets0 = 0x17;
  static const int sets1 = 0x18;
  static const int lii0 = 0x19;
  static const int lii1 = 0x1a;
  static const int lii0b = 0x1b;
  static const int lii1b = 0x1c;
  static const int lii0p = 0x1d;
  static const int lii1p = 0x1e;
  static const int lii0bp = 0x1f;
  static const int lii1bp = 0x20;
  static const int ltrue0 = 0x21;
  static const int ltrue1 = 0x22;
  static const int lfalse0 = 0x23;
  static const int lfalse1 = 0x24;
  static const int ltrue0b = 0x25;
  static const int ltrue1b = 0x26;
  static const int lfalse0b = 0x27;
  static const int lfalse1b = 0x28;
  static const int lnull0 = 0x29;
  static const int lnull1 = 0x2a;
  static const int lnull0b = 0x2b;
  static const int lnull1b = 0x2c;
  static const int lctype0 = 0x2d;
  static const int lctype1 = 0x2e;
  static const int ltrue0p = 0x2f;
  static const int ltrue1p = 0x30;
  static const int lfalse0p = 0x31;
  static const int lfalse1p = 0x32;
  static const int lnull0p = 0x33;
  static const int lnull1p = 0x34;
  static const int ltrue0bp = 0x35;
  static const int ltrue1bp = 0x36;
  static const int lfalse0bp = 0x37;
  static const int lfalse1bp = 0x38;
  static const int lnull0bp = 0x39;
  static const int lnull1bp = 0x3a;
  static const int swap01 = 0x3b;
  static const int swap12 = 0x3c;
  static const int swap02 = 0x3d;
  static const int dup0 = 0x3e;
  static const int dup1 = 0x3f;
  static const int lg0 = 0x40;
  static const int sg0 = 0x41;
  static const int isp = 0x42;
  static const int iadd = 0x43;
  static const int iadds = 0x44;
  static const int iaddsp = 0x45;
  static const int iinc0 = 0x46;
  static const int iinc1 = 0x47;
  static const int isinc = 0x48;
  static const int isub = 0x49;
  static const int isubs = 0x4a;
  static const int isubsp = 0x4b;
  static const int imul = 0x4c;
  static const int imuls = 0x4d;
  static const int imulsp = 0x4e;
  static const int idiv = 0x4f;
  static const int idivs = 0x50;
  static const int idivsp = 0x51;
  static const int iidiv = 0x52;
  static const int iidivs = 0x53;
  static const int iidivsp = 0x54;
  static const int ilt = 0x55;
  static const int iltj = 0x56;
  static const int ilteq = 0x57;
  static const int ilteqj = 0x58;
  static const int ieq = 0x59;
  static const int ieqj = 0x5a;
  static const int iand = 0x5b;
  static const int ior = 0x5c;
  static const int ixor = 0x5d;
  static const int imod = 0x5e;
  static const int ishl = 0x5f;
  static const int ishr = 0x60;
  static const int itoa = 0x61;
  static const int dadd = 0x62;
  static const int dadds = 0x63;
  static const int daddsp = 0x64;
  static const int dsub = 0x65;
  static const int dsubs = 0x66;
  static const int dsubsp = 0x67;
  static const int dmul = 0x68;
  static const int dmuls = 0x69;
  static const int dmulsp = 0x6a;
  static const int ddiv = 0x6b;
  static const int ddivs = 0x6c;
  static const int ddivsp = 0x6d;
  static const int dlt = 0x6e;
  static const int dltj = 0x6f;
  static const int dlteq = 0x70;
  static const int dlteqj = 0x71;
  static const int deq = 0x72;
  static const int deqj = 0x73;
  static const int dmod = 0x74;
  static const int dtoa = 0x75;
  static const int nadd = 0x76;
  static const int nadds = 0x77;
  static const int naddsp = 0x78;
  static const int nsub = 0x79;
  static const int nsubs = 0x7a;
  static const int nsubsp = 0x7b;
  static const int nmul = 0x7c;
  static const int nmuls = 0x7d;
  static const int nmulsp = 0x7e;
  static const int nidiv = 0x7f;
  static const int nidivs = 0x80;
  static const int nidivsp = 0x81;
  static const int ndiv = 0x82;
  static const int ndivs = 0x83;
  static const int ndivsp = 0x84;
  static const int nneg0 = 0x85;
  static const int nneg1 = 0x86;
  static const int nnegs = 0x87;
  static const int nlt = 0x88;
  static const int nltj = 0x89;
  static const int nlteq = 0x8a;
  static const int nlteqj = 0x8b;
  static const int numeq = 0x8c;
  static const int numeqj = 0x8d;
  static const int nmod = 0x8e;
  static const int ntoa = 0x8f;
  static const int bnot = 0x90;
  static const int beq = 0x91;
  static const int beqj = 0x92;
  static const int beqs = 0x93;
  static const int beqsj = 0x94;
  static const int beqsp = 0x95;
  static const int bneqj = 0x96;
  static const int bneqsj = 0x97;
  static const int band = 0x98;
  static const int bor = 0x99;
  static const int unbox0 = 0x9a;
  static const int unbox1 = 0x9b;
  static const int boxi0 = 0x9c;
  static const int boxd0 = 0x9d;
  static const int boxn0 = 0x9e;
  static const int boxs0 = 0x9f;
  static const int boxb0 = 0xa0;
  static const int boxl0 = 0xa1;
  static const int boxm0 = 0xa2;
  static const int boxnilq0 = 0xa3;
  static const int boxi1 = 0xa4;
  static const int boxd1 = 0xa5;
  static const int boxn1 = 0xa6;
  static const int boxs1 = 0xa7;
  static const int boxb1 = 0xa8;
  static const int boxl1 = 0xa9;
  static const int boxm1 = 0xaa;
  static const int boxnilq1 = 0xab;
  static const int newcls = 0xac;
  static const int newbr = 0xad;
  static const int newbss = 0xae;
  static const int linkbss = 0xaf;
  static const int call = 0xb0;
  static const int wcall = 0xb1;
  static const int tailcall = 0xb2;
  static const int wtailcall = 0xb3;
  static const int invoke = 0xb4;
  static const int invokex = 0xb5;
  static const int invokex1 = 0xb6;
  static const int lprop0 = 0xb7;
  static const int lprop1 = 0xb8;
  static const int pop = 0xb9;
  static const int ret = 0xba;
  static const int retc = 0xbb;
  static const int retasync = 0xbc;
  static const int retcasync = 0xbd;
  static const int newlist = 0xbe;
  static const int itlen = 0xbf;
  static const int listset = 0xc0;
  static const int listappend = 0xc1;
  static const int listindex = 0xc2;
  static const int listaddall = 0xc3;
  static const int newmap = 0xc4;
  static const int mapset = 0xc5;
  static const int mapindex = 0xc6;
  static const int newfuncptr = 0xc7;
  static const int await = 0xc8;
  static const int istype = 0xc9;
  static const int istypej = 0xca;
  static const int try_ = 0xcb;
  static const int throw_ = 0xcc;
  static const int popcatch = 0xcd;
  static const int assert_ = 0xce;
  static const int finally_ = 0xcf;
  static const int typeof0 = 0xd0;
  static const int typeof1 = 0xd1;
  static const int strlen = 0xd2;
  static const int strlens = 0xd3;
  static const int concat = 0xd4;
  static const int concats = 0xd5;
  static const int eq = 0xd6;
  static const int eqj = 0xd7;
  static const int neqj = 0xd8;
  static const int tostring = 0xd9;
  static const int index = 0xda;
  static const int pusharg0 = 0xdb;
  static const int pusharg1 = 0xdc;
  static const int pushargs = 0xdd;
  static const int switch_ = 0xde;
  static const int retf = 0xdf;
  static const int mapremove = 0xe0;
  static const int mapcontainskey = 0xe1;
  static const int newset = 0xe2;
  static const int setadd = 0xe3;
  static const int setcontains = 0xe4;
  static const int setremove = 0xe5;
  static const int hashcode = 0xe6;
  static const int push2 = 0xe7;
  static const int lci0 = 0xe8;
  static const int lci1 = 0xe9;
  static const int lcl0 = 0xea;
  static const int lcl1 = 0xeb;
  static const int lcf0 = 0xec;
  static const int lcf1 = 0xed;
  static const int lcd0 = 0xee;
  static const int lcd1 = 0xef;
  static const int lci0p = 0xf0;
  static const int lci1p = 0xf1;
  static const int nop = 0xff;
}
