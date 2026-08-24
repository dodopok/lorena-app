enum LumeEnvironment { local, dev, prod }

abstract final class LumeBuildConfig {
  static const rawEnvironment = String.fromEnvironment(
    'LUME_ENV',
    defaultValue: 'local',
  );
  static const enableCalendar = bool.fromEnvironment(
    'LUME_ENABLE_CALENDAR',
    defaultValue: false,
  );
  static const googleCalendarIosClientId = String.fromEnvironment(
    'LUME_GOOGLE_IOS_CLIENT_ID',
  );
  static const enableLinkExtraction = bool.fromEnvironment(
    'LUME_ENABLE_LINK_EXTRACTION',
    defaultValue: false,
  );

  static LumeEnvironment get environment => switch (rawEnvironment) {
    'prod' => LumeEnvironment.prod,
    'dev' => LumeEnvironment.dev,
    _ => LumeEnvironment.local,
  };

  static bool get isProduction => environment == LumeEnvironment.prod;

  static String get label => switch (environment) {
    LumeEnvironment.prod => 'produção',
    LumeEnvironment.dev => 'desenvolvimento',
    LumeEnvironment.local => 'local',
  };
}
