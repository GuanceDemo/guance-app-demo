import preferences from '@ohos.data.preferences';
import { Context } from '@kit.AbilityKit';

/**
 * Preferences utility class
 */
export class PreferencesUtil {
  private static preferences: preferences.Preferences | null = null;

  /**
   * Initialize Preferences
   */
  static async init(context: Context): Promise<void> {
    try {
      PreferencesUtil.preferences = await preferences.getPreferences(context, 'FT_SDK_DEMO');
    } catch (err) {
      console.error('Failed to get preferences:', JSON.stringify(err));
    }
  }

  /**
   * Save string
   */
  static async putString(key: string, value: string): Promise<void> {
    if (PreferencesUtil.preferences) {
      try {
        await PreferencesUtil.preferences.put(key, value);
        await PreferencesUtil.preferences.flush();
      } catch (err) {
        console.error('Failed to put string:', JSON.stringify(err));
      }
    }
  }

  /**
   * Get string
   */
  static async getString(key: string, defaultValue: string): Promise<string> {
    if (PreferencesUtil.preferences) {
      try {
        return await PreferencesUtil.preferences.get(key, defaultValue) as string;
      } catch (err) {
        console.error('Failed to get string:', JSON.stringify(err));
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /**
   * Save integer
   */
  static async putInt(key: string, value: number): Promise<void> {
    if (PreferencesUtil.preferences) {
      try {
        await PreferencesUtil.preferences.put(key, value);
        await PreferencesUtil.preferences.flush();
      } catch (err) {
        console.error('Failed to put int:', JSON.stringify(err));
      }
    }
  }

  /**
   * Get integer
   */
  static async getInt(key: string, defaultValue: number): Promise<number> {
    if (PreferencesUtil.preferences) {
      try {
        return await PreferencesUtil.preferences.get(key, defaultValue) as number;
      } catch (err) {
        console.error('Failed to get int:', JSON.stringify(err));
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /**
   * Save boolean
   */
  static async putBoolean(key: string, value: boolean): Promise<void> {
    if (PreferencesUtil.preferences) {
      try {
        await PreferencesUtil.preferences.put(key, value);
        await PreferencesUtil.preferences.flush();
      } catch (err) {
        console.error('Failed to put boolean:', JSON.stringify(err));
      }
    }
  }

  /**
   * Get boolean
   */
  static async getBoolean(key: string, defaultValue: boolean): Promise<boolean> {
    if (PreferencesUtil.preferences) {
      try {
        return await PreferencesUtil.preferences.get(key, defaultValue) as boolean;
      } catch (err) {
        console.error('Failed to get boolean:', JSON.stringify(err));
        return defaultValue;
      }
    }
    return defaultValue;
  }

  /**
   * Delete specified key
   */
  static async delete(key: string): Promise<void> {
    if (PreferencesUtil.preferences) {
      try {
        await PreferencesUtil.preferences.delete(key);
        await PreferencesUtil.preferences.flush();
      } catch (err) {
        console.error('Failed to delete:', JSON.stringify(err));
      }
    }
  }

  /**
   * Clear all data
   */
  static async clear(): Promise<void> {
    if (PreferencesUtil.preferences) {
      try {
        await PreferencesUtil.preferences.clear();
        await PreferencesUtil.preferences.flush();
      } catch (err) {
        console.error('Failed to clear:', JSON.stringify(err));
      }
    }
  }
}
