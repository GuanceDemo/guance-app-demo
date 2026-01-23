/**
 * Constant definitions
 */
// Guance public DataWay official configuration
export const PUBLIC_DATAWAY_ADDRESS: string = 'https://rum-openway.guance.com';
export const PUBLIC_DATAWAY_CLIENT_TOKEN: string = 'client_token';
export const PUBLIC_APP_ID: string = 'com_harmonyos_demo';

export const DEFAULT_APP_ID: string = 'com_harmonyos_demo';
export const DEFAULT_API_ADDRESS: string = 'http://127.0.0.1:8000';
export const DEFAULT_DATAKIT_ADDRESS: string = 'http://127.0.0.1:9529';
export const DEFAULT_OTEL_ADDRESS: string = 'http://127.0.0.1:9529/otel/v1/traces';
export const DEFAULT_DATAWAY_ADDRESS: string = 'http://dataway.com';
export const DEFAULT_DATAWAY_CLIENT_TOKEN: string = 'gc_client_token';
export const DEFAULT_USER_NAME: string = 'guance';
export const DEFAULT_PASSWORD: string = 'admin';
export const GC_SCHEME_URL: string = 'gc-demo://';
export const APP_NAME: string = 'FT SDK Demo';

// API paths
export const API_SEGMENT: string = '/api';
export const API_LOGIN: string = '/api/login';
export const API_USER_INFO: string = '/api/user';
export const API_CONNECT: string = '/connect';
export const API_DATAKIT_PING: string = '/v1/ping';
export const API_DATAWAY_CHECK_LOG: string = '/v1/write/logging?token=%s&to_headless=true';

// SharedPreferences Keys
export const PREFS_USER_DATA_NAME: string = 'gc_demo_user_data';
export const PREFS_SETTING_NAME: string = 'gc_demo_sdk_setting';
export const KEY_USER_NAME: string = 'username';
export const KEY_USER_EMAIL: string = 'email';
export const KEY_USER_AVATAR: string = 'avatar';

export const KEY_DATAKIT_ADDRESS: string = 'datakitAddress';
export const KEY_DATAWAY_ADDRESS: string = 'datawayAddress';
export const KEY_OTEL_ADDRESS: string = 'otelAddress';
export const KEY_DATAWAY_CLIENT_TOKEN: string = 'datawayClientToken';
export const KEY_APP_ACCESS_TYPE: string = 'appAccessType';
export const KEY_API_ADDRESS: string = 'demoApiAddress';
export const KEY_APP_ID: string = 'demoAppId';
export const KEY_ENABLE_SESSION_REPLAY: string = 'demoEnableSessionReplay';
export const KEY_SESSION_REPLAY_PRIVACY_TYPE: string = 'demoEnableSessionReplayPrivacyType';

// Error codes
export const ERROR_CODE_LOCAL: number = 0;
export const ERROR_CODE_BODY_EMPTY: number = 100;
export const ERROR_CODE_NET_WORK_NO_AVAILABLE: number = 101;
export const ERROR_CODE_NET_WORK_CONNECT_ERROR: number = 102;

// HTTP status codes
export const HTTP_OK: number = 200;
