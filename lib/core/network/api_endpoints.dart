/// Relative Better Auth and API paths (joined with base URLs from env).
abstract final class ApiEndpoints {
  /// Better Auth email sign-up.
  static const String authSignUpEmail = '/auth/sign-up/email';

  /// Better Auth email sign-in.
  static const String authSignInEmail = '/auth/sign-in/email';

  /// Better Auth sign-out.
  static const String authSignOut = '/auth/sign-out';

  /// Better Auth account deletion.
  static const String authDeleteAccount = '/auth/delete-user';

  /// Better Auth profile patch.
  static const String authUpdateUser = '/auth/update-user';

  /// Better Auth session lookup.
  static const String authGetSession = '/auth/get-session';

  /// Better Auth password reset request.
  static const String authForgetPassword = '/auth/request-password-reset';

  /// Better Auth reset password.
  static const String authResetPassword = '/auth/reset-password';

  /// Better Auth social OAuth entry point (set `provider: "google"` in body).
  /// Social sign-in (Google, Apple, …).
  static const String authSignInSocial = '/auth/sign-in/social';

  /// @deprecated Use [authSignInSocial].
  static const String authSignInGoogle = authSignInSocial;

  /// Better Auth email-OTP send endpoint (sign-in or sign-up via code).
  static const String authSendOtp = '/auth/email-otp/send-verification-otp';

  /// Better Auth email-OTP sign-in endpoint (verifies the 6-digit code).
  static const String authSignInOtp = '/auth/sign-in/email-otp';

  /// Orders collection path.
  static const String orders = '/orders';

  /// Payments root path.
  static const String payments = '/payments';

  /// Payment intent creation.
  static const String paymentIntent = '/payments/intent';

  /// Sandbox charge simulation (dev-only on the server).
  static const String paymentSimulate = '/payments/simulate';

  /// Real Tap charge capture using a token returned by the mobile SDK.
  static const String paymentConfirm = '/payments/confirm';

  /// Measurements collection path.
  static const String measurements = '/measurements';

  /// Designs collection path.
  static const String designs = '/designs';

  /// Fabrics collection path.
  static const String fabrics = '/fabrics';

  /// Presets collection path.
  static const String presets = '/presets';

  /// Modular configurator catalogue (templates, slots, options).
  static const String configuratorTemplates = '/configurator/templates';

  /// Upload endpoint.
  static const String upload = '/upload';

  /// AI proxy root path.
  static const String ai = '/ai';
  static const String aiMannequin = '/ai/mannequin';
  static const String aiDesignRender = '/ai/design-render';

  /// Community root path.
  static const String community = '/community';

  /// Posts root path.
  static const String posts = '/posts';

  /// Bookings root path.
  static const String bookings = '/bookings';

  /// Users root path.
  static const String users = '/users';

  /// Admin-managed mannequin options.
  static const String mannequins = '/mannequins';

  /// Designer profile, list, earnings, commissions.
  static const String designers = '/designers';

  /// Public-design showcase grid.
  static const String showcase = '/showcase';

  /// Delivery-role collection path.
  static const String delivery = '/delivery';

  /// Tailor workshop location and price plan management.
  static const String tailorPricing = '/tailor/pricing';

  /// Tailor wedding dress rent/sale/deposit overrides.
  static const String tailorWeddingPricing = '/tailor/wedding-pricing';

  /// Public wedding dress catalogue.
  static const String weddingDresses = '/wedding/dresses';

  /// Proximity quote for wedding rent or purchase.
  static const String ordersWeddingQuote = '/orders/wedding-quote';

  /// Garment price estimate band (no delivery coords).
  static const String ordersEstimate = '/orders/estimate';

  /// Compare tailor quotes for checkout.
  static const String ordersQuotesCompare = '/orders/quotes/compare';

  /// Quote negotiation endpoints (under /orders).
  static const String ordersQuoteNegotiations = '/orders/quote-negotiations';

  /// Complaints collection path.
  static const String complaints = '/complaints';

  /// Partner role (tailor / delivery) intake requests.
  static const String roleRequests = '/role-requests';

  /// Editor flat-lay design catalog (CMS-managed items).
  static const String catalogDesigns = '/catalog/designs';

  /// Admin dashboard root.
  static const String admin = '/admin';

  /// Admin upload into R2 catalog/{designs|configurator}/ (under [admin]).
  static const String adminUploadCatalogAsset = '/upload/catalog-asset';
}
