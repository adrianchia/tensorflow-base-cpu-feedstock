load("@bazel_tools//tools/build_defs/cc:action_names.bzl", "ACTION_NAMES")
load(
  "@bazel_tools//tools/cpp:cc_toolchain_config_lib.bzl",
  "feature",
  "flag_group",
  "flag_set",
  "tool_path",
  "with_feature_set",
)

def all_assembly_actions():
  return [
    ACTION_NAMES.assemble,
    ACTION_NAMES.preprocess_assemble,
  ]

def all_compile_actions():
  return [
    ACTION_NAMES.assemble,
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.preprocess_assemble,
  ]

def all_cpp_compile_actions():
  return [
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.linkstamp_compile,
  ]

def all_preprocessed_actions():
  return [
    ACTION_NAMES.c_compile,
    ACTION_NAMES.cpp_compile,
    ACTION_NAMES.cpp_header_parsing,
    ACTION_NAMES.cpp_module_codegen,
    ACTION_NAMES.cpp_module_compile,
    ACTION_NAMES.linkstamp_compile,
    ACTION_NAMES.preprocess_assemble,
  ]

def all_c_compile_actions():
  return [
    ACTION_NAMES.c_compile,
  ]

def all_link_actions():
  return [
    ACTION_NAMES.cpp_link_executable,
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
]

def all_executable_link_actions():
  return [
    ACTION_NAMES.cpp_link_executable,
  ]

def all_shared_library_link_actions():
  return [
    ACTION_NAMES.cpp_link_dynamic_library,
    ACTION_NAMES.cpp_link_nodeps_dynamic_library,
  ]

def all_archive_actions():
  return [ACTION_NAMES.cpp_link_static_library]

def all_strip_actions():
  return [ACTION_NAMES.strip]

def _impl(ctx):
  tool_paths = [

    tool_path(
      name = "ld",
      path = "${LD}",
    ),

    tool_path(
      name = "cpp",
      path = "/usr/bin/cpp",
    ),
    tool_path(
      name = "dwp",
      path = "/usr/bin/dwp",
    ),
    tool_path(
      name = "gcov",
      path = "/usr/bin/gcov",
    ),

    tool_path(
      name = "nm",
      path = "${NM}",
    ),
    tool_path(
      name = "objcopy",
      path = "/usr/bin/objcopy",
    ),
    tool_path(
      name = "objdump",
      path = "/usr/bin/objdump",
    ),
    tool_path(
      name = "strip",
      path = "${STRIP}",
    ),
    tool_path(
      name = "gcc",
      path = "cc_wrapper.sh",
    ),
    tool_path(
      name = "ar",
      path = "${LIBTOOL}",
    ),
  ]

  features = [
    # see https://docs.google.com/document/d/1uv4c1zag6KvdI31qdx8C6jiTognXPQrxgsUpVefm9fM/edit# and
    # https://github.com/bazelbuild/bazel/issues/6861
    feature(
      name = "compiler_flag",
      enabled = True,
      flag_sets = [
        flag_set (
          actions = all_compile_actions(),
          flag_groups = ([
            flag_group(
              flags = [
                "-march=core2",
                "-mtune=haswell",
                "-mssse3",
                "-ftree-vectorize",
                "-fPIC",
                "-fPIE",
                "-fstack-protector-strong",
                "-O1",
                "-pipe"
              ]
            )
          ])
        ),
        flag_set (
          actions = all_compile_actions(),
          flag_groups = ([
            flag_group(
              flags = [
                "-g"
              ]
            )
          ]),
          with_features = [
            with_feature_set(
              features = ["dbg"]
            )
          ]
        ),
        flag_set (
          actions = all_compile_actions(),
          flag_groups = ([
            flag_group(
              flags = [
                "-g0",
                "-O1",
                "-D_FORTIFY_SOURCE=1",
                "-DNDEBUG",
                "-ffunction-sections",
                "-fdata-sections",
              ]
            )
          ]),
          with_features = [
            with_feature_set(
              features = ["opt"]
            )
          ]
        )
      ]
    ),
    feature(
      name = "cxx_flag",
      enabled = True,
      flag_sets = [
        flag_set (
          actions = all_cpp_compile_actions(),
          flag_groups = ([
            flag_group(
              flags = [
                "-stdlib=libc++",
                "-fvisibility-inlines-hidden",
                "-std=c++14",
                "-fmessage-length=0"
              ]
            )
          ])
        )
      ]
    ),
    feature(
      name = "unfiltered_compile_flags",
      enabled = True,
      flag_sets = [
        flag_set (
          actions = all_compile_actions(),
          flag_groups = ([
            flag_group(
              flags = [
                "-no-canonical-prefixes",
                "-Wno-builtin-macro-redefined",
                "-D__DATE__=\"redacted\"",
                "-D__TIMESTAMP__=\"redacted\"",
                "-D__TIME__=\"redacted\""
              ],
            )
          ]),
        )
      ]
    ),
    feature(
      name = "objcopy_embed_flag",
      enabled = True,
      flag_sets = [
        flag_set (
          actions = all_assembly_actions(),
          flag_groups = ([
            flag_group(
              flags = [
                "-I",
                "binary"
              ],
            )
          ]),
        )
      ]
    ),
    feature(
      name = "linker_flag",
      enabled = True,
      flag_sets = [
        flag_set (
          actions = all_link_actions(),
          flag_groups = ([
            flag_group(
              flags = [
                "-Wl,-pie",
                "-headerpad_max_install_names",
                "-Wl,-dead_strip_dylibs",
                "-lc++",
                "-undefined",
                "dynamic_lookup"
              ],
            )
          ]),
        )
      ]
    ),
    # replaces needsPic: True
    feature(
      name="supports_pic",
      enabled = True,
    ),
    # replace supports_interface_shared_objects
    feature(
      name="supports_interface_shared_libraries",
      enabled = False,
    ),
    # replaces supports_fission
    feature(
      name="supports_fission",
      enabled = False,
    ),
    # replace supports_start_end_lib
    feature(
      name="supports_start_end_lib",
      enabled = False,
    ),
    # replaces linking_mode_flags: DYNAMIC
    feature(
      name="dynamic_linking_mode",
      enabled=True,
    )
  ]

  return cc_common.create_cc_toolchain_config_info(
    ctx = ctx,
    features = features,
    cxx_builtin_include_directories = [
      "${PREFIX}/include/c++/v1",
      "${PREFIX}/lib/clang/4.0.1/include",
      "${CONDA_BUILD_SYSROOT}/usr/include",
      "${CONDA_BUILD_SYSROOT}/System/Library/Frameworks",
    ],
    toolchain_identifier = "local",
    abi_version = "local",
    abi_libc_version = "local",
    builtin_sysroot = "",
    compiler = "compiler",
    host_system_name = "local",
    target_libc = "macosx",
    target_cpu = "darwin",
    target_system_name = "local",
    tool_paths = tool_paths,
  )

cc_toolchain_config = rule(
  implementation = _impl,
  attrs = {},
  provides = [CcToolchainConfigInfo],
)
