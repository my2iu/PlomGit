#ifndef INCLUDE_android_jni_h__
#define INCLUDE_android_jni_h__

#include <jni.h>

extern JavaVM* gJvm;

// For getting access to JNI
JNIEnv *getJvmEnv(void);
void releaseJvmEnv(void);

// Just for some quick internal debugging. Should not be called
// when the JVMEnv is already in use.
void tempDebugJvmLog(char * message);

void debugJvmLog(JNIEnv * env, char * message);

// Cached versions of classes we may need access to
extern jclass jGitHttpClientClass;

#endif