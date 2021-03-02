import 'dart:ffi';
import 'package:ffi/ffi.dart';

class git_error extends Struct {
  Pointer<Utf8> message;

  @Int32()
  int klass;
}

class git_strarray extends Struct {
  Pointer<Pointer<Utf8>> strings;

  @IntPtr()
  int count;
}

// Opaque type
class git_remote extends Struct {}

// Opaque type
class git_repository extends Struct {}

// Opaque type
class git_status_list extends Struct {}

// Opaque type
class git_credential extends Struct {}

// Opaque type
class git_index extends Struct {}

// Opaque type
class git_tree extends Struct {}

// Opaque type
class git_commit extends Struct {}

typedef git_credentials_acquire_cb = Int32 Function(
    Pointer<Pointer<git_credential>> out,
    Pointer<Utf8> url,
    Pointer<Utf8> username_from_url,
    Uint32 allowed_type,
    Pointer<NativeType> payload);

class git_remote_callbacks extends Struct {
  @Uint32()
  int version;

  Pointer<NativeFunction<Void Function()>> sideband_progress_dummy;
  Pointer<NativeFunction<Void Function()>> completion_dummy;
  Pointer<NativeFunction<git_credentials_acquire_cb>> credentials;
  Pointer<NativeFunction<Void Function()>> certificate_check_dummy;
  Pointer<NativeFunction<Void Function()>> transfer_progress_dummy;
  Pointer<NativeFunction<Void Function()>> update_tips_dummy;
  Pointer<NativeFunction<Void Function()>> pack_progress_dummy;
  Pointer<NativeFunction<Void Function()>> push_transfer_progress_dummy;
  Pointer<NativeFunction<Void Function()>> push_update_reference_dummy;
  Pointer<NativeFunction<Void Function()>> push_negotiation_dummy;
  Pointer<NativeFunction<Void Function()>> transport_dummy;
  Pointer<NativeType> payload;
  Pointer<NativeFunction<Void Function()>> resolve_url_dummy;
}

class git_diff_file extends Struct {
  @Int64()
  int id_0; // Should be a 20 bytes git_oid
  @Int64()
  int id_1;
  @Int32()
  int id_2;

  Pointer<Utf8> path;

  @Int64()
  int size;

  @Uint32()
  int flags;

  @Uint16()
  int mode;

  @Uint16()
  int id_abbrev;
}

class git_diff_delta extends Struct {
  @Int32()
  int status;

  @Uint32()
  int flags;

  @Uint16()
  int similarity;

  @Uint16()
  int nfiles;

  // (this should be a nested struct)
  @Int64()
  int old_file_id_0; // Should be a 20 bytes git_oid
  @Int64()
  int old_file_id_1;
  @Int32()
  int old_file_id_2;

  Pointer<Utf8> old_file_path;

  @Int64()
  int old_file_size;

  @Uint32()
  int old_file_flags;

  @Uint16()
  int old_file_mode;

  @Uint16()
  int old_file_id_abbrev;

  // (this should be a nested struct)
  @Int64()
  int new_file_id_0; // Should be a 20 bytes git_oid
  @Int64()
  int new_file_id_1;
  @Int32()
  int new_file_id_2;

  Pointer<Utf8> new_file_path;

  @Int64()
  int new_file_size;

  @Uint32()
  int new_file_flags;

  @Uint16()
  int new_file_mode;

  @Uint16()
  int new_file_id_abbrev;
}

class git_status_entry extends Struct {
  @Int32()
  int status;

  Pointer<git_diff_delta> head_to_index;
  Pointer<git_diff_delta> index_to_workdir;

  // GIT_STATUS_CURRENT = 0,

  // GIT_STATUS_INDEX_NEW        = (1u << 0),
  // GIT_STATUS_INDEX_MODIFIED   = (1u << 1),
  // GIT_STATUS_INDEX_DELETED    = (1u << 2),
  // GIT_STATUS_INDEX_RENAMED    = (1u << 3),
  // GIT_STATUS_INDEX_TYPECHANGE = (1u << 4),

  // GIT_STATUS_WT_NEW           = (1u << 7),
  // GIT_STATUS_WT_MODIFIED      = (1u << 8),
  // GIT_STATUS_WT_DELETED       = (1u << 9),
  // GIT_STATUS_WT_TYPECHANGE    = (1u << 10),
  // GIT_STATUS_WT_RENAMED       = (1u << 11),
  // GIT_STATUS_WT_UNREADABLE    = (1u << 12),

  // GIT_STATUS_IGNORED          = (1u << 14),
  // GIT_STATUS_CONFLICTED       = (1u << 15),
}

class git_oid extends Struct {
  @Int64()
  int id_0; // Should be a 20 bytes git_oid
  @Int64()
  int id_1;
  @Int32()
  int id_2;
}

class git_signature extends Struct {
  Pointer<Utf8> name;
  Pointer<Utf8> email;
  @Int64()
  int when_time;
  @Int32()
  int when_offset;
  @Int8()
  int when_sign;
}
