# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

LOCAL_PATH := $(call my-dir)
REACT_NATIVE := $(LOCAL_PATH)/../../..

include $(REACT_NATIVE)/ReactCommon/common.mk
include $(CLEAR_VARS)

LOCAL_MODULE := hermes-executor-common-release_abi43_0_0

LOCAL_SRC_FILES := $(wildcard $(LOCAL_PATH)/*.cpp)

LOCAL_C_INCLUDES := $(LOCAL_PATH) $(REACT_NATIVE)/ReactCommon/jsi $(call find-node-module,$(LOCAL_PATH),hermes-engine)/android/include
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)

LOCAL_STATIC_LIBRARIES := libjsi libjsireact
LOCAL_SHARED_LIBRARIES := libhermes_abi43_0_0

include $(BUILD_SHARED_LIBRARY)

include $(CLEAR_VARS)

LOCAL_MODULE := hermes-executor-common-debug_abi43_0_0
LOCAL_CFLAGS := -DHERMES_ENABLE_DEBUGGER=1

LOCAL_SRC_FILES := $(wildcard $(LOCAL_PATH)/*.cpp)

LOCAL_C_INCLUDES := $(LOCAL_PATH) $(REACT_NATIVE)/ReactCommon/jsi $(call find-node-module,$(LOCAL_PATH),hermes-engine)/android/include
LOCAL_EXPORT_C_INCLUDES := $(LOCAL_PATH)

LOCAL_STATIC_LIBRARIES := libjsi libjsireact libhermes-inspector_abi43_0_0
LOCAL_SHARED_LIBRARIES := libhermes_abi43_0_0

include $(BUILD_SHARED_LIBRARY)

