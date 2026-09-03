package com.rainguard.overlay

import android.content.Context
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView
import com.rainguard.R
import kotlin.math.abs

class RainBubbleManager(private val context: Context) {

    private var windowManager: WindowManager? = null
    private var bubbleView: View? = null
    private var isShowing = false
    private var isDragging = false

    private var layoutParams: WindowManager.LayoutParams? = null
    private val handler = Handler(Looper.getMainLooper())

    // Callbacks
    var onTap: (() -> Unit)? = null
    var onLongPress: (() -> Unit)? = null
    var onPositionChanged: ((x: Int, y: Int) -> Unit)? = null

    // State
    private var currentState = "idle"
    private var etaMinutes = -1

    // Dragging
    private var initialX = 0
    private var initialY = 0
    private var initialTouchX = 0f
    private var initialTouchY = 0f
    private var lastTouchX = 0f
    private var lastTouchY = 0f

    // Long press detection
    private val longPressTimeout = 500L
    private var longPressRunnable: Runnable? = null
    private var isLongPressTriggered = false

    companion object {
        private const val BUBBLE_SIZE_DP = 64
        private const val MARGIN_DP = 16
        private const val EDGE_THRESHOLD_DP = 10
    }

    fun show() {
        if (isShowing) return

        windowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        bubbleView = createBubbleView()

        val bubbleSize = dpToPx(BUBBLE_SIZE_DP)
        val margin = dpToPx(MARGIN_DP)

        layoutParams = WindowManager.LayoutParams(
            bubbleSize,
            bubbleSize,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = margin
            y = margin * 4
        }

        setupTouchListener()
        windowManager?.addView(bubbleView, layoutParams)
        isShowing = true
    }

    fun hide() {
        if (!isShowing) return

        try {
            windowManager?.removeView(bubbleView)
        } catch (e: Exception) {
            // View not attached
        }

        bubbleView = null
        isShowing = false
        cancelLongPress()
    }

    fun updateState(state: String, eta: Int?) {
        currentState = state
        etaMinutes = eta ?: -1

        handler.post {
            updateBubbleAppearance()
        }
    }

    private fun updateBubbleAppearance() {
        val emojiTextView = bubbleView?.findViewById<TextView>(R.id.bubble_emoji)
        val etaTextView = bubbleView?.findViewById<TextView>(R.id.bubble_eta)
        val background = bubbleView?.findViewById<View>(R.id.bubble_background)

        when (currentState) {
            "idle" -> {
                emojiTextView?.text = "☀️"
                etaTextView?.text = ""
                background?.setBackgroundResource(R.drawable.bubble_background_idle)
            }
            "watch" -> {
                emojiTextView?.text = "🌦️"
                etaTextView?.text = if (etaMinutes > 0) "${etaMinutes}m" else ""
                background?.setBackgroundResource(R.drawable.bubble_background_watch)
            }
            "approaching" -> {
                emojiTextView?.text = "🌧️"
                etaTextView?.text = if (etaMinutes > 0) "${etaMinutes}m" else ""
                background?.setBackgroundResource(R.drawable.bubble_background_approaching)
            }
            "warning" -> {
                emojiTextView?.text = "⚠️"
                etaTextView?.text = if (etaMinutes > 0) "${etaMinutes}m" else ""
                background?.setBackgroundResource(R.drawable.bubble_background_warning)
            }
            "imminent" -> {
                emojiTextView?.text = "🚨"
                etaTextView?.text = if (etaMinutes > 0) "${etaMinutes}m" else ""
                background?.setBackgroundResource(R.drawable.bubble_background_imminent)
            }
            "raining" -> {
                emojiTextView?.text = "🌧️"
                etaTextView?.text = "NOW"
                background?.setBackgroundResource(R.drawable.bubble_background_raining)
            }
            else -> {
                emojiTextView?.text = "?"
                etaTextView?.text = ""
                background?.setBackgroundResource(R.drawable.bubble_background_idle)
            }
        }
    }

    private fun createBubbleView(): View {
        val inflater = LayoutInflater.from(context)
        return inflater.inflate(R.layout.bubble_layout, null)
    }

    private fun setupTouchListener() {
        bubbleView?.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = layoutParams?.x ?: 0
                    initialY = layoutParams?.y ?: 0
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    lastTouchX = event.rawX
                    lastTouchY = event.rawY
                    isDragging = false
                    isLongPressTriggered = false

                    startLongPressDetection()
                    true
                }

                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - initialTouchX
                    val dy = event.rawY - initialTouchY

