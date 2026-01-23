/**
 * Access type enum
 */
export enum AccessType {
  DATAKIT = 0,
  DATAWAY = 1
}

export function getAccessTypeText(type: AccessType): string {
  return type === AccessType.DATAKIT ? 'DataKit' : 'DataWay';
}
