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


// Some extra functions for interfacing with libgit2

GIT_EXTERN(int) git_fetch_options_size(void) {
  return sizeof(git_fetch_options);
}

GIT_EXTERN(int) git_push_options_size(void) {
  return sizeof(git_push_options);
}

GIT_EXTERN(int) git_status_options_size(void) {
  return sizeof(git_status_options);
}

GIT_EXTERN(int) git_clone_options_size(void) {
  return sizeof(git_clone_options);
}

GIT_EXTERN(int) git_fetch_options_version(void) {
  return GIT_FETCH_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_push_options_version(void) {
  return GIT_PUSH_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_status_options_version(void) {
  return GIT_STATUS_OPTIONS_VERSION;
}

GIT_EXTERN(int) git_clone_options_version(void) {
  return GIT_CLONE_OPTIONS_VERSION;
}

GIT_EXTERN(void) git_fetch_options_set_credentials_cb(git_fetch_options *opts, git_credential_acquire_cb *credentials_cb) {
  opts->callbacks.credentials = credentials_cb;
}

GIT_EXTERN(void) git_push_options_set_credentials_cb(git_push_options *opts, git_credential_acquire_cb *credentials_cb) {
  opts->callbacks.credentials = credentials_cb;
}

GIT_EXTERN(void) git_clone_options_set_credentials_cb(git_clone_options *opts, git_credential_acquire_cb *credentials_cb) {
  opts->fetch_opts.callbacks.credentials = credentials_cb;
}

GIT_EXTERN(void) git_status_options_config(git_status_options * opts, const char **path) {
  if (path != NULL) {
    opts->pathspec.count = 1;
    opts->pathspec.strings = path;
  }
  opts->show = GIT_STATUS_SHOW_INDEX_AND_WORKDIR;
	opts->flags = GIT_STATUS_OPT_INCLUDE_UNTRACKED |
		GIT_STATUS_OPT_RECURSE_UNTRACKED_DIRS |
		GIT_STATUS_OPT_INCLUDE_UNMODIFIED;
}