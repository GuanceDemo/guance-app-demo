import { native, sys } from 'cc';
import { CONFIG_KEY, ConfigStorage, DemoConfig } from './Config';

/** App-owned bridge. The host owns persisted settings and every native SDK module. */
function invoke(method: string, payload = ''): unknown {
  const raw = sys.os === sys.OS.ANDROID
    ? native.reflection.callStaticMethod('com/guance/cocos/demo/NativeTelemetry', 'invoke',
      '(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;', method, payload)
    : native.reflection.callStaticMethod('GCNativeTelemetry', 'invoke:payload:', method, payload);
  const response = JSON.parse(String(raw));
  if (!response.ok) throw new Error(response.error || 'Native SDK host is unavailable. Rebuild the app.');
  return response.value;
}

export const nativeHost = {
  initialize(config: DemoConfig): void { invoke('initialize', JSON.stringify(config)); },
  disable(): boolean { return invoke('disable') === true; },
};

export const configStorage: ConfigStorage = {
  getItem(key) {
    if (sys.isNative && key === CONFIG_KEY) {
      const saved = invoke('read');
      if (typeof saved === 'string' && saved) return saved;
    }
    // One-time migration from the previous Cocos-owned settings store.
    return sys.localStorage.getItem(key);
  },
  setItem(key, value) {
    if (sys.isNative && key === CONFIG_KEY) invoke('save', value);
    else sys.localStorage.setItem(key, value);
  },
};
