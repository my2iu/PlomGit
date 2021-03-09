import 'dart:ffi';
import 'package:ffi/ffi.dart';

class git_error extends Struct {
  external Pointer<Utf8> message;

  @Int32()
  int klass;
}

class git_strarray extends Struct {
  external Pointer<Pointer<Utf8>> strings;

  @IntPtr()
  external int count;
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

// Opaque type
class git_annotated_commit extends Struct {}

// Opaque type
class git_reference extends Struct {}

// Opaque type
class git_object extends Struct {}

typedef git_credentials_acquire_cb = Int32 Function(
    Pointer<Pointer<git_credential>> out,
    Pointer<Utf8> url,
    Pointer<Utf8> username_from_url,
    Uint32 allowed_type,
    Pointer<NativeType> payload);

class git_remote_callbacks extends Struct {
  @Uint32()
  external int version;

  external Pointer<NativeFunction<Void Function()>> sideband_progress_dummy;
  external Pointer<NativeFunction<Void Function()>> completion_dummy;
  external Pointer<NativeFunction<git_credentials_acquire_cb>> credentials;
  external Pointer<NativeFunction<Void Function()>> certificate_check_dummy;
  external Pointer<NativeFunction<Void Function()>> transfer_progress_dummy;
  external Pointer<NativeFunction<Void Function()>> update_tips_dummy;
  external Pointer<NativeFunction<Void Function()>> pack_progress_dummy;
  external Pointer<NativeFunction<Void Function()>>
      push_transfer_progress_dummy;
  external Pointer<NativeFunction<Void Function()>> push_update_reference_dummy;
  external Pointer<NativeFunction<Void Function()>> push_negotiation_dummy;
  external Pointer<NativeFunction<Void Function()>> transport_dummy;
  external Pointer<NativeType> payload;
  external Pointer<NativeFunction<Void Function()>> resolve_url_dummy;
}

class git_diff_file extends Struct {
  @Int64()
  external int id_0; // Should be a 20 bytes git_oid
  @Int64()
  external int id_1;
  @Int32()
  external int id_2;

  external Pointer<Utf8> path;

  @Int64()
  external int size;

  @Uint32()
  external int flags;

  @Uint16()
  external int mode;

  @Uint16()
  external int id_abbrev;
}

class git_diff_delta extends Struct {
  @Int32()
  external int status;

  @Uint32()
  external int flags;

  @Uint16()
  external int similarity;

  @Uint16()
  external int nfiles;

  // (this should be a nested struct)
  @Int64()
  external int old_file_id_0; // Should be a 20 bytes git_oid
  @Int64()
  external int old_file_id_1;
  @Int32()
  external int old_file_id_2;

  Pointer<Utf8> old_file_path;

  @Int64()
  external int old_file_size;

  @Uint32()
  external int old_file_flags;

  @Uint16()
  external int old_file_mode;

  @Uint16()
  external int old_file_id_abbrev;

  // (this should be a nested struct)
  @Int64()
  external int new_file_id_0; // Should be a 20 bytes git_oid
  @Int64()
  external int new_file_id_1;
  @Int32()
  external int new_file_id_2;

  Pointer<Utf8> new_file_path;

  @Int64()
  external int new_file_size;

  @Uint32()
  external int new_file_flags;

  @Uint16()
  external int new_file_mode;

  @Uint16()
  external int new_file_id_abbrev;
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
  external int id_0; // Should be a 20 bytes git_oid
  @Int64()
  external int id_1;
  @Int32()
  external int id_2;
}

class git_signature extends Struct {
  external Pointer<Utf8> name;
  external Pointer<Utf8> email;
  @Int64()
  external int when_time;
  @Int32()
  external int when_offset;
  @Int8()
  external int when_sign;
}

class git_buf extends Struct {
  external Pointer<Utf8> ptr;
  @IntPtr()
  external int asize;
  @IntPtr()
  external int size;
}
