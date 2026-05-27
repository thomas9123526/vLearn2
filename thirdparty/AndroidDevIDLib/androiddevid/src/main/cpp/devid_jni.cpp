#include <jni.h>

#include "devid.h"

// JNI naming convention: Java_<pkg>_<Class>_<method> with '.' -> '_'.
// The fully-qualified Java symbol is
// com.vlearn2.devid.AndroidDevID#nativeReadCpuSerial(), which produces
// the C symbol below. `JNIEXPORT` + `JNICALL` are required so the
// linker exposes it and the JVM finds it with the right calling
// convention on every ABI.

extern "C" JNIEXPORT jstring JNICALL
Java_com_vlearn2_devid_AndroidDevID_nativeReadCpuSerial(
    JNIEnv* env,
    jclass /* clazz */) {
    const std::string serial = vlearn2::devid::read_cpu_serial();
    return env->NewStringUTF(serial.c_str());
}
