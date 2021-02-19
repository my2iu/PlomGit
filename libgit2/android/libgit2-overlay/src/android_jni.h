#ifndef INCLUDE_android_jni_h__
#define INCLUDE_android_jni_h__

#include <jni.h>

extern JavaVM* gJvm;

// For getting access to JNI
JNIEnv *getJvmEnv(void);
void releaseJvmEnv(void);

// Cached versions of classes we may need access to
extern jclass jGitHttpClientClass;

#endif