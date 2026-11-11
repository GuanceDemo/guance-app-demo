export type ScrollCase = 'Slider' | 'ProgressBar' | 'ScrollView' | 'ScrollBar' | 'Mask';
export interface ScrollState {
  progress: number;
  bottom: boolean;
  scrollRevision: number;
  ellipse: boolean;
  visible: boolean;
  moved: boolean;
  privacy: 'default' | 'mask' | 'hide';
}
export interface ReplayScrollUI {
  apply(state: Readonly<ScrollState>): void;
  command(name: string, label: string, x: number, y: number, click: () => void): void;
  status(text: string): void;
}
const initialState = (revision = 0): ScrollState => ({
  progress: 0.25, bottom: false, scrollRevision: revision, ellipse: false,
  visible: true, moved: false, privacy: 'default',
});

/** Shared interactions for real slider, progress, scrolling and clipping components. */
export class ReplayScrollCoverage {
  private state = initialState();
  private disposed = false;
  private preset = 0;

  constructor(private readonly ui: ReplayScrollUI,
    private readonly track: (id: ScrollCase | 'page', stage: string) => void,
    exit: () => void) {
    const commands: Array<[string, string, () => void]> = [
      ['Progress', 'Progress: 0 / 50 / 100%', () => { this.state.progress = [0, 0.5, 1, 0.25][this.preset++ % 4]!; this.record('ProgressBar', 'preset'); }],
      ['Scroll', 'Scroll: bottom / top', () => { this.state.bottom = !this.state.bottom; this.state.scrollRevision++; this.record('ScrollView', this.state.bottom ? 'bottom' : 'top'); }],
      ['MaskShape', 'Mask: rectangle / ellipse', () => { this.state.ellipse = !this.state.ellipse; this.record('Mask', this.state.ellipse ? 'ellipse' : 'rectangle'); }],
      ['Transform', 'Move + scale / reset', () => { this.state.moved = !this.state.moved; this.record('page', this.state.moved ? 'transformed' : 'transform-reset'); }],
      ['Visibility', 'Hide / show all five', () => { this.state.visible = !this.state.visible; this.record('page', this.state.visible ? 'shown' : 'hidden'); }],
      ['Privacy', 'All: default / mask / hide', () => { this.state.privacy = this.state.privacy === 'default' ? 'mask' : this.state.privacy === 'mask' ? 'hide' : 'default'; this.record('page', `privacy-${this.state.privacy}`); }],
      ['Reset', 'Reset batch', () => { this.preset = 0; this.state = initialState(this.state.scrollRevision + 1); this.record('page', 'reset'); }],
      ['Exit', 'Back to coverage', () => { this.record('page', 'exit'); this.dispose(); exit(); }],
    ];
    commands.forEach(([name, label, run], i) => ui.command(name, label, -345 + (i % 4) * 230, i < 4 ? -245 : -295, () => {
      if (!this.disposed) run();
    }));
    this.record('page', 'entered');
  }

  slide(progress: number): void {
    if (this.disposed || !this.state.visible || !Number.isFinite(progress)) return;
    this.state.progress = Math.min(1, Math.max(0, progress));
    this.record('Slider', 'dragged');
  }

  scrolled(): void {
    if (this.disposed || !this.state.visible) return;
    // A native scroll event must not reapply a preset or reset its own position.
    this.ui.status(`ScrollView / dragged | privacy: ${this.state.privacy}`);
    this.track('ScrollView', 'dragged');
  }

  private record(id: ScrollCase | 'page', stage: string): void {
    if (this.disposed) return;
    this.ui.apply({ ...this.state });
    this.ui.status(`${id} / ${stage} | progress: ${Math.round(this.state.progress * 100)}% | privacy: ${this.state.privacy}`);
    this.track(id, stage);
  }

  dispose(): void { this.disposed = true; }
}
