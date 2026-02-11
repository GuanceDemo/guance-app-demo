import { SessionReplayPrivacy } from '../constants/SessionReplayPrivacy';
import { API_USER_INFO } from '../constants/Constant';

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
}
