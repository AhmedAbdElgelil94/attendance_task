# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# WorkManager
-keepclassmembers class * extends androidx.work.Worker {
    public <init>(android.content.Context,androidx.work.WorkerParameters);
}

# Local Notifications
-keep class com.dexterous.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.startup.** { *; }

# Play Core
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }
-keep class * extends com.google.android.play.core.splitcompat.SplitCompatApplication { *; }

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }

# General
-keepattributes SourceFile,LineNumberTable
-keep class * extends androidx.work.Worker
-keep class * extends androidx.work.InputMerger
-keep class * extends androidx.work.WorkerParameters

# Keep R8 rules
-keepattributes LineNumberTable,SourceFile
-renamesourcefileattribute SourceFile

# Prevent R8 from stripping interface information
-keepattributes InnerClasses
-keep class **.R
-keep class **.R$* {
    <fields>;
} 