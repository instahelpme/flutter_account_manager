package com.lkrjangid.account_manager.utils

import android.accounts.Account
import android.accounts.AccountManager
import android.os.Bundle
import org.json.JSONArray
import org.json.JSONException
import com.lkrjangid.account_manager.AccountData

/** Extension helpers for converting between Android Account and Pigeon AccountData. */

const val DISPLAY_NAME_KEY = "displayName"

/**
 * Android's AccountManager cannot enumerate user data, so the keys written through this
 * plugin are tracked (as a JSON array) under this reserved key.
 */
const val USER_DATA_KEYS_KEY = "__account_manager_user_data_keys"

fun Account.toAccountData(accountManager: AccountManager): AccountData {
    val displayName = accountManager.getUserData(this, DISPLAY_NAME_KEY)
    // Only include entries with non-null values to avoid cast failures on the Dart side.
    val userDataMap = mutableMapOf<String?, String?>()
    readUserDataKeys(accountManager.getUserData(this, USER_DATA_KEYS_KEY)).forEach { key ->
        val value = accountManager.getUserData(this, key)
        if (value != null) userDataMap[key] = value
    }
    if (displayName != null) userDataMap[DISPLAY_NAME_KEY] = displayName
    return AccountData(
        username = this.name,
        accountType = this.type,
        displayName = displayName,
        userData = if (userDataMap.isEmpty()) null else userDataMap,
    )
}

fun Map<String?, String?>.toBundle(): Bundle {
    val bundle = Bundle()
    forEach { (key, value) ->
        if (key != null && key != USER_DATA_KEYS_KEY) bundle.putString(key, value)
    }
    bundle.putString(USER_DATA_KEYS_KEY, writeUserDataKeys(persistableKeys()))
    return bundle
}

fun AccountData.toAndroidAccount(): Account = Account(username, accountType)

/** Parses the tracked user data key list; tolerates a missing or corrupt value. */
fun readUserDataKeys(raw: String?): Set<String> {
    if (raw.isNullOrEmpty()) return emptySet()
    return try {
        val array = JSONArray(raw)
        (0 until array.length()).map { array.getString(it) }.toSet()
    } catch (e: JSONException) {
        emptySet()
    }
}

fun writeUserDataKeys(keys: Set<String>): String = JSONArray(keys.sorted()).toString()

/** Keys of this map that are safe to persist (non-null, not reserved). */
fun Map<String?, String?>.persistableKeys(): Set<String> =
    keys.filterNotNull().filter { it != USER_DATA_KEYS_KEY }.toSet()
