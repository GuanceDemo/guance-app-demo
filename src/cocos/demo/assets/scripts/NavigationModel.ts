export type NavigationTab = 'Lobby' | 'Controls' | 'Lab' | 'Settings';
interface Size { width: number; height: number }
interface SafeArea extends Size { x: number; y: number }

export function navigationTab(name: string, scenario: string): NavigationTab {
  if (scenario === 'configuration' || name === 'NativeSdkSettings') return 'Settings';
  if (scenario === 'component_coverage') return 'Controls';
  if (scenario === 'experimental' || scenario === 'multitouch_replay') return 'Lab';
  return 'Lobby';
}

/** Frame dimensions are CSS pixels; view scale and safe area use engine pixels. */
export function navigationGeometry(frame: Size, design: Size, safe: SafeArea, scaleY: number, pixelRatio: number) {
  const scale = Math.min(frame.width, frame.height) * pixelRatio / 720 / scaleY;
  return { scale, width: safe.width / scale - 32,
    x: safe.x + safe.width / 2 - design.width / 2,
    y: safe.y - design.height / 2 + 54 * scale };
}
