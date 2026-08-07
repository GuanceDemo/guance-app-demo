import axios, { AxiosInstance, AxiosResponse, AxiosRequestConfig, AxiosHeaders } from '@ohos/axios';
import { applyFTAxiosTrack } from '@guancecloud/ft_sdk';
import { UserData, JsonObject } from '../model/UserData';
import { ProductDetail, ProductItem, ProductSpec } from '../model/ProductData';
import { BaseData, ConnectData, ReturnResult } from './BaseData';
import { Utils } from '../utils/Utils';
import {
  API_CONNECT,
  API_DATAKIT_PING,
  API_DATAWAY_CHECK_LOG,
  API_LOGIN,
  API_PRODUCTS,
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

  static async products(demoAPIUrl: string): Promise<ProductItem[]> {
    const url = `${demoAPIUrl}${API_PRODUCTS}`;
    const result = await HttpEngine.request(url, 'GET');
    if (result.code !== 200 || !result.result) {
      throw new Error(HttpEngine.buildErrorMessage(result));
    }
    return HttpEngine.parseProductList(result.result, demoAPIUrl);
  }

  static async productDetail(demoAPIUrl: string, productId: string): Promise<ProductDetail> {
    const url = `${demoAPIUrl}${API_PRODUCTS}/${productId}`;
    const result = await HttpEngine.request(url, 'GET');
    if (result.code !== 200 || !result.result) {
      throw new Error(HttpEngine.buildErrorMessage(result));
    }
    return HttpEngine.parseProductDetail(result.result, demoAPIUrl);
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

  private static parseProductList(jsonText: string, demoAPIUrl: string): ProductItem[] {
    const items: ProductItem[] = [];
    const array = JSON.parse(jsonText) as Array<Record<string, Object>>;
    for (const item of array) {
      items.push(HttpEngine.parseProductItem(item, demoAPIUrl));
    }
    return items;
  }

  private static parseProductDetail(jsonText: string, demoAPIUrl: string): ProductDetail {
    const json = JSON.parse(jsonText) as Record<string, Object>;
    const detail = new ProductDetail(HttpEngine.parseProductItem(json, demoAPIUrl));
    detail.stock = HttpEngine.getString(json, 'stock');
    detail.description = HttpEngine.getString(json, 'description');

    const highlights = json['highlights'] as Array<Object> | undefined;
    if (highlights) {
      detail.highlights = highlights.map((value: Object): string => String(value));
    }

    const specs = json['specs'] as Record<string, Object> | undefined;
    if (specs) {
      detail.specs = Object.keys(specs).map((key: string): ProductSpec => {
        return new ProductSpec(key, String(specs[key]));
      });
    }

    return detail;
  }

  private static parseProductItem(json: Record<string, Object>, demoAPIUrl: string): ProductItem {
    return new ProductItem(
      HttpEngine.getString(json, 'id'),
      HttpEngine.getString(json, 'title'),
      HttpEngine.getString(json, 'subtitle'),
      HttpEngine.resolveImageUrl(demoAPIUrl, HttpEngine.getString(json, 'image_url')),
      HttpEngine.getString(json, 'price'),
      HttpEngine.getString(json, 'rating'),
      HttpEngine.getString(json, 'tag')
    );
  }

  private static getString(json: Record<string, Object>, key: string): string {
    const value = json[key];
    if (value === undefined || value === null) {
      return '';
    }
    return String(value);
  }

  private static resolveImageUrl(demoAPIUrl: string, imageUrl: string): string {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return `${demoAPIUrl.replace(/\/$/, '')}/${imageUrl.replace(/^\//, '')}`;
  }

  private static buildErrorMessage(result: ReturnResult): string {
    if (result.result) {
      return `HTTP ${result.code}: ${result.result}`;
    }
    return `HTTP ${result.code}`;
  }
}
