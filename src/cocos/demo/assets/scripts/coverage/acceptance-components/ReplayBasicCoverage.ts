export type BasicCase = 'Label' | 'RichText' | 'Sprite' | 'Button' | 'Toggle';
export type BasicPrivacy = 'default' | 'mask' | 'hide';
export interface BasicState {
  updated: boolean;
  spriteMode: number;
  disabled: boolean;
  visible: boolean;
  moved: boolean;
  privacy: BasicPrivacy;
  clicks: number;
  checked: boolean;
}
export interface ReplayBasicUI {
  apply(state: Readonly<BasicState>): void;
  command(name: string, label: string, x: number, y: number, click: () => void): void;
  status(text: string): void;
}

const initialState = (): BasicState => ({
  updated: false, spriteMode: 0, disabled: false, visible: true,
  moved: false, privacy: 'default', clicks: 0, checked: false,
});

/** One shared workflow drives five real components in both engine adapters. */
export class ReplayBasicCoverage {
  private state = initialState();
  private disposed = false;

  constructor(private readonly ui: ReplayBasicUI,
    private readonly track: (id: BasicCase | 'page', stage: string) => void,
    exit: () => void) {
    const commands: Array<[string, string, () => void]> = [
      ['Content', 'Update text / colors', () => { this.state.updated = !this.state.updated; this.record('page', 'content-updated'); }],
      ['SpriteMode', 'Sprite: simple / slice / fill', () => { this.state.spriteMode = (this.state.spriteMode + 1) % 3; this.record('Sprite', ['simple', 'sliced', 'filled'][this.state.spriteMode]!); }],
      ['Interaction', 'Enable / disable controls', () => { this.state.disabled = !this.state.disabled; this.record('page', this.state.disabled ? 'disabled' : 'enabled'); }],
      ['Transform', 'Move + scale / reset', () => { this.state.moved = !this.state.moved; this.record('page', this.state.moved ? 'transformed' : 'transform-reset'); }],
      ['Visibility', 'Hide / show all five', () => { this.state.visible = !this.state.visible; this.record('page', this.state.visible ? 'shown' : 'hidden'); }],
      ['Privacy', 'All: default / mask / hide', () => { this.state.privacy = this.state.privacy === 'default' ? 'mask' : this.state.privacy === 'mask' ? 'hide' : 'default'; this.record('page', `privacy-${this.state.privacy}`); }],
      ['Reset', 'Reset batch', () => { this.state = initialState(); this.record('page', 'reset'); }],
      ['Exit', 'Back to coverage', () => { this.record('page', 'exit'); this.dispose(); exit(); }],
    ];
    commands.forEach(([name, label, run], i) => ui.command(name, label, -345 + (i % 4) * 230, i < 4 ? -245 : -295, () => {
      if (!this.disposed) run();
    }));
    this.record('page', 'entered');
  }

  pressButton(): void {
    if (this.disposed || this.state.disabled || !this.state.visible) return;
    this.state.clicks++;
    this.record('Button', 'clicked');
  }

  toggle(checked: boolean): void {
    if (this.disposed || this.state.disabled || !this.state.visible) return;
    this.state.checked = checked;
    this.record('Toggle', checked ? 'checked' : 'unchecked');
  }

  private record(id: BasicCase | 'page', stage: string): void {
    if (this.disposed) return;
    this.ui.apply({ ...this.state });
    this.ui.status(`${id} / ${stage} | privacy: ${this.state.privacy} | clicks: ${this.state.clicks}`);
    this.track(id, stage);
  }

  dispose(): void { this.disposed = true; }
}

/** Deterministic color quadrants and border make Sprite cropping/fill observable. */
export function coverageTexturePixels(pattern: boolean): Uint8Array {
  const pixels = new Uint8Array(32 * 32 * 4);
  for (let y = 0; y < 32; y++) for (let x = 0; x < 32; x++) {
    const color = !pattern || x < 3 || y < 3 || x > 28 || y > 28 ? [255, 255, 255]
      : y < 16 ? (x < 16 ? [241, 171, 58] : [48, 191, 195])
        : (x < 16 ? [118, 89, 220] : [228, 82, 123]);
    pixels.set([...color, 255], (y * 32 + x) * 4);
  }
  return pixels;
}
