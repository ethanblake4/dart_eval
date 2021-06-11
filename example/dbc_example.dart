import 'package:dart_eval/src/dbc/dbc_gen.dart';

void main(List<String> args) {
  /*final abc = int.parse(args[0]);
*/
  /*
  final _program = <int>[
    Dbc.OP_SETVC,   0x00,0x00, 0x00,0xCF,0xF0,0x0F, // i #0
    Dbc.OP_SETVC,   0x00,0x01, 0x00,0x20,0x3A,0x4F, // a #4
    Dbc.OP_SETVC,   0x00,0x02, 0x00,0x00,0x00,0x00, // == 0
    Dbc.OP_MODVCS,  0x00,0x01, 0x00,0x00,0x00,3, // a %= 3
    Dbc.OP_SUBVCS,  0x00,0x00, 0x00,0x00,0x00,0x01, // i--
    Dbc.OP_CMPDDI,  0x00,0x00, 0x00,0x02,
    Dbc.OP_JNZ,     0x00,0x00,0x00,3,
    Dbc.OP_EXIT,    0x00,0x01,
  ];

  final l = Uint8List.fromList(_program);
  final bd = l.buffer.asByteData();

  final dt = DateTime.now().millisecondsSinceEpoch;
  DbcExecutor(bd).execute();
  print('pend ${DateTime.now().millisecondsSinceEpoch - dt}');

  final dta = DateTime.now().millisecondsSinceEpoch;
  var a = 1987654321;
  var abc = 3;
  for(var i = 0; i<13627407; i++) {
    a %= abc;
  }
  print(a);
  print('xend ${DateTime.now().millisecondsSinceEpoch - dta}');
/*
  final dta = DateTime.now().millisecondsSinceEpoch;
  var a = 1987654321;
  var abc = 3;
  for(var i = 0; i<13627407; i++) {
    a %= abc;
  }
  print(a);
  print('xend normal ${DateTime.now().millisecondsSinceEpoch - dta}');

  final dtt = DateTime.now().millisecondsSinceEpoch;
  var b = malloc.allocate<Int64>(8);
  b.value = 1987654321;

  var c = malloc.allocate<Int64>(8);
  c.value = 3;

  var i = malloc.allocate<Int64>(8);
  i.value = 0;

  var il = malloc.allocate<Int64>(8);
  il.value = 13627407;

  while (i.value < il.value) {
    b.value %= c.value;
    i.value++;
  }
  print(b.value);
  print('xend ffi ${DateTime.now().millisecondsSinceEpoch - dtt}');

  final dttf = DateTime.now().millisecondsSinceEpoch;
  var bf = malloc.allocate<Int64>(8);
  bf.value = 1987654321;

  var cf = malloc.allocate<Int64>(8);
  cf.value = 3;*/

/*

  var iyf = malloc.allocate<Int64>(8);
  iyf.value = 0;


  var ilf = malloc.allocate<Int64>(8);
  ilf.value = 13627407;

  final farr = <Pointer>[bf, cf, iyf, ilf];

  while ((farr[2] as Pointer<Int64>).value < (farr[3] as Pointer<Int64>).value) {
    (farr[0] as Pointer<Int64>).value %= (farr[1] as Pointer<Int64>).value;
    (farr[2] as Pointer<Int64>).value++;
  }
  print(farr[0].cast<Int64>().value);
  print('xend ffi2 ${DateTime.now().millisecondsSinceEpoch - dttf}');

  final dtab = DateTime.now().millisecondsSinceEpoch;
  final ab = <dynamic>[1987654321, 'hi'];
  final abcb = <dynamic>[3, 'hi'];
  final ib = <dynamic>[0, 'hi'];
  final cbcb = <dynamic>[13627407, 'hi'];
  while ((ib[0] as int) < (cbcb[0] as int)) {
    ab[0] = (ab[0] as int) % (abcb[0] as int);
    ib[0] = (ib[0] as int) + 1;
  }
  print(ab[0]);
  print('xend arr ${DateTime.now().millisecondsSinceEpoch - dtab}');

  final dtac = DateTime.now().millisecondsSinceEpoch;
  var ac = ByteData(8)..setInt64(0, 1987654321);
  var abcc = ByteData(8)..setInt64(0, 3);
  var ic = ByteData(8)..setInt64(0, 0);
  var cbcc = ByteData(8)..setInt64(0, 13627407);

  while (ic.getInt64(0) < cbcc.getInt64(0)) {
    ac.setInt64(0, ac.getInt64(0) % abcc.getInt64(0));
    ic.setInt64(0, ic.getInt64(0) + 1);
  }
  print(ac.getInt64(0));
  print('xend Int64list ${DateTime.now().millisecondsSinceEpoch - dtac}');
*/*/
  final gen = DbcGen();

  gen.generate('''
  int main() {
    var i = 3;
    var k = 2;
    k = i;
    return k;
  }
  ''');
}
