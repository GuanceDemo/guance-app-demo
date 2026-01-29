/**
 * Type declarations for FT Crash Native Module
 */
declare module 'libftcrash.so' {
  /**
   * Trigger null pointer dereference crash
   */
  export function triggerNullPointerCrash(): void;

  /**
   * Trigger division by zero crash
   */
  export function triggerDivisionByZero(): void;

  /**
   * Trigger abort crash
   */
  export function triggerAbort(): void;

  /**
   * Trigger wild pointer crash
   */
  export function triggerWildPointer(): void;

  /**
   * Trigger pure virtual call crash
   */
  export function triggerPureVirtualCall(): void;
}
