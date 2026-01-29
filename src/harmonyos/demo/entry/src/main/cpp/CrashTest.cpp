#include "CrashTest.h"
#include <functional>
#include <cstdlib>

namespace ftcrash {

// Trigger null pointer dereference crash
void CrashTest::triggerNullPointerCrash() {
    int* nullPtr = nullptr;
    *nullPtr = 42;  // This will cause SIGSEGV
}

// Trigger division by zero crash
void CrashTest::triggerDivisionByZero() {
    volatile int divisor = 0;
    volatile int result = 100 / divisor;  // This will cause SIGFPE
    (void)result;  // Suppress unused warning
}

// Trigger stack overflow crash
void CrashTest::triggerStackOverflow() {
    // Recursive function to cause stack overflow
    std::function<void()> recursive = [&]() {
        volatile char buffer[1024 * 1024];  // Allocate 1MB on stack each call
        (void)buffer;
        recursive();  // Recursive call
    };
    recursive();
}

// Trigger abort crash
void CrashTest::triggerAbort() {
    std::abort();  // This will cause SIGABRT
}

// Trigger segmentation violation via wild pointer
void CrashTest::triggerWildPointer() {
    // Use an invalid memory address
    int* wildPtr = reinterpret_cast<int*>(0xDEADBEEF);
    *wildPtr = 123;
}

// Trigger pure virtual function call crash
class Base {
public:
    Base() {}
    virtual void pureVirtual() = 0;
    void callPureVirtual() {
        pureVirtual();  // Call pure virtual in constructor/destructor context
    }
};

class Derived : public Base {
public:
    Derived() : Base() {
        // This will be called before Derived's vtable is set up
        callPureVirtual();
    }
    void pureVirtual() override {
        // Never reached
    }
};

void CrashTest::triggerPureVirtualCall() {
    Derived derived;  // Crash during construction
}

} // namespace ftcrash
