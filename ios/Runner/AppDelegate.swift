import Flutter
import UIKit
import StoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register Flutter plugins (includes in_app_purchase, sign_in_with_apple, etc.)
    // This also sets up SKPaymentQueue observer via the IAP plugin.
    GeneratedPluginRegistrant.register(with: self)

    // Ensure StoreKit payment queue observer is registered early.
    // The in_app_purchase plugin does this internally, but we ensure the queue
    // is active from launch to catch any pending transactions from previous sessions.
    SKPaymentQueue.default().add(StoreKitPaymentObserver.shared)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

/// Minimal StoreKit observer that ensures pending transactions are processed at launch.
/// The actual transaction handling is done by the in_app_purchase Flutter plugin.
/// This observer catches transactions that arrive before the Flutter engine is ready.
class StoreKitPaymentObserver: NSObject, SKPaymentTransactionObserver {
  static let shared = StoreKitPaymentObserver()

  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    // Let the in_app_purchase plugin handle the transactions.
    // This observer just ensures the queue is active from app launch.
    // Transactions will be forwarded to the plugin when Flutter engine is ready.
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
