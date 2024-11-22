# https://github.com/mogol/flutter_secure_storage/issues/748
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy

# Keep native methods and callbacks from libgit2
-keepclasseswithmembernames class * {
    native <methods>;
}
-keep class com.example.libgit2.* { *; }

# For debugging what the minifier is doing
#-printusage usage.txt
#-dontobfuscate
#-dontoptimize
#-dontshrink