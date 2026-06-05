# Suppress warnings for missing optional annotations
-dontwarn javax.annotation.**
-dontwarn javax.annotation.concurrent.**
-keepattributes *Annotation*

# Keep Tink classes
-keep class com.google.crypto.tink.** { *; }

# Ignore missing optional classes used by Tink
-dontwarn com.google.api.client.http.**
-dontwarn org.joda.time.**
-keep class com.google.crypto.tink.** { *; }
