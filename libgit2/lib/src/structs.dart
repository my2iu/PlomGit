import 'dart:ffi';
import 'package:ffi/ffi.dart';

// class git_error extends Struct {
//   external Pointer<Utf8> message;

//   @Int32()
//   external int klass;
// }

// class git_strarray extends Struct {
//   external Pointer<Pointer<Utf8>> strings;

//   @IntPtr()
//   external int count;
// }

// Opaque types
class git_remote extends Opaque {}

// class git_repository extends Opaque {}

class git_status_list extends Opaque {}

class git_credential extends Opaque {}

class git_index extends Opaque {}

class git_tree extends Opaque {}

class git_commit extends Opaque {}

class git_annotated_commit extends Opaque {}

// class git_reference extends Opaque {}

class git_object extends Opaque {}

// class git_repository_init_options extends Opaque {}

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

  external Pointer<Utf8> old_file_path;

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

  external Pointer<Utf8> new_file_path;

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
  external int status;

  external Pointer<git_diff_delta> head_to_index;
  external Pointer<git_diff_delta> index_to_workdir;
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

// class git_buf extends Struct {
//   external Pointer<Utf8> ptr;
//   @IntPtr()
//   external int asize;
//   @IntPtr()
//   external int size;
// }
