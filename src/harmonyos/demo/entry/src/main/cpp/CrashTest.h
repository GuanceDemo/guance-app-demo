#ifndef CRASH_TEST_H
#define CRASH_TEST_H

#include <functional>

namespace ftcrash {

class CrashTest {
public:
    // Trigger null pointer dereference crash
    static void triggerNullPointerCrash();

    // Trigger division by zero crash
    static void triggerDivisionByZero();

    // Trigger stack overflow crash
    static void triggerStackOverflow();

    // Trigger abort crash
    static void triggerAbort();

    // Trigger segmentation violation via wild pointer
    static void triggerWildPointer();

    // Trigger pure virtual function call crash
    static void triggerPureVirtualCall();
};

} // namespace ftcrash

#endif // CRASH_TEST_H
