package com.example.app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val securityChannel = "com.binoexam.app/security"
    private val mainHandler = Handler(Looper.getMainLooper())
    private var pendingLockResult: MethodChannel.Result? = null
    private var lockTimeoutRunnable: Runnable? = null
    private var lockPollRunnable: Runnable? = null

    /** Mendaftarkan MethodChannel keamanan perangkat, baterai, dan kecerahan layar. */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isScreenPinned" -> {
                        result.success(isScreenPinned())
                    }
                    "startLockTask" -> {
                        handleStartLockTask(result)
                    }
                    "stopLockTask" -> {
                        try {
                            if (isScreenPinned()) {
                                stopLockTask()
                            }
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "openSecuritySettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_SECURITY_SETTINGS))
                            result.success(true)
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "getBatteryInfo" -> {
                        result.success(getBatteryInfo())
                    }
                    "getBrightness" -> {
                        result.success(getCurrentBrightness())
                    }
                    "setBrightness" -> {
                        val level = (call.argument<Double>("level") ?: 0.5).coerceIn(0.15, 1.0)
                        val lp = window.attributes
                        lp.screenBrightness = level.toFloat()
                        window.attributes = lp
                        result.success(true)
                    }
                    "enableSecureScreen" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(true)
                    }
                    "disableSecureScreen" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Memulai Screen Pinning dan menunggu hingga status Lock Task benar-benar terverifikasi. */
    private fun handleStartLockTask(result: MethodChannel.Result) {
        if (isScreenPinned()) {
            result.success(true)
            return
        }

        // Batalkan permintaan sebelumnya jika masih menggantung
        finishPendingLock(false)
        pendingLockResult = result

        try {
            startLockTask()
        } catch (e: Exception) {
            finishPendingLock(false)
            return
        }

        // Poll cepat setiap 250ms agar langsung terdeteksi begitu mode pinned aktif
        var elapsedMs = 0L
        val poll = object : Runnable {
            override fun run() {
                if (pendingLockResult == null) return
                if (isScreenPinned()) {
                    finishPendingLock(true)
                    return
                }
                elapsedMs += 250L
                if (elapsedMs >= 1500L && hasWindowFocus()) {
                    finishPendingLock(false)
                    return
                }
                mainHandler.postDelayed(this, 250L)
            }
        }
        lockPollRunnable = poll
        mainHandler.postDelayed(poll, 250L)

        // Batas waktu maksimal agar channel tidak menggantung selamanya
        val timeout = Runnable {
            if (pendingLockResult != null) {
                finishPendingLock(isScreenPinned())
            }
        }
        lockTimeoutRunnable = timeout
        mainHandler.postDelayed(timeout, 30000L)
    }

    /** Memeriksa ulang status Screen Pinning saat dialog sistem Android selesai ditutup. */
    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus && pendingLockResult != null) {
            mainHandler.postDelayed({
                if (pendingLockResult != null) {
                    finishPendingLock(isScreenPinned())
                }
            }, 150L)
        }
    }

    /** Menyelesaikan callback MethodChannel yang tertunda dan membersihkan timer polling. */
    private fun finishPendingLock(success: Boolean) {
        lockPollRunnable?.let { mainHandler.removeCallbacks(it) }
        lockPollRunnable = null
        lockTimeoutRunnable?.let { mainHandler.removeCallbacks(it) }
        lockTimeoutRunnable = null
        val pending = pendingLockResult
        pendingLockResult = null
        pending?.success(success)
    }

    /** Memeriksa apakah aplikasi sedang berada dalam mode Screen Pinning / Lock Task. */
    @Suppress("DEPRECATION")
    private fun isScreenPinned(): Boolean {
        val activityManager = getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return false

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            activityManager.lockTaskModeState != ActivityManager.LOCK_TASK_MODE_NONE
        } else {
            activityManager.isInLockTaskMode
        }
    }

    /** Mengambil persentase baterai dan status pengisian daya dari sistem Android. */
    private fun getBatteryInfo(): Map<String, Any> {
        val batteryIntent = registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val level = batteryIntent?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryIntent?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1
        val pct = if (level >= 0 && scale > 0) (level * 100) / scale else -1
        val status = batteryIntent?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val isCharging = status == BatteryManager.BATTERY_STATUS_CHARGING ||
            status == BatteryManager.BATTERY_STATUS_FULL
        return mapOf(
            "level" to pct,
            "isCharging" to isCharging
        )
    }

    /** Membaca nilai kecerahan layar jendela saat ini atau fallback ke pengaturan sistem. */
    private fun getCurrentBrightness(): Double {
        val winVal = window.attributes.screenBrightness
        if (winVal >= 0f) {
            return winVal.toDouble().coerceIn(0.15, 1.0)
        }
        return try {
            val sysVal = Settings.System.getInt(
                contentResolver,
                Settings.System.SCREEN_BRIGHTNESS,
                128
            )
            (sysVal / 255.0).coerceIn(0.15, 1.0)
        } catch (e: Exception) {
            0.5
        }
    }
}
