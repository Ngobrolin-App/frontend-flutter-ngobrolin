# ==========================================
# 1. FLUTTER CORE RULES
# ==========================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.common.** { *; }

# ==========================================
# 2. IMAGE CROPPER / UCROP (Wajib)
# ==========================================
-keep class com.yalantis.ucrop.** { *; }
-dontwarn com.yalantis.ucrop.**

# ==========================================
# 3. FLUTTER LOCAL NOTIFICATIONS
# ==========================================
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# ==========================================
# 4. FIREBASE & PLAY SERVICES
# ==========================================
-keep public class com.google.firebase.** { *; }
-keep public class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ==========================================
# 5. PERMISSION HANDLER
# ==========================================
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# ==========================================
# 6. IGNORE MISSING PLAY CORE CLASSES
# ==========================================
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**