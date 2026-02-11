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
   * Get current timestamp (nanoseconds)
   */
  static getCurrentNanoTime(): string {
    return Date.now() * 1000000 + '';
  }
}
