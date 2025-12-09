class ApiManager {
  static const String baseUrl = "https://enabled-flowing-bedbug.ngrok-free.app";

  static const String chatTestUrl = "/test";
  static const String chatUrl = "/chat";
  static const String voiceUrl = "/voice";
  static const String searchUrl = "/search";

  // Translation endpoints
  static const String translateUrl = "/translate";
  static const String batchTranslateUrl = "/batch-translate";
  static const String translateWithContextUrl = "/translate-with-context";
  static const String supportedLanguagesUrl = "/languages";
  static const String languageHealthUrl = "/language-health";
  // Users
  static const String usersUrl = "/user/profile";
  // posts
  static const String postsUrl = "/posts";
  static const String postCreateUrl = "/post";
  static const String postUser = "/post/user";
  static String postLike(String postId) => "/post/$postId/like";

  // Expert/Special posts
  static const String createSpecialPostUrl = "/post/special";
  static const String pendingPostsUrl = "/post/pending";
  static String verifyPostUrl(String postId) => "/post/verify/$postId";
  static String rejectPostUrl(String postId) => "/post/reject/$postId";

  // IMD Weather
  static String imdStationsUrl(String stateName) =>
      "$baseUrl/weather/stations/$stateName";
  static String imdWeatherUrl(String stationId) =>
      "$baseUrl/weather/$stationId";

  // enam mandi
  static String mandiTradeDataUrl(
    String stateName,
    String fromDate,
    String toDate,
  ) => "$baseUrl/mandi/trade_data/$stateName/$fromDate/$toDate";

  // chat agri
  static const String chatAgriUrl = '$baseUrl/chat/agri';
}
