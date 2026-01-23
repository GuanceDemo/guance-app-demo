import { Context } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

/**
 * Utility class
 */
export class Utils {
  /**
   * Validate if it's a valid HTTP URL
   */
  static isValidHttpUrl(url: string): boolean {
    if (!url || url.trim().length === 0) {
      return false;
    }
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /**
   * Base64 decode
   */
  static base64Decode(base64Str: string): string {
    try {
      const decode = (str: string): string => {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
        let output = '';
        str = str.replace(/[^A-Za-z0-9+/=]/g, '');
        for (let i = 0; i < str.length;) {
          const enc1 = chars.indexOf(str.charAt(i++));
          const enc2 = chars.indexOf(str.charAt(i++));
          const enc3 = chars.indexOf(str.charAt(i++));
          const enc4 = chars.indexOf(str.charAt(i++));
          const chr1 = (enc1 << 2) | (enc2 >> 4);
          const chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
          const chr3 = ((enc3 & 3) << 6) | enc4;
          output += String.fromCharCode(chr1);
          if (enc3 !== 64) {
            output += String.fromCharCode(chr2);
          }
          if (enc4 !== 64) {
            output += String.fromCharCode(chr3);
          }
        }
        return output;
      };
      // Decode Base64 string to UTF-8 string
      const decodedStr = decode(base64Str);
      return decodeURIComponent(escape(decodedStr));
    } catch (err) {
      console.error('Base64 decode failed:', JSON.stringify(err));
      return '';
    }
  }

  /**
   * Base64 encode
   */
  static base64Encode(str: string): string {
    try {
      const encode = (str: string): string => {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
        let output = '';
        let i = 0;
        str = unescape(encodeURIComponent(str));
        while (i < str.length) {
          const chr1 = str.charCodeAt(i++);
          const chr2 = i < str.length ? str.charCodeAt(i++) : NaN;
          const chr3 = i < str.length ? str.charCodeAt(i++) : NaN;
          const enc1 = chr1 >> 2;
          const enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
          const enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
          const enc4 = chr3 & 63;
          if (isNaN(chr2)) {
            output += chars.charAt(enc1) + chars.charAt(enc2) + '==';
          } else if (isNaN(chr3)) {
            output += chars.charAt(enc1) + chars.charAt(enc2) + chars.charAt(enc3) + '=';
          } else {
            output += chars.charAt(enc1) + chars.charAt(enc2) + chars.charAt(enc3) + chars.charAt(enc4);
          }
        }
        return output;
      };
      return encode(str);
    } catch (err) {
      console.error('Base64 encode failed:', JSON.stringify(err));
      return '';
    }
  }

  /**
   * Generate UUID
   */
  static generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c: string): string => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  /**
   * Get current timestamp (nanoseconds)
   */
  static getCurrentNanoTime(): string {
    return Date.now() * 1000000 + '';
  }

  /**
   * Show toast message
   */
  static showToast(message: string, duration: number = 2000): void {
    promptAction.showToast({
      message: message,
      duration: duration
    });
  }
}
