# Rules applied to consumers of this AAR.
# Keep the vendored ZXing classes so an R8-shrunk consumer build still works.
-keep class com.google.zxing.** { *; }
-dontwarn com.google.zxing.**
