/**
 * JSON object class
 */
export class JsonObject {
  private data: Map<string, Object | string | number | boolean | null> = new Map();

  constructor() {
    // Empty constructor
  }

  /**
   * Set value
   */
  set(key: string, value: Object | string | number | boolean | null): void {
    this.data.set(key, value);
  }

  /**
   * Get string value
   */
  getString(key: string, defaultValue: string = ''): string {
    const value = this.data.get(key);
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return String(value);
  }

  /**
   * Get number value
   */
  getNumber(key: string, defaultValue: number = 0): number {
    const value = this.data.get(key);
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return Number(value);
  }

  /**
   * Get boolean value
   */
  getBoolean(key: string, defaultValue: boolean = false): boolean {
    const value = this.data.get(key);
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return Boolean(value);
  }

  /**
   * Get any value
   */
  get(key: string): Object | string | number | boolean | null {
    return this.data.get(key) || null;
  }

  /**
   * Create from JSON string
   */
  static fromJsonString(jsonStr: string): JsonObject {
    const obj = new JsonObject();
    try {
      const parsed: Record<string, Object> = JSON.parse(jsonStr);
      const keys = Object.keys(parsed);
      for (const key of keys) {
        obj.set(key, parsed[key]);
      }
    } catch (err) {
      console.error('Failed to parse JSON:', JSON.stringify(err));
    }
    return obj;
  }
}

/**
 * User data model
 */
export class UserData {
  username: string = '';
  email: string = '';
  avatar: string = '';

  constructor(username?: string, email?: string, avatar?: string) {
    if (username !== undefined) {
      this.username = username;
    }
    if (email !== undefined) {
      this.email = email;
    }
    if (avatar !== undefined) {
      this.avatar = avatar;
    }
  }

  /**
   * Create UserData from JSON object
   */
  static fromJson(json: JsonObject): UserData {
    const data = new UserData();
    data.username = json.getString('username');
    data.email = json.getString('email');
    data.avatar = json.getString('avatar');
    return data;
  }

  /**
   * Check if empty
   */
  isEmpty(): boolean {
    return !this.username && !this.email && !this.avatar;
  }

  /**
   * Convert to JSON object
   */
  toJson(): JsonObject {
    const obj = new JsonObject();
    obj.set('username', this.username);
    obj.set('email', this.email);
    obj.set('avatar', this.avatar);
    return obj;
  }
}
