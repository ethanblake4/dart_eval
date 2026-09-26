import 'support/comparison.dart';

// Classify document requests from packed audit records by tenant, role,
// ownership, expiry, account state, and risk.
// dart compile exe benchmark/access_policy.dart -o .dart_tool/access-policy-baseline.exe
// .dart_tool/access-policy-baseline.exe [requests] [samples]
const _source = r'''
int main(int requests) {
  final principals = List<int>.filled(requests, 0);
  final resources = List<int>.filled(requests, 0);
  var state = 123456789;
  for (var i = 0; i < requests; i++) {
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    principals[i] = state;
    state = (state * 1103515245 + 12345) & 0x7fffffff;
    resources[i] = state;
  }

  const now = 1120;
  var allowedCount = 0;
  var reviewCount = 0;
  var deniedCount = 0;
  var policyScore = 0;
  for (var i = 0; i < requests; i++) {
    final principal = principals[i];
    final resource = resources[i];
    final tenant = (principal >> 8) & 7;
    final resourceTenant = ((resource >> 5) & 3) == 0
        ? (tenant + 1) & 7
        : tenant;
    final user = (principal >> 11) & 127;
    final owner = ((resource >> 3) & 7) == 0
        ? user
        : (resource >> 11) & 127;
    final role = (principal >> 18) & 3;
    final risk = (principal >> 20) % 100;

    final sameTenant = tenant == resourceTenant;
    final ownsDocument = user == owner;
    final roleGrants = role >= 2 || (role == 1 && ownsDocument);
    final verified = (resource & 0x08000000) != 0;
    final suspended = (resource & 0x70000000) == 0x70000000;
    final active = now < 1000 + ((resource >> 8) & 255);
    final safe = risk < 65 || (verified && risk < 80);
    final allow = sameTenant && active && roleGrants && safe && !suspended;
    final review = sameTenant && active && roleGrants && !suspended &&
        !allow && (verified || risk < 90);

    if (allow) {
      allowedCount++;
      policyScore += 200 - risk;
    } else if (review) {
      reviewCount++;
      policyScore += 100 - risk;
    } else {
      deniedCount++;
      policyScore -= risk + 1;
    }
  }
  return policyScore + allowedCount * 1000003 + reviewCount * 1009 + deniedCount;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'access_policy',
  source: _source,
  parameter: 'requests',
  unit: 'request',
  iterations: 200000,
  warmupIterations: 1000,
);
