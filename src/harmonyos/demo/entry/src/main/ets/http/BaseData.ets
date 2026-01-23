/**
 * Base data class
 */
export abstract class BaseData {
  code: number;
  errorMessage: string = '';
  private returnResult: ReturnResult;

  // Error code constants
  static readonly ERROR_CODE_LOCAL = 0;
  static readonly ERROR_CODE_BODY_EMPTY = 100;
  static readonly ERROR_CODE_NET_WORK_NO_AVAILABLE = 101;
  static readonly ERROR_CODE_NET_WORK_CONNECT_ERROR = 102;

  constructor(returnResult: ReturnResult) {
    this.returnResult = returnResult;
    this.code = returnResult.code;
    this.parse();
  }

  parse(): void {
    if (this.code !== BaseData.ERROR_CODE_LOCAL) {
      if (this.returnResult.result !== null) {
        try {
          const json: Record<string, Object> = JSON.parse(this.returnResult.result);
          if (this.code === 200) {
            this.onHttpOk(json);
          } else {
            // Handle non-200 status codes
            switch (this.code) {
              case BaseData.ERROR_CODE_NET_WORK_NO_AVAILABLE:
                this.onHttpError({ 'error': 'network no available' });
                break;
              case BaseData.ERROR_CODE_NET_WORK_CONNECT_ERROR:
                this.onHttpError({ 'error': 'connect error:1' });
                break;
              default:
                this.onHttpError(json);
                break;
            }
          }
        } catch (err) {
          this.onHttpError({ 'error': 'connect error:0' });
          console.error('JSON Parse Error:', JSON.stringify(err));
        }
      } else {
        this.code = BaseData.ERROR_CODE_BODY_EMPTY;
        this.errorMessage = 'connect error:3';
      }
    }
  }

  abstract onHttpOk(json: Record<string, Object>): void;

  onHttpError(json: Record<string, Object>): void {
    const error = json['error'];
    this.errorMessage = (typeof error === 'string') ? error : 'Unknown error';
  }
}

/**
 * Connection data
 */
export class ConnectData extends BaseData {
  constructor(returnResult: ReturnResult) {
    super(returnResult);
  }

  onHttpOk(json: Record<string, Object>): void {
    // Connection successful, no special handling
  }
}

/**
 * Return result
 */
export class ReturnResult {
  code: number;
  result: string | null;

  constructor(code: number, result: string | null = null) {
    this.code = code;
    this.result = result;
  }
}
