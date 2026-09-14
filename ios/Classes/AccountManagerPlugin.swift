import Flutter
import UIKit

/// Flutter plugin entry point for the account_manager plugin.
public class AccountManagerPlugin: NSObject, FlutterPlugin {

    /// Retained for the lifetime of the plugin so the configure channel handler
    /// can update the active KeychainManager access group.
    private static var sharedImpl: AccountManagerHostApiImpl?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let impl = AccountManagerHostApiImpl()
        sharedImpl = impl
        AccountManagerHostApiSetup.setUp(binaryMessenger: messenger, api: impl)

        // Secondary MethodChannel that lets the Dart layer configure the
        // Keychain Access Group before the first credential operation.
        let configChannel = FlutterMethodChannel(
            name: "flutter_account_manager/config",
            binaryMessenger: messenger
        )
        configChannel.setMethodCallHandler { call, result in
            guard call.method == "configure" else {
                result(FlutterMethodNotImplemented)
                return
            }
            let args = call.arguments as? [String: Any?]
            let group = args?["keychainAccessGroup"] as? String
            AccountManagerPlugin.sharedImpl?.configure(accessGroup: group)
            result(nil)
        }
    }
}
