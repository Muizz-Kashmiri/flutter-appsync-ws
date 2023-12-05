class ConstantsClass {
// websocket endpoint
  static const String wss = "";
// api key
  static const String api = "";
// graphql endpoint
  static const String graphQlUrlEndpoint = "";

  static final Map<String, String> apiHeader = {
    "Sec-WebSocket-Protocol": "graphql-ws",
    "host": ConstantsClass.generateHost(wss),
    'x-api-key': ConstantsClass.api,
  };

  static String username = 'Unknown';

  static String generateHost(String firstUrl) {
    int index = firstUrl.indexOf("appsync-realtime-api");

    if (index != -1) {
      int start = firstUrl.lastIndexOf("/", index);
      String subdomain = firstUrl.substring(start + 1, index - 1);
      return "$subdomain.appsync-api.us-east-1.amazonaws.com";
    } else {
      return "";
    }
  }
}
