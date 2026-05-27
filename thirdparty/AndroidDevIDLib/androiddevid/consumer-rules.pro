# R8/ProGuard rules applied to consumers of this AAR. Keep the JNI
# entry point — R8 has no way to know the C++ side references it,
# so without this it gets stripped from release builds.
-keep class com.vlearn2.devid.AndroidDevID {
    public static java.lang.String getDeviceId(android.content.Context);
    private static native java.lang.String nativeReadCpuSerial();
}
