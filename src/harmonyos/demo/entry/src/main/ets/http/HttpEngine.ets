import axios, { AxiosInstance, AxiosResponse, AxiosRequestConfig, AxiosHeaders } from '@ohos/axios';
import { applyFTAxiosTrack } from '@guancecloud/ft_sdk/src/main/ets/components/network/FTHttpAutoTrack';
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

export class HttpEngine {
  private static apiAddress: string = '';
  private static axiosInstance: AxiosInstance | null = null;

  static initAPIAddress(url: string): void {
    HttpEngine.apiAddress = url;
  }

  private static getAxiosInstance(): AxiosInstance {
    if (!HttpEngine.axiosInstance) {
      const defaultHeaders = new AxiosHeaders();
      defaultHeaders.setContentType('application/json');
      const client = axios.create({
        timeout: 10000,
        headers: defaultHeaders
      });
      applyFTAxiosTrack(client);
      HttpEngine.axiosInstance = client;
    }
    return HttpEngine.axiosInstance;
  }

  static async login(
    username: string,
    password: string
  ): Promise<ConnectData> {
    const url = `${HttpEngine.apiAddress}${API_LOGIN}`;
    const bodyData: Record<string, string> = {};
    bodyData['username'] = username;
    bodyData['password'] = password;
    const result = await HttpEngine.request(url, 'POST', JSON.stringify(bodyData));
    return new ConnectData(result);
  }

  static async userinfo(): Promise<UserData> {
    const url = `${HttpEngine.apiAddress}${API_USER_INFO}`;
    const result = await HttpEngine.request(url, 'GET');
    return HttpEngine.parseUserData(result);
  }

  static async datakitPing(
    datakitUrl: string
  ): Promise<ConnectData> {
    const url = `${datakitUrl}${API_DATAKIT_PING}`;
    const result = await HttpEngine.request(url, 'GET');
    return new ConnectData(result);
  }

  static async datawayPing(
    dataWayUrl: string,
    clientToken: string
  ): Promise<ConnectData> {
    const url = `${dataWayUrl}${API_DATAWAY_CHECK_LOG.replace('%s', clientToken)}`;
    const content = `df_rum_ohos_log message="connect test" ${Utils.getCurrentNanoTime()}`;
    const result = await HttpEngine.request(url, 'POST', content, 'text/plain');
    return new ConnectData(result);
  }

  static async apiConnect(
    demoAPIUrl: string
  ): Promise<ConnectData> {
    const url = `${demoAPIUrl}${API_CONNECT}`;
    const result = await HttpEngine.request(url, 'GET');
    return new ConnectData(result);
  }

  private static async request(
    url: string,
    method: string,
    body?: string,
    contentType: string = 'application/json'
  ): Promise<ReturnResult> {
    try {
      const client = HttpEngine.getAxiosInstance();
      const headers = new AxiosHeaders();
      headers.setContentType(contentType);
      const config: AxiosRequestConfig = {
        url: url,
        method: method,
        headers: headers,
        responseType: 'string',
        validateStatus: () => true
      };

      if (body && (method === 'POST' || method === 'PUT')) {
        config.data = body;
      }

      const response: AxiosResponse<string> = await client.request<string, AxiosResponse<string>, string>(config);

      if (response.data !== undefined && response.data !== null) {
        return new ReturnResult(response.status, String(response.data));
      } else {
        return new ReturnResult(response.status, null);
      }
    } catch (err) {
      console.error('HTTP request failed:', JSON.stringify(err));
      return new ReturnResult(BaseData.ERROR_CODE_NET_WORK_CONNECT_ERROR);
    }
  }

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
