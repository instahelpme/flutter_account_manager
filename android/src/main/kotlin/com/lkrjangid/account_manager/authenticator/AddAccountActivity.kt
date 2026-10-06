package com.lkrjangid.account_manager.authenticator

import android.accounts.Account
import android.accounts.AccountAuthenticatorActivity
import android.accounts.AccountManager
import android.content.ContentResolver
import android.os.Bundle
import android.text.InputType
import android.view.Gravity
import android.view.View
import android.widget.*

/**
 * Native "Add Account" Activity launched by Android when the user taps
 * Settings → Accounts → Add account → Account Manager.
 *
 * This is the mandatory entry point required by [AbstractAccountAuthenticator].
 * Without it, tapping "Add account" in system Settings silently does nothing.
 *
 * Flow:
 *  1. Android calls [AccountAuthenticator.addAccount] (via [AuthenticatorService]).
 *  2. Authenticator returns a [android.content.Intent] pointing to this Activity.
 *  3. Android starts this Activity from Settings.
 *  4. User fills in their credentials and taps "Add Account".
 *  5. We call [AccountManager.addAccountExplicitly] and [setAccountAuthenticatorResult].
 *  6. Android returns to Settings showing the newly created account.
 */
class AddAccountActivity : AccountAuthenticatorActivity() {

    private lateinit var accountManager: AccountManager
    private lateinit var usernameField: EditText
    private lateinit var passwordField: EditText
    private lateinit var statusText: TextView
    private lateinit var addButton: Button
    private var accountType: String = DEFAULT_ACCOUNT_TYPE

    companion object {
        const val DEFAULT_ACCOUNT_TYPE = "com.lkrjangid.account_manager"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        accountManager = AccountManager.get(this)
        accountType = intent.getStringExtra(AccountManager.KEY_ACCOUNT_TYPE)
            ?: DEFAULT_ACCOUNT_TYPE

        setContentView(buildLayout())
    }

    // ─── Build UI programmatically (no layout XML needed in library) ──────────

    private fun buildLayout(): View {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(24), dpToPx(32), dpToPx(24), dpToPx(24))
            gravity = Gravity.CENTER_HORIZONTAL
        }

        // Title
        root.addView(TextView(this).apply {
            text = "Add Account"
            textSize = 22f
            setPadding(0, 0, 0, dpToPx(4))
            setTextColor(0xFF1A73E8.toInt())
            gravity = Gravity.CENTER
        })

        // Subtitle showing account type
        root.addView(TextView(this).apply {
            text = accountType
            textSize = 12f
            setTextColor(0xFF888888.toInt())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dpToPx(24))
        })

        // Username
        root.addView(TextView(this).apply {
            text = "Email / Username"
            textSize = 12f
            setTextColor(0xFF555555.toInt())
        })
        usernameField = EditText(this).apply {
            inputType = InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS or
                    InputType.TYPE_CLASS_TEXT
            hint = "user@example.com"
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dpToPx(16) }
        }
        root.addView(usernameField)

        // Password
        root.addView(TextView(this).apply {
            text = "Password"
            textSize = 12f
            setTextColor(0xFF555555.toInt())
        })
        passwordField = EditText(this).apply {
            inputType = InputType.TYPE_CLASS_TEXT or
                    InputType.TYPE_TEXT_VARIATION_PASSWORD
            hint = "••••••••"
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = dpToPx(24) }
        }
        root.addView(passwordField)

        // Status text (errors / info)
        statusText = TextView(this).apply {
            textSize = 12f
            setTextColor(0xFFCC0000.toInt())
            visibility = View.GONE
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dpToPx(8))
        }
        root.addView(statusText)

        // Add button
        addButton = Button(this).apply {
            text = "Add Account"
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(48)
            ).apply { bottomMargin = dpToPx(8) }
            setOnClickListener { attemptAddAccount() }
        }
        root.addView(addButton)

        // Cancel button
        root.addView(Button(this).apply {
            text = "Cancel"
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(48)
            )
            setBackgroundColor(0x00000000)
            setTextColor(0xFF888888.toInt())
            setOnClickListener {
                setResult(RESULT_CANCELED)
                finish()
            }
        })

        return root
    }

    // ─── Account creation logic ───────────────────────────────────────────────

    private fun attemptAddAccount() {
        val username = usernameField.text.toString().trim()
        val password = passwordField.text.toString()

        // Basic validation
        if (username.isEmpty()) {
            showError("Username is required")
            return
        }
        if (password.isEmpty()) {
            showError("Password is required")
            return
        }

        // Check if account already exists
        val existing = accountManager.getAccountsByType(accountType)
        if (existing.any { it.name.equals(username, ignoreCase = true) }) {
            showError("An account for \"$username\" already exists")
            return
        }

        addButton.isEnabled = false
        showError(null)

        val account = Account(username, accountType)

        // Add the account to the system AccountManager
        val added = accountManager.addAccountExplicitly(account, password, null)

        if (added) {
            // Return success to Settings — this is what makes the account appear
            val result = Bundle().apply {
                putString(AccountManager.KEY_ACCOUNT_NAME, username)
                putString(AccountManager.KEY_ACCOUNT_TYPE, accountType)
            }
            setAccountAuthenticatorResult(result)
            setResult(RESULT_OK)
            finish()
        } else {
            addButton.isEnabled = true
            showError("Failed to add account. It may already exist.")
        }
    }

    private fun showError(message: String?) {
        if (message == null) {
            statusText.visibility = View.GONE
        } else {
            statusText.text = message
            statusText.visibility = View.VISIBLE
        }
    }

    private fun dpToPx(dp: Int): Int =
        (dp * resources.displayMetrics.density).toInt()
}
