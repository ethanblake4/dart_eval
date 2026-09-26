import 'support/comparison.dart';

// Validate service manifests with nested routes and optional metadata.
// dart compile exe benchmark/config_validation.dart -o .dart_tool/config-baseline.exe
// .dart_tool/config-baseline.exe [batches] [samples]
const _source = r'''
class ConfigError implements Exception {
  ConfigError(this.path, this.reason);
  final String path;
  final String reason;
}

class Route {
  Route(this.path, this.target);
  final String path;
  final String target;

  int get score => path.length * 11 + target.length * 7;
}

class ServiceConfig {
  ServiceConfig(this.name, this.host, this.port, {
    required this.enabled,
    required this.retries,
    required this.owner,
    required this.tags,
    required this.routes,
  });
  final String name;
  final String host;
  final int port;
  final bool enabled;
  final int retries;
  final String owner;
  final List<String> tags;
  final List<Route> routes;

  int get score {
    var total = name.length * 3 + host.length + port + retries * 5 +
        owner.length + (enabled ? 17 : 0);
    for (final tag in tags) {
      total += tag.length * 13;
    }
    for (final route in routes) {
      total += route.score;
    }
    return total;
  }
}

Map<String, Object?> requireMap(Object? value, String path) {
  if (value is! Map<String, Object?>) throw ConfigError(path, 'type');
  return value;
}

String requireString(Map<String, Object?> values, String key, String path) {
  final value = values[key];
  if (value is! String || value.isEmpty) throw ConfigError(path, 'string');
  return value;
}

int requireInt(Map<String, Object?> values, String key, String path) {
  final value = values[key];
  if (value is! int) throw ConfigError(path, 'integer');
  return value;
}

Route parseRoute(Object? raw, String path) {
  final values = requireMap(raw, path);
  final routePath = requireString(values, 'path', '$path.path');
  if (!routePath.startsWith('/')) throw ConfigError('$path.path', 'absolute');
  final target = requireString(values, 'target', '$path.target');
  return Route(routePath, target);
}

ServiceConfig validate(Object? raw) {
  final values = requireMap(raw, 'service');
  final name = requireString(values, 'name', 'service.name');
  final host = requireString(values, 'host', 'service.host');
  final port = requireInt(values, 'port', 'service.port');
  if (port < 1 || port > 65535) throw ConfigError('service.port', 'range');

  final enabledValue = values['enabled'];
  if (enabledValue != null && enabledValue is! bool) {
    throw ConfigError('service.enabled', 'boolean');
  }
  final enabled = enabledValue == null ? true : enabledValue as bool;

  final retriesValue = values['retries'];
  if (retriesValue != null && retriesValue is! int) {
    throw ConfigError('service.retries', 'integer');
  }
  final retries = retriesValue == null ? 2 : retriesValue as int;
  if (retries < 0 || retries > 5) throw ConfigError('service.retries', 'range');

  final routesValue = values['routes'];
  if (routesValue is! List) throw ConfigError('service.routes', 'list');
  final routes = <Route>[];
  for (var i = 0; i < routesValue.length; i++) {
    routes.add(parseRoute(routesValue[i], 'service.routes[$i]'));
  }

  final metadataValue = values['metadata'];
  var owner = 'unknown';
  final tags = <String>[];
  if (metadataValue != null) {
    final metadata = requireMap(metadataValue, 'service.metadata');
    final ownerValue = metadata['owner'];
    if (ownerValue != null) {
      owner = requireString(metadata, 'owner', 'service.metadata.owner');
    }
    final tagsValue = metadata['tags'];
    if (tagsValue != null) {
      if (tagsValue is! List) throw ConfigError('service.metadata.tags', 'list');
      for (var i = 0; i < tagsValue.length; i++) {
        final tag = tagsValue[i];
        if (tag is! String || tag.isEmpty) {
          throw ConfigError('service.metadata.tags[$i]', 'string');
        }
        tags.add(tag);
      }
    }
  }
  return ServiceConfig(name, host, port,
      enabled: enabled, retries: retries, owner: owner, tags: tags, routes: routes);
}

int main(int batches) {
  final configs = <Map<String, Object?>>[
    {'name': 'web', 'host': 'web.internal', 'port': 8080, 'enabled': true,
      'retries': 3, 'routes': [
        {'path': '/api', 'target': 'api'},
        {'path': '/health', 'target': 'status'},
      ], 'metadata': {'owner': 'core', 'tags': ['public', 'api']}},
    {'name': 'worker', 'host': 'queue.internal', 'port': 9001,
      'enabled': false, 'routes': []},
    {'name': 'metrics', 'host': 'stats.internal', 'port': 9100,
      'routes': [{'path': '/metrics', 'target': 'prometheus'}],
      'metadata': {'owner': 'ops', 'tags': []}},
    {'name': 'gateway', 'host': 'edge.example', 'port': 443,
      'retries': null, 'routes': [
        {'path': '/', 'target': 'web'},
        {'path': '/login', 'target': 'auth'},
        {'path': '/static', 'target': 'assets'},
      ]},
    {'name': 'docs', 'host': 'docs.internal', 'port': 8081,
      'routes': [{'path': '/guide', 'target': 'pages'}],
      'metadata': {'owner': null, 'tags': ['web']}},
    {'name': 'sync', 'host': 'sync.internal', 'port': 7001,
      'routes': [], 'metadata': {'owner': 'data', 'tags': null}},
    {'name': 'notifications', 'host': 'mail.internal', 'port': 2525,
      'enabled': null, 'retries': 1, 'routes': [
        {'path': '/send', 'target': 'mailer'},
        {'path': '/status', 'target': 'queue'},
      ]},
    {'name': 'audit', 'host': 'audit.internal', 'port': 4111,
      'routes': [{'path': '/events', 'target': 'log'}]},
    {'name': 'broken-port', 'host': 'bad.internal', 'port': 70000,
      'routes': []},
    {'name': 'broken-route', 'host': 'bad.internal', 'port': 8080,
      'routes': [{'path': 'health', 'target': 'status'}]},
  ];

  var checksum = 0;
  var valid = 0;
  var invalid = 0;
  for (var batch = 0; batch < batches; batch++) {
    for (final raw in configs) {
      try {
        checksum += validate(raw).score;
        valid++;
      } on ConfigError catch (error) {
        checksum += error.path.length * 13 + error.reason.length * 7;
        invalid++;
      }
    }
  }
  return checksum + valid * 1000003 + invalid * 1009;
}
''';

void main(List<String> args) => runComparison(
  args,
  name: 'config_validation',
  source: _source,
  parameter: 'batches',
  unit: 'batch',
  iterations: 500,
  warmupIterations: 5,
);
