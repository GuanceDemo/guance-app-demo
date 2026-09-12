export type Platform = 'android' | 'ios';
export interface DemoConfig {
  accessType: 'datakit' | 'dataway';
  datakitAddress: string;
  datawayAddress: string;
  datawayClientToken: string;
  demoApiAddress: string;
  demoAndroidAppId: string;
  demoIOSAppId: string;
  enableSessionReplay: boolean;
}

export const CONFIG_KEY = 'gc_demo_cocos_setting_v1';
export const defaultConfig = (): DemoConfig => ({
  accessType: 'datakit', datakitAddress: '', datawayAddress: '', datawayClientToken: '',
  demoApiAddress: '', demoAndroidAppId: '', demoIOSAppId: '', enableSessionReplay: true,
});

// JSB does not guarantee browser atob/TextDecoder globals.
function decodeBase64(text: string): string {
  if (!/^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$/.test(text) || !text) {
    throw new Error('Invalid Base64 settings string');
  }
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
  let bits = 0, value = 0, encoded = '';
  for (const c of text.replace(/=+$/, '')) {
    value = (value << 6) | alphabet.indexOf(c); bits += 6;
    if (bits >= 8) {
      bits -= 8;
      encoded += '%' + ((value >> bits) & 255).toString(16).padStart(2, '0');
    }
  }
  return decodeURIComponent(encoded);
}

export function isHttpUrl(value: string): boolean {
  return /^https?:\/\/(?:\[[0-9a-f:]+\]|[a-z0-9](?:[a-z0-9.-]*[a-z0-9])?)(?::[0-9]{1,5})?(?:\/[^\s#]*)?$/i.test(value);
}

export function validateConfig(config: DemoConfig, platform: Platform): void {
  const appId = platform === 'ios' ? config.demoIOSAppId : config.demoAndroidAppId;
  if (!appId.trim()) throw new Error(`Enter the ${platform === 'ios' ? 'iOS' : 'Android'} App ID.`);
  if (!isHttpUrl(config.demoApiAddress)) throw new Error('Demo API URL must be a valid HTTP(S) URL.');
  if (config.accessType === 'datakit') {
    if (!isHttpUrl(config.datakitAddress)) throw new Error('Enter a valid DataKit URL.');
  } else if (config.accessType === 'dataway') {
    if (!isHttpUrl(config.datawayAddress)) throw new Error('Enter a valid DataWay URL.');
    if (!config.datawayClientToken.trim()) throw new Error('Enter the DataWay Client Token.');
  } else throw new Error('Select DataKit or DataWay.');
}

/** Same payload as server /import_helper and the Android/iOS demos. */
export function importConfig(input: string, previous = defaultConfig()): DemoConfig {
  const text = input.trim();
  if (text.length > 32768) throw new Error('Settings string is too long.');
  let data: Record<string, unknown>;
  try {
    const parsed: unknown = JSON.parse(text.startsWith('gc-demo://') ? decodeBase64(text.slice(10)) : text);
    if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) throw new Error();
    data = parsed as Record<string, unknown>;
  } catch { throw new Error('Cannot parse settings. Paste a complete gc-demo:// string or JSON.'); }
  const get = (key: string): string | undefined => {
    if (data[key] === undefined) return undefined;
    if (typeof data[key] !== 'string') throw new Error(`${key} must be a string.`);
    return (data[key] as string).trim();
  };
  const config = { ...previous };
  const keys = ['datakitAddress', 'datawayAddress', 'datawayClientToken', 'demoApiAddress', 'demoAndroidAppId', 'demoIOSAppId'] as const;
  for (const key of keys) config[key] = get(key) ?? config[key];
  config.demoAndroidAppId = get('demoCocosAndroidAppId') || config.demoAndroidAppId;
  config.demoIOSAppId = get('demoCocosIOSAppId') || config.demoIOSAppId;
  if (get('datakitAddress')) config.accessType = 'datakit';
  else if (get('datawayAddress') && get('datawayClientToken')) config.accessType = 'dataway';
  if (data.enableSessionReplay !== undefined) {
    if (typeof data.enableSessionReplay !== 'boolean') throw new Error('enableSessionReplay must be a boolean.');
    config.enableSessionReplay = data.enableSessionReplay;
  }
  return config;
}

export interface ConfigStorage { getItem(key: string): string | null; setItem(key: string, value: string): void; }
export function readConfig(storage: ConfigStorage): DemoConfig {
  try {
    const saved = storage.getItem(CONFIG_KEY);
    if (!saved) return defaultConfig();
    const parsed = JSON.parse(saved) as Partial<DemoConfig>;
    const result = importConfig(saved);
    // Persisted explicit mode wins over inactive endpoint fields.
    if (parsed.accessType === 'datakit' || parsed.accessType === 'dataway') result.accessType = parsed.accessType;
    return result;
  } catch { return defaultConfig(); }
}

export function saveConfig(storage: ConfigStorage, config: DemoConfig, platform: Platform): void {
  validateConfig(config, platform);
  storage.setItem(CONFIG_KEY, JSON.stringify(config));
}

export function sdkConnection(config: DemoConfig) {
  return config.accessType === 'datakit'
    ? { datakitUrl: config.datakitAddress }
    : { datawayUrl: config.datawayAddress, clientToken: config.datawayClientToken };
}

export function endpoint(base: string, path: string): string {
  return base.replace(/\/+$/, '') + '/' + path.replace(/^\/+/, '');
}
