#!/bin/bash

set -ex

export TF_NEED_MKL=0
export BAZEL_MKL_OPT=""
export BAZEL_OPTS=""

if [[ ${HOST} =~ .*darwin.* ]]; then

  # set up bazel config file for conda provided clang toolchain
  #cp -r ${RECIPE_DIR}/custom_clang_toolchain .
  #cd custom_clang_toolchain
  #sed -e "s:\${CLANG}:${CLANG}:" \
  #    -e "s:\${INSTALL_NAME_TOOL}:${INSTALL_NAME_TOOL}:" \
  #    -e "s:\${CONDA_BUILD_SYSROOT}:${CONDA_BUILD_SYSROOT}:" \
  #    cc_wrapper.sh.template > cc_wrapper.sh
  #chmod +x cc_wrapper.sh
  #sed -e "s:\${PREFIX}:${BUILD_PREFIX}:" \
  #    -e "s:\${LD}:${LD}:" \
  #    -e "s:\${NM}:${NM}:" \
  #    -e "s:\${STRIP}:${STRIP}:" \
  #    -e "s:\${LIBTOOL}:${LIBTOOL}:" \
  #    -e "s:\${CONDA_BUILD_SYSROOT}:${CONDA_BUILD_SYSROOT}:" \
  #    CROSSTOOL.template > CROSSTOOL
  #cd ..

  # set build arguments
  export  BAZEL_USE_CPP_ONLY_TOOLCHAIN=1
  BUILD_OPTS="
      --crosstool_top=//custom_clang_toolchain:toolchain
      --verbose_failures
      ${BAZEL_MKL_OPT}
      --config=opt"
  export TF_ENABLE_XLA=0
else
  # Linux
  # the following arguments are useful for debugging
  #    --logging=6
  #    --subcommands
  # jobs can be used to limit parallel builds and reduce resource needs
  #    --jobs=20
  # Set compiler and linker flags as bazel does not account for CFLAGS,
  # CXXFLAGS and LDFLAGS.
  BUILD_OPTS="
  --copt=-march=nocona
  --copt=-mtune=haswell
  --copt=-ftree-vectorize
  --copt=-fPIC
  --copt=-fstack-protector-strong
  --copt=-O2
  --cxxopt=-fvisibility-inlines-hidden
  --cxxopt=-fmessage-length=0
  --linkopt=-zrelro
  --linkopt=-znow
  --verbose_failures
  ${BAZEL_MKL_OPT}
  --config=opt"
  export TF_ENABLE_XLA=1
fi

if [[ ${HOST} =~ "2*" ]]; then
    BUILD_OPTS="$BUILD_OPTS --config=v2"
fi

# Python Settings
export PYTHON_BIN_PATH=${PYTHON}
export PYTHON_LIB_PATH=${SP_DIR}
export USE_DEFAULT_PYTHON_LIB_PATH=1

# additional settings
export CC_OPT_FLAGS="-march=nocona -mtune=haswell"
export TF_NEED_OPENCL=0
export TF_NEED_OPENCL_SYCL=0
export TF_NEED_COMPUTECPP=0
export TF_NEED_CUDA=0
export TF_CUDA_CLANG=0
export TF_NEED_TENSORRT=0
export TF_NEED_ROCM=0
export TF_NEED_MPI=0
export TF_DOWNLOAD_CLANG=0
export TF_SET_ANDROID_WORKSPACE=0

./configure

# build using bazel

bazel ${BAZEL_OPTS} build ${BUILD_OPTS} //tensorflow/tools/pip_package:build_pip_package

# build a whl file
mkdir -p $SRC_DIR/tensorflow_pkg
bazel-bin/tensorflow/tools/pip_package/build_pip_package $SRC_DIR/tensorflow_pkg

# install the whl using pip
pip install --no-deps $SRC_DIR/tensorflow_pkg/*.whl

# The tensorboard package has the proper entrypoint
rm -f ${PREFIX}/bin/tensorboard