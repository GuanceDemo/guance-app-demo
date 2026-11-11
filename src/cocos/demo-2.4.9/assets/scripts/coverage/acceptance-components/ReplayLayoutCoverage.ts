export type LayoutCase = 'PageView' | 'PageViewIndicator' | 'ToggleContainer' | 'Layout' | 'Widget';
export interface LayoutState {
  page: number;
  pageRevision: number;
  selected: number;
  selectionRevision: number;
  layout: number;
  alignment: number;
  visible: boolean;
  moved: boolean;
  privacy: 'default' | 'mask' | 'hide';
}
export interface ReplayLayoutUI {
  apply(state: Readonly<LayoutState>): void;
  command(name: string, label: string, x: number, y: number, click: () => void): void;
  status(text: string): void;
}
const initialState = (revision = 0): LayoutState => ({
  page: 0, pageRevision: revision, selected: 0, selectionRevision: revision,
  layout: 0, alignment: 0, visible: true, moved: false, privacy: 'default',
});

/** Shared workflow; engine components own page motion, mutual exclusion and layout. */
export class ReplayLayoutCoverage {
  private state = initialState();
  private disposed = false;

  constructor(private readonly ui: ReplayLayoutUI,
    private readonly track: (id: LayoutCase | 'page', stage: string) => void,
    exit: () => void) {
    const commands: Array<[string, string, () => void]> = [
      ['Page', 'Next page / wrap', () => { this.state.page = (this.state.page + 1) % 3; this.state.pageRevision++; this.record('PageView', 'next-page'); }],
      ['Layout', 'Layout: row / column / grid', () => { this.state.layout = (this.state.layout + 1) % 3; this.record('Layout', ['row', 'column', 'grid'][this.state.layout]!); }],
      ['Widget', 'Widget: left / center / right / fill', () => { this.state.alignment = (this.state.alignment + 1) % 4; this.record('Widget', ['left', 'center', 'right', 'fill'][this.state.alignment]!); }],
      ['Transform', 'Move + scale / reset', () => { this.state.moved = !this.state.moved; this.record('page', this.state.moved ? 'transformed' : 'transform-reset'); }],
      ['Visibility', 'Hide / show all five', () => { this.state.visible = !this.state.visible; this.record('page', this.state.visible ? 'shown' : 'hidden'); }],
      ['Privacy', 'All: default / mask / hide', () => { this.state.privacy = this.state.privacy === 'default' ? 'mask' : this.state.privacy === 'mask' ? 'hide' : 'default'; this.record('page', `privacy-${this.state.privacy}`); }],
      ['Reset', 'Reset batch', () => { this.state = initialState(Math.max(this.state.pageRevision, this.state.selectionRevision) + 1); this.record('page', 'reset'); }],
      ['Exit', 'Back to coverage', () => { this.record('page', 'exit'); this.dispose(); exit(); }],
    ];
    commands.forEach(([name, label, run], i) => ui.command(name, label, -345 + (i % 4) * 230, i < 4 ? -245 : -295, () => {
      if (!this.disposed) run();
    }));
    this.record('page', 'entered');
  }

  turned(page: number): void {
    if (this.disposed || !this.state.visible || !Number.isInteger(page) || page < 0 || page > 2 || page === this.state.page) return;
    this.state.page = page;
    // Preserve the revision so a native gesture is never overwritten by apply().
    this.record('PageView', 'swiped');
  }

  selected(index: number): void {
    if (this.disposed || !this.state.visible || !Number.isInteger(index) || index < 0 || index > 2 || index === this.state.selected) return;
    this.state.selected = index;
    this.record('ToggleContainer', 'selected');
  }

  private record(id: LayoutCase | 'page', stage: string): void {
    if (this.disposed) return;
    this.ui.apply({ ...this.state });
    this.ui.status(`${id} / ${stage} | page: ${this.state.page + 1} | selected: ${'ABC'[this.state.selected]} | privacy: ${this.state.privacy}`);
    this.track(id, stage);
  }

  dispose(): void { this.disposed = true; }
}
