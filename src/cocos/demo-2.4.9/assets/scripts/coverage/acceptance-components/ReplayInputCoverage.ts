export type InputCase = 'I01' | 'I02' | 'I03' | 'I04';
export type InputKind = 'normal' | 'password' | 'sensitive';
export type InputPhase = 'focus' | 'changed' | 'blur' | 'return';
export type InputPrivacy = 'default' | 'mask' | 'hide';

export interface CoverageInput {
  setValue(value: string): void;
  setPassword(revealed: boolean): void;
  setVisible(visible: boolean): void;
  setPrivacy(mode: InputPrivacy): void;
  blur(): void;
  destroy(): void;
}

/** Engine adapters own real EditBox components; input values never cross the event boundary. */
export interface ReplayInputUI {
  input(id: InputCase, kind: InputKind, y: number, phase: (phase: InputPhase) => void): CoverageInput;
  button(name: string, text: string, x: number, y: number, click: () => void): void;
  status(text: string): void;
  transform(moved: boolean): void;
}

const INITIAL_VALUES: Record<InputCase, string> = {
  I01: 'DEMO-NORMAL-3141',
  I02: 'DEMO-PASSWORD-2718',
  I03: 'DEMO-SENSITIVE-1618',
  I04: 'DEMO-DYNAMIC-5772',
};

export class ReplayInputCoverage {
  private inputs: Partial<Record<InputCase, CoverageInput>> = {};
  private revealed = false;
  private visible = true;
  private moved = false;
  private empty = false;
  private privacy: InputPrivacy = 'default';
  private disposed = false;

  constructor(
    private readonly ui: ReplayInputUI,
    private readonly track: (id: InputCase | 'page', stage: string) => void,
    private readonly exit: () => void,
  ) {
    this.create('I01', 'normal', 155);
    this.create('I02', 'password', 65);
    this.create('I03', 'sensitive', -25);
    this.create('I04', 'normal', -115);
    ui.button('PasswordVisibility', 'Reveal / hide password', -345, -245, () => {
      if (this.disposed) return;
      this.blur();
      this.revealed = !this.revealed;
      this.inputs.I02!.setPassword(this.revealed);
      this.record('I02', this.revealed ? 'password-revealed' : 'password-hidden');
    });
    ui.button('InputValues', 'Clear / fill demo text', -115, -245, () => {
      if (this.disposed) return;
      this.blur();
      this.empty = !this.empty;
      this.each((input, id) => input.setValue(this.empty ? '' : INITIAL_VALUES[id]));
      this.record('page', this.empty ? 'values-cleared' : 'demo-values-filled');
    });
    ui.button('InputVisibility', 'Hide / show inputs', 115, -245, () => {
      if (this.disposed) return;
      this.blur();
      this.visible = !this.visible;
      this.each(input => input.setVisible(this.visible));
      this.record('page', this.visible ? 'inputs-shown' : 'inputs-hidden');
    });
    ui.button('InputTransform', 'Move + scale / reset', 345, -245, () => {
      if (this.disposed) return;
      this.blur();
      this.moved = !this.moved;
      ui.transform(this.moved);
      this.record('page', this.moved ? 'transformed' : 'transform-reset');
    });
    ui.button('DynamicInput', 'Destroy / create I04', -345, -295, () => {
      if (this.disposed) return;
      if (this.inputs.I04) {
        const input = this.inputs.I04;
        delete this.inputs.I04;
        input.blur();
        input.destroy();
        this.record('I04', 'destroyed');
      } else {
        this.create('I04', 'normal', -115);
        this.record('I04', 'created');
      }
    });
    ui.button('InputPrivacy', 'I04: default / mask / hide', -115, -295, () => {
      if (this.disposed) return;
      this.blur();
      this.privacy = this.privacy === 'default' ? 'mask' : this.privacy === 'mask' ? 'hide' : 'default';
      this.inputs.I04?.setPrivacy(this.privacy);
      this.record('I04', `privacy-${this.privacy}`);
    });
    ui.button('BlurInputs', 'Blur / close keyboard', 115, -295, () => {
      if (this.disposed) return;
      this.blur();
      this.record('page', 'blur-all');
    });
    ui.button('ExitInputCoverage', 'Back to coverage', 345, -295, () => {
      if (this.disposed) return;
      this.record('page', 'exit');
      this.dispose();
      exit();
    });
    this.record('page', 'entered');
  }

  private create(id: InputCase, kind: InputKind, y: number): void {
    const input = this.ui.input(id, kind, y, phase => {
      if (!this.disposed && this.inputs[id] === input) this.record(id, phase);
    });
    this.inputs[id] = input;
    input.setValue(this.empty ? '' : INITIAL_VALUES[id]);
    input.setVisible(this.visible);
    if (id === 'I04') input.setPrivacy(this.privacy);
  }

  private each(callback: (input: CoverageInput, id: InputCase) => void): void {
    (Object.keys(this.inputs) as InputCase[]).forEach(id => callback(this.inputs[id]!, id));
  }

  private blur(): void { this.each(input => input.blur()); }

  private record(id: InputCase | 'page', stage: string): void {
    if (this.disposed) return;
    this.ui.status(`${id} / ${stage} | I04 privacy: ${this.privacy}`);
    this.track(id, stage);
  }

  dispose(): void {
    if (this.disposed) return;
    this.disposed = true;
    this.each(input => { input.blur(); input.destroy(); });
    this.inputs = {};
  }
}
