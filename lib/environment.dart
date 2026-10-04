enum AppFlavor {
  dev,
  prod,
}

class Environment {
  final AppFlavor flavor;
  final String appName;
  final String routingBaseUrl;
  final bool showDevBanner;

  const Environment({
    required this.flavor,
    required this.appName,
    required this.routingBaseUrl,
    required this.showDevBanner,
  });

  static late final Environment current;

  static void init(Environment env) {
    current = env;
  }

  bool get isDev => flavor == AppFlavor.dev;
  bool get isProd => flavor == AppFlavor.prod;
}
