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
  traceUrl: string;

  constructor(
    datakitAddress: string = '',
    demoApiAddress: string = '',
    appId: string = '',
    datawayAddress: string = '',
    datawayClientToken: string = '',
    otelAddress: string = '',
    type: number = 0,
    traceUrl: string = ''
  ) {
    this.datakitAddress = datakitAddress;
    this.demoApiAddress = demoApiAddress;
    this.appId = appId;
    this.datawayAddress = datawayAddress;
    this.datawayClientToken = datawayClientToken;
    this.otelAddress = otelAddress;
    this.type = type;
    this.traceUrl = traceUrl;
  }

  /**
   * Get user info URL
   */
  getUserInfoUrl(): string {
    return this.demoApiAddress + API_USER_INFO;
  }

  /**
   * Get the endpoint used by the linked trace request.
   */
  getTraceUrl(): string {
    return this.traceUrl || this.getUserInfoUrl();
  }
}
