import Flutter
import UIKit

/// Flutter plugin entry point for the account_manager plugin.
public class AccountManagerPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let impl = AccountManagerHostApiImpl()
        AccountManagerHostApiSetup.setUp(binaryMessenger: messenger, api: impl)
    }
}