                    if (abs(dx) > 10 || abs(dy) > 10) {
                        isDragging = true
                        cancelLongPress()
                    }

                    if (isDragging) {
                        layoutParams?.x = initialX + dx.toInt()
                        layoutParams?.y = initialY + dy.toInt()
                        try {
                            windowManager?.updateViewLayout(bubbleView, layoutParams)
                        } catch (e: Exception) {
                            // View not attached
                        }
                    }

                    lastTouchX = event.rawX
                    lastTouchY = event.rawY
                    true
                }

                MotionEvent.ACTION_UP -> {
                    cancelLongPress()

                    if (!isDragging && !isLongPressTriggered) {
                        onTap?.invoke()
                    } else if (isDragging) {
                        snapToEdge()
                        savePosition()
                    }
                    true
                }

                MotionEvent.ACTION_CANCEL -> {
                    cancelLongPress()
                    true
                }

                else -> false
            }
        }
    }

    private fun startLongPressDetection() {
        cancelLongPress()
        longPressRunnable = Runnable {
            if (!isDragging) {
                isLongPressTriggered = true
                onLongPress?.invoke()
            }
        }
        handler.postDelayed(longPressRunnable!!, longPressTimeout)
    }

    private fun cancelLongPress() {
        longPressRunnable?.let { handler.removeCallbacks(it) }
        longPressRunnable = null
    }

    private fun snapToEdge() {
        val screenWidth = context.resources.displayMetrics.widthPixels
        val bubbleWidth = dpToPx(BUBBLE_SIZE_DP)
        val margin = dpToPx(MARGIN_DP)

        val currentX = layoutParams?.x ?: 0
        val centerX = currentX + bubbleWidth / 2

        // Snap to nearest edge
        val newX = if (centerX < screenWidth / 2) {
            margin
        } else {
            screenWidth - bubbleWidth - margin
        }

        // Animate to edge
        animateX(newX)
    }

    private fun animateX(targetX: Int) {
        val startX = layoutParams?.x ?: 0
        val startTime = System.currentTimeMillis()
        val duration = 200L

        val animator = object : Runnable {
            override fun run() {
                val elapsed = System.currentTimeMillis() - startTime
                val progress = (elapsed.toFloat() / duration).coerceIn(0f, 1f)

                // Ease out
                val easedProgress = 1f - (1f - progress) * (1f - progress)

                layoutParams?.x = (startX + (targetX - startX) * easedProgress).toInt()

                try {
                    windowManager?.updateViewLayout(bubbleView, layoutParams)
                } catch (e: Exception) {
                    return
                }

                if (progress < 1f) {
                    handler.postDelayed(this, 16) // ~60fps
                } else {
                    onPositionChanged?.invoke(layoutParams?.x ?: 0, layoutParams?.y ?: 0)
                }
            }
        }

        handler.post(animator)
    }

    private fun savePosition() {
        val x = layoutParams?.x ?: 0
        val y = layoutParams?.y ?: 0
        val prefs = context.getSharedPreferences("bubble_prefs", Context.MODE_PRIVATE)
        prefs.edit()
            .putInt("bubble_x", x)
            .putInt("bubble_y", y)
            .apply()
    }

    fun restorePosition() {
        val prefs = context.getSharedPreferences("bubble_prefs", Context.MODE_PRIVATE)
        val x = prefs.getInt("bubble_x", dpToPx(MARGIN_DP))
        val y = prefs.getInt("bubble_y", dpToPx(MARGIN_DP * 4))

        layoutParams?.x = x
        layoutParams?.y = y

        try {
            windowManager?.updateViewLayout(bubbleView, layoutParams)
        } catch (e: Exception) {
            // View not attached
        }
    }

    fun setPosition(x: Int, y: Int) {
        layoutParams?.x = x
        layoutParams?.y = y
        try {
            windowManager?.updateViewLayout(bubbleView, layoutParams)
        } catch (e: Exception) {
            // View not attached
        }
    }

    fun getPosition(): Pair<Int, Int> {
        return Pair(layoutParams?.x ?: 0, layoutParams?.y ?: 0)
    }

    fun isShowing(): Boolean = isShowing

    private fun dpToPx(dp: Int): Int {
        return (dp * context.resources.displayMetrics.density).toInt()
    }
}
