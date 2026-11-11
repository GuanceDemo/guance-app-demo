export type EffectsCase = 'Graphics' | 'LabelOutline' | 'LabelShadow' | 'WebView' | 'VideoPlayer';
export interface EffectsState {
  revision: number;
  playing: boolean;
  visible: boolean;
  moved: boolean;
  privacy: 'default' | 'mask' | 'hide';
}
export interface ReplayEffectsUI {
  apply(state: Readonly<EffectsState>): void;
  command(name: string, label: string, x: number, y: number, click: () => void): void;
  status(text: string): void;
}
const initial = (revision = 0): EffectsState => ({ revision, playing: true, visible: true, moved: false, privacy: 'default' });

/** Engine-rendered effects and native overlays share one repeatable workflow. */
export class ReplayEffectsCoverage {
  private state = initial();
  private disposed = false;

  constructor(ui: ReplayEffectsUI, track: (id: EffectsCase | 'page', stage: string) => void, exit: () => void) {
    const record = (id: EffectsCase | 'page', stage: string): void => {
      ui.apply({ ...this.state });
      ui.status(`${id} / ${stage} | revision: ${this.state.revision} | privacy: ${this.state.privacy}`);
      track(id, stage);
    };
    const commands: Array<[string, string, () => void]> = [
      ['Change', 'Change graphics + text effects', () => { this.state.revision++; record('Graphics', 'changed'); }],
      ['Video', 'Video: play / pause', () => { this.state.playing = !this.state.playing; record('VideoPlayer', this.state.playing ? 'play' : 'pause'); }],
      ['Web', 'Reload local WebView', () => { this.state.revision++; record('WebView', 'reloaded'); }],
      ['Transform', 'Move + scale / reset', () => { this.state.moved = !this.state.moved; record('page', this.state.moved ? 'transformed' : 'transform-reset'); }],
      ['Visibility', 'Hide / show all five', () => { this.state.visible = !this.state.visible; record('page', this.state.visible ? 'shown' : 'hidden'); }],
      ['Privacy', 'All: default / mask / hide', () => { this.state.privacy = this.state.privacy === 'default' ? 'mask' : this.state.privacy === 'mask' ? 'hide' : 'default'; record('page', `privacy-${this.state.privacy}`); }],
      ['Reset', 'Reset batch', () => { this.state = initial(this.state.revision + 1); record('page', 'reset'); }],
      ['Exit', 'Back to coverage', () => { record('page', 'exit'); this.dispose(); exit(); }],
    ];
    commands.forEach(([name, label, run], i) => ui.command(name, label, -345 + i % 4 * 230, i < 4 ? -245 : -295, () => { if (!this.disposed) run(); }));
    record('page', 'entered');
  }

  dispose(): void { this.disposed = true; }
}
