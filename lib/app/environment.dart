enum LumeEnvironment { local, dev, prod }

abstract final class LumeBuildConfig {
  static const rawEnvironment = String.fromEnvironment(
    'LUME_ENV',
    defaultValue: 'local',
  );
  static const enableCalendar = bool.fromEnvironment(
    'LUME_ENABLE_CALENDAR',
    defaultValue: true,
  );
  static const googleCalendarIosClientId = String.fromEnvironment(
    'LUME_GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '1018427269031-d002niqglh23u9omq8urmee091gqotca.apps.googleusercontent.com',
  );
  static const enableLinkExtraction = bool.fromEnvironment(
    'LUME_ENABLE_LINK_EXTRACTION',
    defaultValue: false,
  );
  static const linkExtractionEndpoint = String.fromEnvironment(
    'LUME_LINK_EXTRACTION_ENDPOINT',
    defaultValue:
        'https://us-central1-lume-13125.cloudfunctions.net/extractLinkMetadata',
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
