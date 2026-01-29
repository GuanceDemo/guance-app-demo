#include "CrashTest.h"
#include <napi/native_api.h>

// N-API wrapper for null pointer crash
static napi_value TriggerNullPointerCrash(napi_env env, napi_callback_info info) {
    ftcrash::CrashTest::triggerNullPointerCrash();
    return nullptr;
}

// N-API wrapper for division by zero crash
static napi_value TriggerDivisionByZero(napi_env env, napi_callback_info info) {
    ftcrash::CrashTest::triggerDivisionByZero();
    return nullptr;
}

// N-API wrapper for abort crash
static napi_value TriggerAbort(napi_env env, napi_callback_info info) {
    ftcrash::CrashTest::triggerAbort();
    return nullptr;
}

// N-API wrapper for wild pointer crash
static napi_value TriggerWildPointer(napi_env env, napi_callback_info info) {
    ftcrash::CrashTest::triggerWildPointer();
    return nullptr;
}

// N-API wrapper for pure virtual call crash
static napi_value TriggerPureVirtualCall(napi_env env, napi_callback_info info) {
    ftcrash::CrashTest::triggerPureVirtualCall();
    return nullptr;
}

// Module initialization
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"triggerNullPointerCrash", nullptr, TriggerNullPointerCrash, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"triggerDivisionByZero", nullptr, TriggerDivisionByZero, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"triggerAbort", nullptr, TriggerAbort, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"triggerWildPointer", nullptr, TriggerWildPointer, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"triggerPureVirtualCall", nullptr, TriggerPureVirtualCall, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

// Module registration
static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "ftcrash",
    .nm_priv = ((void*)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterFTCrashModule(void) {
    napi_module_register(&demoModule);
}
