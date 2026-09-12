import { endpoint } from './Config';
import { sdk, Telemetry } from './Telemetry';

export interface Product {
  id: string; title: string; subtitle: string; price: string; rating: string; tag: string;
  image_url: string; description?: string; highlights?: string[]; stock?: string;
}
export interface User { username: string; email: string; avatar: string; }
export interface HttpResult { status: number; body: string; }

// Capture before SDK initialization. Connection checks must never send tokens through RUM.
const original = {
  open: XMLHttpRequest.prototype.open,
  send: XMLHttpRequest.prototype.send,
  setRequestHeader: XMLHttpRequest.prototype.setRequestHeader,
};

export class Api {
  private pending = new Set<XMLHttpRequest>();
  private sequence = 0;
  constructor(public base: string, private telemetry: Telemetry) {}

  cancel(): void { for (const xhr of this.pending) xhr.abort(); this.pending.clear(); }

  request(url: string, options: { method?: string; body?: unknown; rawBody?: string; manual?: boolean; untracked?: boolean; timeout?: number } = {}): Promise<HttpResult> {
    const method = options.method ?? 'GET';
    const manual = options.manual && this.telemetry.ready;
    const bypass = options.untracked || options.manual;
    const key = `cocos-manual-${Date.now()}-${++this.sequence}`;
    const started = Date.now() * 1e6;
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();
      let completed = false;
      const finish = (failure?: string) => {
        if (completed) return;
        completed = true; this.pending.delete(xhr);
        if (manual) {
          sdk.rum.stopResource(key, { failed: !!failure });
          sdk.rum.addResource(key, { url, httpMethod: method, statusCode: xhr.status || 0 },
            { fetchStartTime: started, responseEndTime: Date.now() * 1e6 });
        }
        if (failure) reject(new Error(failure));
        else resolve({ status: xhr.status, body: xhr.responseText });
      };
      try {
        if (manual) sdk.rum.startResource(key, { demo_scenario: 'experimental', collection_mode: 'manual' });
        this.pending.add(xhr);
        if (bypass) original.open.call(xhr, method, url, true); else xhr.open(method, url, true);
        const header = (name: string, value: string) => bypass
          ? original.setRequestHeader.call(xhr, name, value) : xhr.setRequestHeader(name, value);
        if (options.body !== undefined) header('Content-Type', 'application/json');
        if (options.rawBody !== undefined) header('Content-Type', 'text/plain');
        if (manual) {
          const headers = sdk.trace.getHeaders(url, key);
          for (const name of Object.keys(headers)) header(name, headers[name]);
        }
        xhr.timeout = options.timeout ?? 12000;
        xhr.onload = () => finish();
        xhr.onerror = () => finish('Connection failed. Check the Demo API URL.');
        xhr.ontimeout = () => finish('Request timed out. Please try again.');
        xhr.onabort = () => finish('Request cancelled');
        const body = options.rawBody ?? (options.body === undefined ? null : JSON.stringify(options.body));
        if (bypass) original.send.call(xhr, body); else xhr.send(body);
      } catch { finish('Could not start the network request.'); }
    });
  }

  async json<T>(path: string, body?: unknown): Promise<T> {
    const response = await this.request(endpoint(this.base, path), { method: body === undefined ? 'GET' : 'POST', body });
    if (response.status < 200 || response.status >= 300) throw new Error(`HTTP ${response.status}. Please try again.`);
    try { return JSON.parse(response.body) as T; } catch { throw new Error('The server returned invalid JSON.'); }
  }
  login(username: string, password: string) { return this.json<{ success: boolean }>('/api/login', { username, password }); }
  products() { return this.json<Product[]>('/api/products'); }
  product(id: string) { return this.json<Product>('/api/products/' + encodeURIComponent(id)); }
  user() { return this.json<User>('/api/user'); }
}
