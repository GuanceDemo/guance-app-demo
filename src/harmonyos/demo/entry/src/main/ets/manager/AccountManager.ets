import { UserData as LocalUserData } from '../model/UserData';
import { PreferencesUtil } from '../utils/PreferencesUtil';
import { HttpEngine } from '../http/HttpEngine';
import { SettingConfigManager } from '../manager/SettingConfigManager';
import { FTSDK } from 'ft_sdk/src/main/ets/components/FTSDK';
import { FTLogger } from 'ft_sdk/src/main/ets/components/log/FTLogger';
import { Status } from 'ft_sdk/src/main/ets/components/bean/Status';
import { UserData as FTUserData } from 'ft_sdk/src/main/ets/components/rum/bean/UserData';
import {
  KEY_USER_AVATAR,
  KEY_USER_EMAIL,
  KEY_USER_NAME,
  PREFS_USER_DATA_NAME,
  DEFAULT_API_ADDRESS
} from '../constants/Constant';

/**
 * Login result interface
 */
interface LoginResult {
  success: boolean;
  errorMessage?: string;
}

/**
 * Account manager
 */
export class AccountManager {
  private static userData: LocalUserData | null = null;
  private static isLogin: boolean = false;

  /**
   * Check login status
   */
  static async checkLogin(): Promise<boolean> {
    if (AccountManager.userData === null) {
      AccountManager.userData = await AccountManager.readUserData();
    }

    AccountManager.isLogin = !AccountManager.userData.isEmpty();

    // If logged in, bind user data to RUM
    if (AccountManager.isLogin && AccountManager.userData) {
      AccountManager.bindUserDataToRUM(AccountManager.userData);
    }

    return AccountManager.isLogin;
  }

  /**
   * Login
   */
  static async login(username: string, password: string): Promise<LoginResult> {
    try {
      // Initialize HttpEngine API address
      const setting = await SettingConfigManager.readSetting();
      if (setting.demoApiAddress) {
        HttpEngine.initAPIAddress(setting.demoApiAddress);
      } else {
        HttpEngine.initAPIAddress(DEFAULT_API_ADDRESS);
      }

      const result = await HttpEngine.login(username, password);
      if (result.code === 200) {
        AccountManager.isLogin = true;
        await AccountManager.getUserInfo();
        return { success: true };
      } else {
        return { success: false, errorMessage: result.errorMessage };
      }
    } catch (err) {
      return { success: false, errorMessage: 'Login failed' };
    }
  }

  /**
   * Get user info
   */
  static async getUserInfo(): Promise<boolean> {
    try {
      const data = await HttpEngine.userinfo();
      if (!data.isEmpty()) {
        AccountManager.userData = data;
        await AccountManager.saveUserData(data);

        // Bind user data to RUM after successful login
        AccountManager.bindUserDataToRUM(data);

        return true;
      }
      return false;
    } catch (err) {
      console.error('Failed to get user info:', JSON.stringify(err));
      return false;
    }
  }

  /**
   * Bind user data to RUM
   * This is an important feature of Guance SDK for associating user information with RUM data
   */
  private static bindUserDataToRUM(data: LocalUserData): void {
    try {
      if (data.isEmpty()) {
        console.warn('UserData is empty, skip binding');
        return;
      }

      // Use SDK's UserData class for binding
      const userData = new FTUserData();
      userData.setId(data.username);
      userData.setName(data.username);
      if (data.email) {
        userData.setEmail(data.email);
      }

      // Set user extended information
      const exts: Record<string, string> = {
        'user_avatar': data.avatar || '',
        'user_type': 'vip',
        'login_platform': 'harmonyos'
      };
      userData.setExts(exts);

      // Bind user data (async operation)
      FTSDK.bindRumUserData(userData).then(() => {
        console.info('User data bound to RUM successfully');
        FTLogger.logBackground('User bound: ' + data.username, Status.INFO);
      }).catch((error: Error) => {
        console.error('Failed to bind user data to RUM:', error.message);
        FTLogger.logBackground('Failed to bind user data: ' + error.message, Status.ERROR);
      });

    } catch (error) {
      console.error('Error binding user data to RUM:', JSON.stringify(error));
    }
  }

  /**
   * Initialize HttpEngine
   */
  static async initHttpEngine(): Promise<void> {
    try {
      const setting = await SettingConfigManager.readSetting();
      if (setting.demoApiAddress) {
        HttpEngine.initAPIAddress(setting.demoApiAddress);
      } else {
        HttpEngine.initAPIAddress(DEFAULT_API_ADDRESS);
      }
    } catch (err) {
      console.error('Failed to init HttpEngine:', JSON.stringify(err));
      HttpEngine.initAPIAddress(DEFAULT_API_ADDRESS);
    }
  }

  /**
   * Save user data
   */
  private static async saveUserData(data: LocalUserData): Promise<void> {
    try {
      await PreferencesUtil.putString(PREFS_USER_DATA_NAME + '_' + KEY_USER_NAME, data.username);
      await PreferencesUtil.putString(PREFS_USER_DATA_NAME + '_' + KEY_USER_EMAIL, data.email);
      await PreferencesUtil.putString(PREFS_USER_DATA_NAME + '_' + KEY_USER_AVATAR, data.avatar);
    } catch (err) {
      console.error('Failed to save user data:', JSON.stringify(err));
    }
  }

  /**
   * Read user data
   */
  private static async readUserData(): Promise<LocalUserData> {
    try {
      const username = await PreferencesUtil.getString(PREFS_USER_DATA_NAME + '_' + KEY_USER_NAME, '');
      const email = await PreferencesUtil.getString(PREFS_USER_DATA_NAME + '_' + KEY_USER_EMAIL, '');
      const avatar = await PreferencesUtil.getString(PREFS_USER_DATA_NAME + '_' + KEY_USER_AVATAR, '');
      return new LocalUserData(username, email, avatar);
    } catch (err) {
      console.error('Failed to read user data:', JSON.stringify(err));
      return new LocalUserData();
    }
  }

  /**
   * Clear user data
   */
  private static async cleanUserData(): Promise<void> {
    try {
      await PreferencesUtil.delete(PREFS_USER_DATA_NAME + '_' + KEY_USER_NAME);
      await PreferencesUtil.delete(PREFS_USER_DATA_NAME + '_' + KEY_USER_EMAIL);
      await PreferencesUtil.delete(PREFS_USER_DATA_NAME + '_' + KEY_USER_AVATAR);
    } catch (err) {
      console.error('Failed to clean user data:', JSON.stringify(err));
    }
  }

  /**
   * Logout
   */
  static async logout(): Promise<void> {
    // Unbind user data (Important: need to unbind when user logs out)
    try {
      await FTSDK.unbindRumUserData();
      console.info('User data unbound from RUM');
      FTLogger.logBackground('User unbound', Status.INFO);
    } catch (error) {
      const errorObj: Error = error as Error;
      console.error('Failed to unbind user data:', errorObj.message);
    }

    AccountManager.isLogin = false;
    await AccountManager.cleanUserData();
    AccountManager.userData = null;
  }

  /**
   * Get current user data
   */
  static getUserData(): LocalUserData | null {
    return AccountManager.userData;
  }
}
