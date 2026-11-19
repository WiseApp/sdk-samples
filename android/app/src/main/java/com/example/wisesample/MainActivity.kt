package com.example.wisesample

import android.os.Bundle
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.edit
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import androidx.core.widget.doAfterTextChanged
import com.wise.sdk.core.WiseSDK
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : AppCompatActivity() {

    private val wise by lazy { WiseSDK.getInstance(applicationContext) }
    private val prefs by lazy { getSharedPreferences("wise-sample", MODE_PRIVATE) }
    private var ready = false

    private lateinit var namespace: EditText
    private lateinit var classPublicId: EditText
    private lateinit var displayName: EditText
    private lateinit var ssoToken: EditText
    private lateinit var classId: EditText
    private lateinit var signIn: Button
    private lateinit var signOut: Button
    private lateinit var signInTitle: TextView
    private lateinit var log: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        // Android 15+ draws apps edge to edge: keep the form clear of the status bar, the
        // navigation bar and the keyboard.
        // Light background: dark status bar icons.
        WindowCompat.getInsetsController(window, window.decorView).isAppearanceLightStatusBars = true
        ViewCompat.setOnApplyWindowInsetsListener(findViewById<View>(R.id.root)) { view, insets ->
            val bars = insets.getInsets(WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.ime())
            view.updatePadding(left = bars.left, top = bars.top, right = bars.right, bottom = bars.bottom)
            insets
        }

        namespace = findViewById(R.id.namespace)
        classPublicId = findViewById(R.id.classPublicId)
        displayName = findViewById(R.id.displayName)
        ssoToken = findViewById(R.id.ssoToken)
        classId = findViewById(R.id.classId)
        signIn = findViewById(R.id.signIn)
        signOut = findViewById(R.id.signOut)
        signInTitle = findViewById(R.id.signInTitle)
        log = findViewById(R.id.log)

        // Your details are typed in once and saved on the device.
        remember(namespace, "namespace")
        remember(classPublicId, "classPublicId")
        remember(classId, "classId")

        findViewById<Button>(R.id.initialize).setOnClickListener {
            wise.init(namespace.text.toString().trim())
            wise.trackAttentiveness(applicationContext)
            // "Meeting in progress" notification icon (white on transparent).
            wise.setNotificationIconRes(R.drawable.ic_notification)
            ready = true
            add("initialize: ok")
        }

        findViewById<Button>(R.id.joinPublic).setOnClickListener {
            if (!checkReady()) return@setOnClickListener
            wise.joinMeeting(
                token = classPublicId.text.toString().trim(),
                userId = "",
                displayName = displayName.text.toString().trim(),
                listener = meetingListener,
            )
        }

        signIn.setOnClickListener {
            if (!checkReady()) return@setOnClickListener
            val token = ssoToken.text.toString().replace(Regex("\\s+"), "")
            wise.loginUsingSSOToken(token, object : WiseSDK.SSOTokenLoginListener {
                override fun onSuccess() = runOnUiThread {
                    add("loginUsingSSOToken: ok")
                    ssoToken.text.clear()
                    updateSignedIn()
                }

                override fun onError(errorCode: Int, errorFlag: String?) = runOnUiThread {
                    add("loginUsingSSOToken: error $errorCode ${errorFlag.orEmpty()}")
                }
            })
        }

        signOut.setOnClickListener {
            wise.logoutSSO()
            add("logoutSSO: ok")
            updateSignedIn()
        }

        findViewById<Button>(R.id.joinClass).setOnClickListener {
            if (!checkReady()) return@setOnClickListener
            wise.joinMeeting(classId.text.toString().trim(), disableScreenCapture = false, listener = meetingListener)
        }

        findViewById<Button>(R.id.startClass).setOnClickListener {
            if (!checkReady()) return@setOnClickListener
            wise.startMeeting(classId.text.toString().trim(), disableScreenCapture = false, listener = meetingListener)
        }

        // The SDK keeps the session across launches: no need to sign in again while it exists.
        updateSignedIn()
    }

    private fun updateSignedIn() {
        val signedIn = wise.isLoggedIn()
        ssoToken.isEnabled = !signedIn
        ssoToken.hint = if (signedIn) "Already signed in" else "JWT signed by your backend (eyJ...)"
        signIn.isEnabled = !signedIn
        signOut.isEnabled = signedIn
        signInTitle.text = if (signedIn) "Sign in · Signed in ✓" else "Sign in (once per install)"
    }

    private fun checkReady(): Boolean {
        if (!ready) add("Tap Initialize first")
        return ready
    }

    private fun remember(field: EditText, key: String) {
        field.setText(prefs.getString(key, ""))
        field.doAfterTextChanged { prefs.edit { putString(key, it?.toString()?.trim().orEmpty()) } }
    }

    private fun add(line: String) {
        val time = SimpleDateFormat("HH:mm:ss", Locale.US).format(Date())
        log.text = "$time  $line\n${log.text}"
    }

    private val meetingListener = object : WiseSDK.WiseSDKMeetingListener {
        override fun onSDKError(wiseErrorCode: Int, errorCode: Int, internalErrorCode: Int) =
            event("onSDKError wiseErrorCode=$wiseErrorCode errorCode=$errorCode internal=$internalErrorCode")

        override fun onMeetingConnecting() = event("onMeetingConnecting")
        override fun onMeetingStarted(isInMeeting: Boolean) = event("onMeetingStarted isInMeeting=$isInMeeting")
        override fun onMeetingEnded(userId: String?, endReasonCode: Long) = event("onMeetingEnded reason=$endReasonCode")
        override fun onMeetingEndedByHost(endReasonCode: Long) = event("onMeetingEndedByHost reason=$endReasonCode")
        override fun onMeetingEndedWithError(message: String, errorCode: Int, internalErrorCode: Int) =
            event("onMeetingEndedWithError $message ($errorCode)")

        override fun onMeetingNeedPasswordOrDisplayName() = event("onMeetingNeedPasswordOrDisplayName")
        override fun onMeetingNotStartedByHostError() = event("onMeetingNotStartedByHostError")
        override fun onVendorIdError() = event("onVendorIdError")
        override fun onInitialised() = event("onInitialised")
    }

    private fun event(line: String) = runOnUiThread { add(line) }
}
