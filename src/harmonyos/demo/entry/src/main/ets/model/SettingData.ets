import { SessionReplayPrivacy } from '../constants/SessionReplayPrivacy';
import { API_USER_INFO } from '../constants/Constant';
import { JsonObject } from './UserData';

/**
 * Settings data model
 */
export class SettingData {
  datakitAddress: string;
  demoApiAddress: string;
  appId: string;
  datawayAddress: string;
  datawayClientToken: string;
  otelAddress: string;
  type: number; // AccessType
  enableSessionReplay: boolean;
  sessionReplayPrivacyType: SessionReplayPrivacy;

  constructor(
    datakitAddress: string = '',
    demoApiAddress: string = '',
    appId: string = '',
    datawayAddress: string = '',
    datawayClientToken: string = '',
    otelAddress: string = '',
    type: number = 0,
    enableSessionReplay: boolean = false,
    sessionReplayPrivacyType: SessionReplayPrivacy = SessionReplayPrivacy.ALLOW
  ) {
    this.datakitAddress = datakitAddress;
    this.demoApiAddress = demoApiAddress;
    this.appId = appId;
    this.datawayAddress = datawayAddress;
    this.datawayClientToken = datawayClientToken;
    this.otelAddress = otelAddress;
    this.type = type;
    this.enableSessionReplay = enableSessionReplay;
    this.sessionReplayPrivacyType = sessionReplayPrivacyType;
  }

  /**
   * Get user info URL
   */
  getUserInfoUrl(): string {
    return this.demoApiAddress + API_USER_INFO;
  }

  /**
   * Create SettingData from JSON object
   */
  static fromJson(json: JsonObject): SettingData | null {
    try {
      const data = new SettingData();
      data.datakitAddress = json.getString('datakitAddress');
      data.demoApiAddress = json.getString('demoApiAddress');
      data.appId = json.getString('appId');
      data.datawayAddress = json.getString('datawayAddress');
      data.datawayClientToken = json.getString('datawayClientToken');
      data.otelAddress = json.getString('otelAddress');
      data.type = json.getNumber('type');
      data.enableSessionReplay = json.getBoolean('enableSessionReplay');
      data.sessionReplayPrivacyType = json.getNumber('sessionReplayPrivacyType') as SessionReplayPrivacy ||
        SessionReplayPrivacy.ALLOW;
      return data;
    } catch (err) {
      console.error('Failed to parse SettingData from JSON:', JSON.stringify(err));
      return null;
    }
  }

  /**
   * Convert to JSON object
   */
  toJson(): JsonObject {
    const obj = new JsonObject();
    obj.set('datakitAddress', this.datakitAddress);
    obj.set('demoApiAddress', this.demoApiAddress);
    obj.set('appId', this.appId);
    obj.set('datawayAddress', this.datawayAddress);
    obj.set('datawayClientToken', this.datawayClientToken);
    obj.set('otelAddress', this.otelAddress);
    obj.set('type', this.type);
    obj.set('enableSessionReplay', this.enableSessionReplay);
    obj.set('sessionReplayPrivacyType', this.sessionReplayPrivacyType);
    return obj;
  }

  /**
   * Convert to JSON string
   */
  toJsonString(): string {
    return JSON.stringify({
      datakitAddress: this.datakitAddress,
      demoApiAddress: this.demoApiAddress,
      appId: this.appId,
      datawayAddress: this.datawayAddress,
      datawayClientToken: this.datawayClientToken,
      otelAddress: this.otelAddress,
      type: this.type,
      enableSessionReplay: this.enableSessionReplay,
      sessionReplayPrivacyType: this.sessionReplayPrivacyType
    });
  }
}
