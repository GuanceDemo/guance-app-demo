import { http } from '@kit.NetworkKit';
import { applyFTHttpTrack } from 'ft_sdk/src/main/ets/components/network/FTHttpAutoTrack';
import { UserData, JsonObject } from '../model/UserData';
import { BaseData, ConnectData, ReturnResult } from './BaseData';
import { Utils } from '../utils/Utils';
import {
  API_CONNECT,
  API_DATAKIT_PING,
  API_DATAWAY_CHECK_LOG,
  API_LOGIN,
  API_USER_INFO
} from '../constants/Constant';

/**
 * HTTP engine
 */
export class HttpEngine {
  private static apiAddress: string = '';

  /**
   * Initialize API address
   */
  static initAPIAddress(url: string): void {
    HttpEngine.apiAddress = url;
  }

  /**
   * Login request
   */
  static async login(
    username: string,
    password: string
  ): Promise<ConnectData> {
    const url = `${HttpEngine.apiAddress}${API_LOGIN}`;
    const bodyData: Record<string, string> = {};
    bodyData['username'] = username;
    bodyData['password'] = password;
    const result = await HttpEngine.request(url, http.RequestMethod.POST, JSON.stringify(bodyData));
    return new ConnectData(result);
  }

  /**
   * Get user info
   */
  static async userinfo(): Promise<UserData> {
    const url = `${HttpEngine.apiAddress}${API_USER_INFO}`;
    const result = await HttpEngine.request(url, http.RequestMethod.GET);
    return HttpEngine.parseUserData(result);
  }

  /**
   * DataKit ping test
   */
  static async datakitPing(
    datakitUrl: string
  ): Promise<ConnectData> {
    const url = `${datakitUrl}${API_DATAKIT_PING}`;
    const result = await HttpEngine.request(url, http.RequestMethod.GET);
    return new ConnectData(result);
  }

  /**
   * DataWay ping test
   */
  static async datawayPing(
    dataWayUrl: string,
    clientToken: string
  ): Promise<ConnectData> {
    const url = `${dataWayUrl}${API_DATAWAY_CHECK_LOG.replace('%s', clientToken)}`;
    const content = `df_rum_ohos_log message="connect test" ${Utils.getCurrentNanoTime()}`;
    const result = await HttpEngine.request(url, http.RequestMethod.POST, content, 'text/plain');
    return new ConnectData(result);
  }

  /**
   * API connection test
   */
  static async apiConnect(
    demoAPIUrl: string
  ): Promise<ConnectData> {
    const url = `${demoAPIUrl}${API_CONNECT}`;
    const result = await HttpEngine.request(url, http.RequestMethod.GET);
    return new ConnectData(result);
  }

  /**
   * Common request method
   */
  private static async request(
    url: string,
    method: http.RequestMethod,
    body?: string,
    contentType: string = 'application/json'
  ): Promise<ReturnResult> {
    let httpRequest: http.HttpRequest | undefined = undefined;
    try {
      httpRequest = http.createHttp();
      applyFTHttpTrack(httpRequest);

      const options: http.HttpRequestOptions = {
        method: method,
        header: {
          'Content-Type': contentType
        },
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 10000,
        readTimeout: 10000
      };

      if (body && (method === http.RequestMethod.POST || method === http.RequestMethod.PUT)) {
        options.extraData = body;
      }

      const response = await httpRequest.request(url, options);

      if (response.result !== undefined && response.result !== null) {
        return new ReturnResult(response.responseCode, response.result as string);
      } else {
        return new ReturnResult(response.responseCode, null);
      }
    } catch (err) {
      console.error('HTTP request failed:', JSON.stringify(err));
      return new ReturnResult(BaseData.ERROR_CODE_NET_WORK_CONNECT_ERROR);
    } finally {
      if (httpRequest) {
        httpRequest.destroy();
      }
    }
  }

  /**
   * Parse user data
   */
  private static parseUserData(result: ReturnResult): UserData {
    const data = new UserData();

    if (result.code === 200 && result.result) {
      try {
        const jsonObj = JsonObject.fromJsonString(result.result);
        return UserData.fromJson(jsonObj);
      } catch (err) {
        console.error('Failed to parse UserData:', JSON.stringify(err));
      }
    }

    return data;
  }
}
