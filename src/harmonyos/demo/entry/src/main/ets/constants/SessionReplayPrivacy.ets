/**
 * Session replay privacy type enum
 */
export enum SessionReplayPrivacy {
  ALLOW = 0,
  MASK = 1,
  MASK_USER_INPUT = 2
}

export function getPrivacyTypeText(type: SessionReplayPrivacy): string {
  switch (type) {
    case SessionReplayPrivacy.ALLOW:
      return 'Allow';
    case SessionReplayPrivacy.MASK:
      return 'Mask';
    case SessionReplayPrivacy.MASK_USER_INPUT:
      return 'Mask User Input';
    default:
      return 'Allow';
  }
}
