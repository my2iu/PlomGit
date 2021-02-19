#include "android_jni.h"
#include "common.h"

JavaVM* gJvm;
struct JavaVMAttachArgs defaultJvmAttachArgs;

jclass jGitHttpClientClass;

static void JNICALL jgit_set_error(JNIEnv *env, jobject thisObj, jint klass, jstring msg)
{
   const char *str = (*env)->GetStringUTFChars(env, msg, NULL);
   if (NULL == str) return;

   git_error_set((int)klass, "%s", str);

   (*env)->ReleaseStringUTFChars(env, msg, str);  
}

JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved)
{
    gJvm = vm;
    defaultJvmAttachArgs.version = JNI_VERSION_1_2;
    defaultJvmAttachArgs.name = NULL;
    defaultJvmAttachArgs.group = NULL;

    // We only have access to the proper app classloader from here, so
    // we need to grab references to all the classes we want to access
    // now. (Later on, we'll be called from Flutter's native code, so
    // we won't have a proper classloader to access Java code.)
    JNIEnv *env;
    (*gJvm)->GetEnv(gJvm, &env, JNI_VERSION_1_6);
    jclass localClass = (*env)->FindClass(env, "com/example/libgit2/GitHttpClient");
    jGitHttpClientClass = (jclass)((*env)->NewGlobalRef(env, localClass));

    static const JNINativeMethod methods[] = {
        {"gitErrorSet", "(ILjava/lang/String;)V", (void*)(jgit_set_error)},
    };
    int rc = (*env)->RegisterNatives(env, jGitHttpClientClass, methods, 1);
    if (rc != JNI_OK) return rc;

    return JNI_VERSION_1_6;
}

static int envFromAttach = 0;

JNIEnv *getJvmEnv(void)
{
    JNIEnv *env;
    envFromAttach = 0;
    (*gJvm)->GetEnv(gJvm, &env, JNI_VERSION_1_6);
    if (env != NULL) return env;
    envFromAttach = 1;
    (*gJvm)->AttachCurrentThread(gJvm, &env, &defaultJvmAttachArgs);
    return env;
}

void releaseJvmEnv(void)
{
    if (envFromAttach)
        (*gJvm)->DetachCurrentThread(gJvm);
}