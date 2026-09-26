from support.comparison import run_comparison


class ConfigError(Exception):
    def __init__(self, path: str, reason: str) -> None:
        self.path = path
        self.reason = reason


class Route:
    def __init__(self, path: str, target: str) -> None:
        self.path = path
        self.target = target

    @property
    def score(self) -> int:
        return len(self.path) * 11 + len(self.target) * 7


class ServiceConfig:
    def __init__(self, name: str, host: str, port: int, *, enabled: bool,
                 retries: int, owner: str, tags: list[str], routes: list[Route]) -> None:
        self.name = name
        self.host = host
        self.port = port
        self.enabled = enabled
        self.retries = retries
        self.owner = owner
        self.tags = tags
        self.routes = routes

    @property
    def score(self) -> int:
        total = (len(self.name) * 3 + len(self.host) + self.port +
                 self.retries * 5 + len(self.owner) + (17 if self.enabled else 0))
        for tag in self.tags:
            total += len(tag) * 13
        for route in self.routes:
            total += route.score
        return total


def require_map(value: object, path: str) -> dict[str, object]:
    if type(value) is not dict:
        raise ConfigError(path, 'type')
    return value


def require_string(values: dict[str, object], key: str, path: str) -> str:
    value = values.get(key)
    if type(value) is not str or not value:
        raise ConfigError(path, 'string')
    return value


def require_int(values: dict[str, object], key: str, path: str) -> int:
    value = values.get(key)
    if type(value) is not int:
        raise ConfigError(path, 'integer')
    return value


def parse_route(raw: object, path: str) -> Route:
    values = require_map(raw, path)
    route_path = require_string(values, 'path', f'{path}.path')
    if not route_path.startswith('/'):
        raise ConfigError(f'{path}.path', 'absolute')
    target = require_string(values, 'target', f'{path}.target')
    return Route(route_path, target)


def validate(raw: object) -> ServiceConfig:
    values = require_map(raw, 'service')
    name = require_string(values, 'name', 'service.name')
    host = require_string(values, 'host', 'service.host')
    port = require_int(values, 'port', 'service.port')
    if port < 1 or port > 65535:
        raise ConfigError('service.port', 'range')

    enabled_value = values.get('enabled')
    if enabled_value is not None and type(enabled_value) is not bool:
        raise ConfigError('service.enabled', 'boolean')
    enabled = True if enabled_value is None else enabled_value

    retries_value = values.get('retries')
    if retries_value is not None and type(retries_value) is not int:
        raise ConfigError('service.retries', 'integer')
    retries = 2 if retries_value is None else retries_value
    if retries < 0 or retries > 5:
        raise ConfigError('service.retries', 'range')

    routes_value = values.get('routes')
    if type(routes_value) is not list:
        raise ConfigError('service.routes', 'list')
    routes = []
    for i in range(len(routes_value)):
        routes.append(parse_route(routes_value[i], f'service.routes[{i}]'))

    metadata_value = values.get('metadata')
    owner = 'unknown'
    tags = []
    if metadata_value is not None:
        metadata = require_map(metadata_value, 'service.metadata')
        owner_value = metadata.get('owner')
        if owner_value is not None:
            owner = require_string(metadata, 'owner', 'service.metadata.owner')
        tags_value = metadata.get('tags')
        if tags_value is not None:
            if type(tags_value) is not list:
                raise ConfigError('service.metadata.tags', 'list')
            for i in range(len(tags_value)):
                tag = tags_value[i]
                if type(tag) is not str or not tag:
                    raise ConfigError(f'service.metadata.tags[{i}]', 'string')
                tags.append(tag)
    return ServiceConfig(name, host, port, enabled=enabled, retries=retries,
                         owner=owner, tags=tags, routes=routes)


def main(batches: int) -> int:
    configs = [
        {'name': 'web', 'host': 'web.internal', 'port': 8080, 'enabled': True,
         'retries': 3, 'routes': [
             {'path': '/api', 'target': 'api'},
             {'path': '/health', 'target': 'status'},
         ], 'metadata': {'owner': 'core', 'tags': ['public', 'api']}},
        {'name': 'worker', 'host': 'queue.internal', 'port': 9001,
         'enabled': False, 'routes': []},
        {'name': 'metrics', 'host': 'stats.internal', 'port': 9100,
         'routes': [{'path': '/metrics', 'target': 'prometheus'}],
         'metadata': {'owner': 'ops', 'tags': []}},
        {'name': 'gateway', 'host': 'edge.example', 'port': 443,
         'retries': None, 'routes': [
             {'path': '/', 'target': 'web'},
             {'path': '/login', 'target': 'auth'},
             {'path': '/static', 'target': 'assets'},
         ]},
        {'name': 'docs', 'host': 'docs.internal', 'port': 8081,
         'routes': [{'path': '/guide', 'target': 'pages'}],
         'metadata': {'owner': None, 'tags': ['web']}},
        {'name': 'sync', 'host': 'sync.internal', 'port': 7001,
         'routes': [], 'metadata': {'owner': 'data', 'tags': None}},
        {'name': 'notifications', 'host': 'mail.internal', 'port': 2525,
         'enabled': None, 'retries': 1, 'routes': [
             {'path': '/send', 'target': 'mailer'},
             {'path': '/status', 'target': 'queue'},
         ]},
        {'name': 'audit', 'host': 'audit.internal', 'port': 4111,
         'routes': [{'path': '/events', 'target': 'log'}]},
        {'name': 'broken-port', 'host': 'bad.internal', 'port': 70000,
         'routes': []},
        {'name': 'broken-route', 'host': 'bad.internal', 'port': 8080,
         'routes': [{'path': 'health', 'target': 'status'}]},
    ]

    checksum = 0
    valid = 0
    invalid = 0
    for _ in range(batches):
        for raw in configs:
            try:
                checksum += validate(raw).score
                valid += 1
            except ConfigError as error:
                checksum += len(error.path) * 13 + len(error.reason) * 7
                invalid += 1
    return checksum + valid * 1000003 + invalid * 1009


if __name__ == '__main__':
    run_comparison('config_validation', main, unit='batch', iterations=500,
                   warmup_iterations=5)
