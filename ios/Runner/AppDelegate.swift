import Flutter
import UIKit
import StoreKit
import GoogleSignIn
import GoogleMaps       // ← Maps SDK for iOS
import GooglePlaces     // ← Places SDK for iOS

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ─────────────────────────────────────────────────────────────
    // Google Maps SDK for iOS: API キーを登録
    // GeneratedPluginRegistrant.register より前に呼び出すこと
    // ─────────────────────────────────────────────────────────────
    GMSServices.provideAPIKey("AIzaSyDIyFqBLbT9OyONC-kRVHAfs8XgWYz3jlo")

    // ─────────────────────────────────────────────────────────────
    // Google Places SDK for iOS: API キーを登録
    // ─────────────────────────────────────────────────────────────
    GMSPlacesClient.provideAPIKey("AIzaSyDIyFqBLbT9OyONC-kRVHAfs8XgWYz3jlo")

    // Register Flutter plugins (includes in_app_purchase, sign_in_with_apple, google_sign_in, etc.)
    GeneratedPluginRegistrant.register(with: self)

    // Ensure StoreKit payment queue observer is registered early.
    SKPaymentQueue.default().add(StoreKitPaymentObserver.shared)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Google Sign-In URL handling
  // Required for GIDSignIn to handle the OAuth redirect callback.
  // Without this, the Google sign-in flow will silently fail after
  // the user authenticates in Safari/ASWebAuthenticationSession.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Forward the URL to GIDSignIn first (Google Sign-In callback)
    if GIDSignIn.sharedInstance.handle(url) {
      return true
    }
    // Fall back to super for other URL schemes (e.g., deep links, Apple Sign-In)
    return super.application(app, open: url, options: options)
  }
}

/// Minimal StoreKit observer that ensures pending transactions are processed at launch.
/// The actual transaction handling is done by the in_app_purchase Flutter plugin.
class StoreKitPaymentObserver: NSObject, SKPaymentTransactionObserver {
  static let shared = StoreKitPaymentObserver()

  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased, .restored:
        // Don't finish here - let the Flutter plugin handle it
        break
      case .failed:
        // Finish failed transactions to prevent them from blocking the queue
        queue.finishTransaction(transaction)
      case .deferred, .purchasing:
        break
      @unknown default:
        break
      }
    }
  }
}
