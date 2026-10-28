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
  enableSdk: boolean;
  debug: boolean;
  enableNativeCrash: boolean;
  enableNativeAnr: boolean;
  enableNativeUiBlock: boolean;
  enableAutoResource: boolean;
  enableAutoError: boolean;
  replayFps: number;
  replayQuality: 'low' | 'medium' | 'high';
}

export const CONFIG_KEY = 'gc_demo_cocos_setting_v1';
export const defaultConfig = (): DemoConfig => ({
  accessType: 'datakit', datakitAddress: '', datawayAddress: '', datawayClientToken: '',
  demoApiAddress: '', demoAndroidAppId: '', demoIOSAppId: '', enableSessionReplay: true,
  enableSdk: true, debug: false, enableNativeCrash: true, enableNativeAnr: true,
  enableNativeUiBlock: true, enableAutoResource: true, enableAutoError: true,
  replayFps: 1, replayQuality: 'medium',
});

export const toggleKeys = ['enableSdk', 'debug', 'enableSessionReplay', 'enableNativeCrash',
  'enableNativeAnr', 'enableNativeUiBlock', 'enableAutoResource', 'enableAutoError'] as const;

export function validateSdkOptions(config: DemoConfig): void {
  for (const key of toggleKeys) if (typeof config[key] !== 'boolean') throw new Error(`${key} must be a boolean.`);
  if (!Number.isInteger(config.replayFps) || config.replayFps < 1 || config.replayFps > 5) throw new Error('Replay FPS must be an integer from 1 to 5.');
  if (!['low', 'medium', 'high'].includes(config.replayQuality)) throw new Error('Select Low, Medium or High replay quality.');
}

/** Send only the current platform ID across the SDK bridge. Never fall back to the other platform. */
export function sdkAppId(config: DemoConfig, platform: Platform) {
  const appId = (platform === 'android' ? config.demoAndroidAppId : config.demoIOSAppId).trim();
  if (!appId) throw new Error(`Enter the ${platform === 'android' ? 'Android' : 'iOS'} App ID.`);
  return platform === 'android' ? { androidAppId: appId } : { iosAppId: appId };
}

export function sdkReplay(config: DemoConfig) {
  return { captureFps: config.replayFps,
    imagePolicy: { quality: config.replayQuality }, touchPrivacy: 'show' as const };
}

export interface SettingField {
  key: keyof DemoConfig; label: string; kind: 'text' | 'secret' | 'toggle' | 'choice';
  options?: Array<{ label: string; value: string | number }>;
}
export function settingFields(platform: Platform): SettingField[] {
  return [
    { key: 'enableSdk', label: 'Enable SDK', kind: 'toggle' },
    { key: platform === 'android' ? 'demoAndroidAppId' : 'demoIOSAppId', label: `${platform === 'android' ? 'Android' : 'iOS'} App ID (this device)`, kind: 'text' },
    { key: 'accessType', label: 'Collector', kind: 'choice', options: [{ label: 'DataKit', value: 'datakit' }, { label: 'DataWay', value: 'dataway' }] },
    { key: 'datakitAddress', label: 'DataKit URL', kind: 'text' },
    { key: 'datawayAddress', label: 'DataWay URL', kind: 'text' },
    { key: 'datawayClientToken', label: 'DataWay Client Token', kind: 'secret' },
    { key: 'demoApiAddress', label: 'Demo API URL', kind: 'text' },
    { key: 'enableSessionReplay', label: 'Session Replay', kind: 'toggle' },
    { key: 'replayFps', label: 'Replay capture FPS', kind: 'choice', options: [1, 2, 3, 4, 5].map(value => ({ label: `${value} FPS`, value })) },
    { key: 'replayQuality', label: 'Replay image quality', kind: 'choice', options: [
      { label: 'Low · 480 px', value: 'low' }, { label: 'Medium · 720 px', value: 'medium' }, { label: 'High · 960 px', value: 'high' }] },
    { key: 'enableNativeCrash', label: 'Native crash collection', kind: 'toggle' },
    ...(platform === 'android' ? [{ key: 'enableNativeAnr', label: 'Android ANR collection', kind: 'toggle' } as SettingField] : []),
    { key: 'enableNativeUiBlock', label: 'Native UI block collection', kind: 'toggle' },
    { key: 'enableAutoResource', label: 'Automatic Cocos network collection', kind: 'toggle' },
    { key: 'enableAutoError', label: 'Automatic JavaScript error collection', kind: 'toggle' },
    { key: 'debug', label: 'SDK debug logging', kind: 'toggle' },
  ];
}

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
  validateSdkOptions(config);
  if (!config.enableSdk) return;
  sdkAppId(config, platform);
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
  for (const key of toggleKeys) {
    if (data[key] === undefined) continue;
    if (typeof data[key] !== 'boolean') throw new Error(`${key} must be a boolean.`);
    config[key] = data[key] as boolean;
  }
  if (data.replayFps !== undefined) config.replayFps = data.replayFps as number;
  if (data.replayQuality !== undefined) config.replayQuality = data.replayQuality as DemoConfig['replayQuality'];
  validateSdkOptions(config);
  return config;
}

/** Native form round-trip preserves the explicit collector and ignores unknown fields. */
export function formConfig(value: unknown): DemoConfig {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Invalid settings form.');
  const data = value as Record<string, unknown>;
  const result = importConfig(JSON.stringify(data));
  if (data.accessType !== 'datakit' && data.accessType !== 'dataway') throw new Error('Select DataKit or DataWay.');
  result.accessType = data.accessType;
  return result;
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
