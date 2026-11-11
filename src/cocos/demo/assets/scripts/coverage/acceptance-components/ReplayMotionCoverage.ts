export interface MotionState {
  variant: number;
  running: boolean;
  visible: boolean;
  moved: boolean;
  privacy: 'default' | 'mask' | 'hide';
}
export interface ReplayMotionUI {
  apply(state: Readonly<MotionState>): void;
  command(name: string, label: string, x: number, y: number, click: () => void): void;
  status(text: string): void;
}
const initial = (): MotionState => ({ variant: 0, running: true, visible: true, moved: false, privacy: 'default' });

export class ReplayMotionCoverage {
  private state = initial();
  private disposed = false;

  constructor(ui: ReplayMotionUI, track: (id: string, stage: string) => void, exit: () => void) {
    const record = (stage: string) => {
      ui.apply({ ...this.state });
      ui.status(`${stage} | variant: ${this.state.variant} | running: ${this.state.running} | privacy: ${this.state.privacy}`);
      track('page', stage);
    };
    const commands: Array<[string, string, () => void]> = [
      ['Change', 'Switch frame / effects / extra', () => { this.state.variant = 1 - this.state.variant; record('changed'); }],
      ['Running', 'Motion + particles: stop / run', () => { this.state.running = !this.state.running; record(this.state.running ? 'running' : 'stopped'); }],
      ['SafeArea', 'Refresh device safe area', () => record('safe-area-refreshed')],
      ['Transform', 'Move + scale / reset', () => { this.state.moved = !this.state.moved; record(this.state.moved ? 'transformed' : 'transform-reset'); }],
      ['Visibility', 'Hide / show five cases', () => { this.state.visible = !this.state.visible; record(this.state.visible ? 'shown' : 'hidden'); }],
      ['Privacy', 'All: default / mask / hide', () => { this.state.privacy = this.state.privacy === 'default' ? 'mask' : this.state.privacy === 'mask' ? 'hide' : 'default'; record(`privacy-${this.state.privacy}`); }],
      ['Reset', 'Reset batch', () => { this.state = initial(); record('reset'); }],
      ['Exit', 'Back to coverage', () => { record('exit'); this.dispose(); exit(); }],
    ];
    commands.forEach(([name, label, run], i) => ui.command(name, label, -345 + i % 4 * 230, i < 4 ? -245 : -295, () => { if (!this.disposed) run(); }));
    record('entered');
  }

  dispose(): void { this.disposed = true; }
}
