class EnvConfig {
  final String flavor;
  final String appName;
  final String baseUrl;

  const EnvConfig({
    required this.flavor,
    required this.appName,
    required this.baseUrl,
  });

  static const dev = EnvConfig(
    flavor: 'dev',
    appName: 'OpShare Dev',
    baseUrl: 'http://192.168.1.6:8080',
  );

  static const uat = EnvConfig(
    flavor: 'uat',
    appName: 'OpShare UAT',
    baseUrl: 'http://34.60.181.59:8080',
  );

  static const prod = EnvConfig(
    flavor: 'prod',
    appName: 'OpShare',
    baseUrl: 'http://34.60.181.59:8080',
  );
}