# ──────────────────────────────
# Flutter CallKit Incoming
# ──────────────────────────────
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-keep class com.hiennv.flutter_callkit_incoming.models.** { *; }

# ──────────────────────────────
# Firebase Messaging & GMS
# ──────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ──────────────────────────────
# Awesome Notifications
# ──────────────────────────────
-keep class me.carda.awesome_notifications.** { *; }

# ──────────────────────────────
# Jackson / Gson / Annotations
# ──────────────────────────────
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Jackson specific fix for annotations
-keepclassmembers class * {
    @com.fasterxml.jackson.annotation.* <fields>;
    @com.fasterxml.jackson.annotation.* <methods>;
}

-keepclassmembers class * {
    @com.fasterxml.jackson.databind.annotation.* <fields>;
    @com.fasterxml.jackson.databind.annotation.* <methods>;
}

# ──────────────────────────────
# Services and BroadcastReceivers
# ──────────────────────────────
-keep class * extends android.app.Service { *; }
-keep class * extends android.content.BroadcastReceiver { *; }

# ──────────────────────────────
# AndroidX Compatibility
# ──────────────────────────────
-keep class androidx.** { *; }
-dontwarn androidx.**

# ──────────────────────────────
# Fix for R8 missing Java platform classes (jackson-databind)
# ──────────────────────────────
-keep class java.beans.ConstructorProperties { *; }
-keep class java.beans.Transient { *; }
-keep class java.beans.** { *; }
-dontwarn java.beans.**

-keep class org.w3c.dom.bootstrap.DOMImplementationRegistry { *; }
-keep class org.w3c.dom.** { *; }
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry
