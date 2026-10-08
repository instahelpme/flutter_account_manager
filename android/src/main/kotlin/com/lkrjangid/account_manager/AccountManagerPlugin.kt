package com.lkrjangid.account_manager

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger

/** AccountManagerPlugin — Pigeon-based Flutter plugin entry point. */
class AccountManagerPlugin : FlutterPlugin {

    private var hostApiImpl: AccountManagerHostApiImpl? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        setup(binding.binaryMessenger, binding.applicationContext)
    }

    private fun setup(messenger: BinaryMessenger, context: Context) {
        val impl = AccountManagerHostApiImpl(context)
        hostApiImpl = impl
        AccountManagerHostApi.setUp(messenger, impl)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        AccountManagerHostApi.setUp(binding.binaryMessenger, null)
        hostApiImpl?.dispose()
        hostApiImpl = null
    }
}
