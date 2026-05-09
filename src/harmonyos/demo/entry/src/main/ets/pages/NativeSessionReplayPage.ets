import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { AppColors, BorderRadius, FontSizes, Spacing } from '../constants/UIConstants';
import { AppNavBar } from '../components/AppNavBar';

class ReplaySelectOption {
  value: string;

  constructor(value: string) {
    this.value = value;
  }
}

@Entry
@Component
struct NativeSessionReplayPage {
  @State selectedTabIndex: number = 0;

  @State materialText: string = 'Material input';
  @State materialPassword: string = 'material-secret';
  @State materialCheckedText: boolean = true;
  @State materialCheckbox: boolean = true;
  @State materialRadio: string = 'Radio A';
  @State materialSwitch: boolean = true;
  @State materialSpinnerIndex: number = 2;
  @State materialSpinnerValue: string = 'Earth';
  @State materialTime: string = '09:30';
  @State materialDate: string = '2026-05-09';
  @State materialSeek: number = 20;
  @State materialNumber: number = 4;
  @State materialRegion: string = 'Shanghai';

  @State nativeText: string = 'Native input';
  @State nativePassword: string = 'native-secret';
  @State nativeCheckedText: boolean = false;
  @State nativeCheckbox: boolean = false;
  @State nativeRadio: string = 'Native B';
  @State nativeSwitch: boolean = false;
  @State nativeSpinnerIndex: number = 0;
  @State nativeSpinnerValue: string = 'Mercury';
  @State nativeTime: string = '14:20';
  @State nativeDate: string = '2026-05-09';
  @State nativeProgress: number = 56;
  @State nativeNumber: number = 6;
  @State nativeRegion: string = 'Hangzhou';

  private planets: string[] = ['Mercury', 'Venus', 'Earth', 'Mars', 'Jupiter'];
  private regions: string[] = ['Beijing', 'Shanghai', 'Hangzhou', 'Shenzhen', 'Guangzhou'];

  build() {
    Column() {
      AppNavBar({
        title: 'Session Replay',
        showBack: true,
        onBack: () => {
          router.back();
        }
      })

      Tabs({ barPosition: BarPosition.Start, index: this.selectedTabIndex }) {
        TabContent() {
          this.MaterialCompatDemo()
        }
        .tabBar('Material')

        TabContent() {
          this.NativeComponentDemo()
        }
        .tabBar('Native')
      }
      .layoutWeight(1)
      .onChange((index: number) => {
        this.selectedTabIndex = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  MaterialCompatDemo() {
    Scroll() {
      Column() {
        this.HeroPanel('Material 兼容组件', '对齐 Android Material Fragment，覆盖输入、选择、开关、下拉、日期时间、进度与图片。')

        this.TextInputCard('EditText', '输入框', this.materialText, false, (value: string) => {
          this.materialText = value;
        })
        this.TextInputCard('Password EditText', '隐私输入框', this.materialPassword, true, (value: string) => {
          this.materialPassword = value;
        })
        this.CheckedTextCard('CheckedTextView', this.materialCheckedText, (value: boolean) => {
          this.materialCheckedText = value;
        })
        this.CheckboxCard('MaterialCheckBox', this.materialCheckbox, (value: boolean) => {
          this.materialCheckbox = value;
        })
        this.RadioGroupCard('MaterialRadioButton', this.materialRadio, 'Radio A', 'Radio B', (value: string) => {
          this.materialRadio = value;
        })
        this.SwitchCard('SwitchMaterial', this.materialSwitch, (value: boolean) => {
          this.materialSwitch = value;
        })
        this.SelectCard('Spinner', this.materialSpinnerIndex, (index: number, value: string) => {
          this.materialSpinnerIndex = index;
          this.materialSpinnerValue = value;
        })
        this.DateTimeCard('Material Picker', this.materialDate, this.materialTime, (date: string) => {
          this.materialDate = date;
        }, (time: string) => {
          this.materialTime = time;
        })
        this.RegionPickerCard('Region Picker', this.materialRegion, (value: string) => {
          this.materialRegion = value;
        })
        this.ProgressCard('SeekBar / Progress', this.materialSeek, (value: number) => {
          this.materialSeek = value;
        })
        this.NumberPickerCard('NumberPicker', this.materialNumber, (value: number) => {
          this.materialNumber = value;
        })
        this.ImageCard()

        Button('custom toast')
          .width('100%')
          .height(44)
          .margin({ top: Spacing.SM, bottom: Spacing.LG })
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .borderRadius(BorderRadius.SMALL)
          .onClick(() => {
            promptAction.showToast({ message: `Toast:${Date.now()}`, duration: 1200 });
          })

        Blank()
          .height(48)
          .width('100%')
          .onClick(() => {
            this.clearInputFocus();
          })
      }
      .width('100%')
      .padding(Spacing.MD)
    }
  }

  @Builder
  NativeComponentDemo() {
    Scroll() {
      Column() {
        this.HeroPanel('ArkUI 原生组件', '对齐 Android AppCompat Fragment，用 ArkUI 原生控件验证同类 Session Replay 场景。')

        this.TextInputCard('TextInput', '输入框', this.nativeText, false, (value: string) => {
          this.nativeText = value;
        })
        this.TextInputCard('Password TextInput', '隐私输入框', this.nativePassword, true, (value: string) => {
          this.nativePassword = value;
        })
        this.CheckedTextCard('Checked Text Row', this.nativeCheckedText, (value: boolean) => {
          this.nativeCheckedText = value;
        })
        this.CheckboxCard('Checkbox', this.nativeCheckbox, (value: boolean) => {
          this.nativeCheckbox = value;
        })
        this.RadioGroupCard('Radio', this.nativeRadio, 'Native A', 'Native B', (value: string) => {
          this.nativeRadio = value;
        })
        this.SwitchCard('Switch', this.nativeSwitch, (value: boolean) => {
          this.nativeSwitch = value;
        })
        this.SelectCard('Select 下拉菜单', this.nativeSpinnerIndex, (index: number, value: string) => {
          this.nativeSpinnerIndex = index;
          this.nativeSpinnerValue = value;
        })
        this.DateTimeCard('DatePicker / TimePicker', this.nativeDate, this.nativeTime, (date: string) => {
          this.nativeDate = date;
        }, (time: string) => {
          this.nativeTime = time;
        })
        this.RegionPickerCard('地区选择 Picker', this.nativeRegion, (value: string) => {
          this.nativeRegion = value;
        })
        this.ProgressCard('Progress / Slider', this.nativeProgress, (value: number) => {
          this.nativeProgress = value;
        })
        this.NumberPickerCard('Stepper NumberPicker', this.nativeNumber, (value: number) => {
          this.nativeNumber = value;
        })
        this.ImageCard()

        Blank()
          .height(48)
          .width('100%')
          .onClick(() => {
            this.clearInputFocus();
          })
      }
      .width('100%')
      .padding(Spacing.MD)
    }
  }

  @Builder
  HeroPanel(title: string, description: string) {
    Column() {
      Text(title)
        .fontSize(FontSizes.MEDIUM)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_PRIMARY)
        .width('100%')

      Text(description)
        .fontSize(FontSizes.SMALL)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ top: Spacing.SM })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.SM, bottom: Spacing.SM })
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  TextInputCard(title: string, placeholder: string, value: string, isPassword: boolean, onChange: (value: string) => void) {
    Column() {
      this.CardTitle(title)
      TextInput({ placeholder: placeholder, text: value })
        .width('100%')
        .height(44)
        .margin({ top: Spacing.SM })
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(BorderRadius.SMALL)
        .type(isPassword ? InputType.Password : InputType.Normal)
        .enterKeyType(EnterKeyType.Done)
        .onChange((text: string) => {
          onChange(text);
        })
        .onSubmit(() => {
          this.clearInputFocus();
        })
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  CheckedTextCard(title: string, checked: boolean, onChange: (value: boolean) => void) {
    Row() {
      Column() {
        this.CardTitle(title)
        Text(checked ? 'checked' : 'unchecked')
          .fontSize(FontSizes.SMALL)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ top: Spacing.XS })

        Text(`输出：${checked ? 'selected' : 'unselected'}`)
          .fontSize(FontSizes.SMALL)
          .fontColor(checked ? AppColors.PRIMARY : AppColors.TEXT_HINT)
          .margin({ top: Spacing.XS })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Text(checked ? '✓' : '')
        .width(28)
        .height(28)
        .fontSize(FontSizes.MEDIUM)
        .fontColor(AppColors.WHITE)
        .textAlign(TextAlign.Center)
        .backgroundColor(checked ? AppColors.PRIMARY : AppColors.LIGHT_GRAY)
        .borderRadius(14)
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
    .onClick(() => {
      onChange(!checked);
    })
  }

  @Builder
  CheckboxCard(title: string, checked: boolean, onChange: (value: boolean) => void) {
    Row() {
      Checkbox({ name: title, group: 'checkbox' })
        .select(checked)
        .onChange((value: boolean) => {
          onChange(value);
        })

      Text(title)
        .fontSize(FontSizes.NORMAL)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ left: Spacing.SM })
        .layoutWeight(1)
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  RadioGroupCard(title: string, selected: string, optionA: string, optionB: string, onChange: (value: string) => void) {
    Column() {
      this.CardTitle(title)
      Row() {
        this.RadioOption(optionA, selected, onChange)
        this.RadioOption(optionB, selected, onChange)
      }
      .width('100%')
      .margin({ top: Spacing.SM })
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  RadioOption(value: string, selected: string, onChange: (value: string) => void) {
    Row() {
      Radio({ value: value, group: `radio_${selected}` })
        .checked(selected === value)
        .onChange((checked: boolean) => {
          if (checked) {
            onChange(value);
          }
        })

      Text(value)
        .fontSize(FontSizes.NORMAL)
        .fontColor(AppColors.TEXT_PRIMARY)
        .margin({ left: Spacing.XS })
    }
    .layoutWeight(1)
  }

  @Builder
  SwitchCard(title: string, enabled: boolean, onChange: (value: boolean) => void) {
    Row() {
      Column() {
        this.CardTitle(title)
        Text(enabled ? 'On' : 'Off')
          .fontSize(FontSizes.SMALL)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ top: Spacing.XS })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: enabled })
        .onChange((value: boolean) => {
          onChange(value);
        })
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  SelectCard(title: string, selectedIndex: number, onSelect: (index: number, value: string) => void) {
    Column() {
      this.CardTitle(title)
      Select(this.planets.map((item: string) => new ReplaySelectOption(item)))
        .selected(selectedIndex)
        .value(this.planets[selectedIndex])
        .width('100%')
        .margin({ top: Spacing.SM })
        .onSelect((index: number, value: string) => {
          onSelect(index, value);
        })
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  DateTimeCard(
    title: string,
    dateText: string,
    timeText: string,
    onDateChange: (value: string) => void,
    onTimeChange: (value: string) => void
  ) {
    Column() {
      this.CardTitle(title)
      Row() {
        Text(dateText)
          .fontSize(FontSizes.SMALL)
          .fontColor(AppColors.TEXT_SECONDARY)
          .layoutWeight(1)

        Text(timeText)
          .fontSize(FontSizes.SMALL)
          .fontColor(AppColors.TEXT_SECONDARY)
      }
      .width('100%')
      .margin({ top: Spacing.XS, bottom: Spacing.SM })

      Row() {
        Button('选择日期')
          .layoutWeight(1)
          .height(40)
          .backgroundColor(AppColors.INPUT_BG)
          .fontColor(AppColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.SMALL)
          .onClick(() => {
            this.showDateDialog(onDateChange);
          })

        Button('选择时间')
          .layoutWeight(1)
          .height(40)
          .margin({ left: Spacing.SM })
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .borderRadius(BorderRadius.SMALL)
          .onClick(() => {
            this.showTimeDialog(onTimeChange);
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  ProgressCard(title: string, value: number, onChange: (value: number) => void) {
    Column() {
      Row() {
        this.CardTitle(title)
        Text(`${Math.round(value)}%`)
          .fontSize(FontSizes.SMALL)
          .fontColor(AppColors.PRIMARY)
      }
      .width('100%')

      Progress({ value: value, total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(8)
        .margin({ top: Spacing.SM })

      Slider({ value: value, min: 0, max: 100, step: 1 })
        .width('100%')
        .margin({ top: Spacing.SM })
        .onChange((next: number) => {
          onChange(next);
        })
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  RegionPickerCard(title: string, value: string, onChange: (value: string) => void) {
    Row() {
      Column() {
        this.CardTitle(title)
        Text(value)
          .fontSize(FontSizes.SMALL)
          .fontColor(AppColors.TEXT_SECONDARY)
          .margin({ top: Spacing.XS })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Button('选择地区')
        .height(40)
        .backgroundColor(AppColors.INPUT_BG)
        .fontColor(AppColors.TEXT_PRIMARY)
        .borderRadius(BorderRadius.SMALL)
        .onClick(() => {
          this.showRegionDialog(value, onChange);
        })
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  NumberPickerCard(title: string, value: number, onChange: (value: number) => void) {
    Column() {
      this.CardTitle(title)
      Row() {
        Button('-')
          .width(52)
          .height(44)
          .backgroundColor(value <= 0 ? AppColors.LIGHT_GRAY : AppColors.INPUT_BG)
          .fontColor(value <= 0 ? AppColors.TEXT_DISABLED : AppColors.TEXT_PRIMARY)
          .borderRadius(BorderRadius.SMALL)
          .onClick(() => {
            onChange(Math.max(0, value - 1));
          })

        Column() {
          Text(value.toString())
            .fontSize(FontSizes.HUGE)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.PRIMARY)

          Progress({ value: value, total: 10, type: ProgressType.Linear })
            .width('100%')
            .height(6)
            .margin({ top: Spacing.XS })
        }
        .layoutWeight(1)
        .padding({ left: Spacing.MD, right: Spacing.MD })

        Button('+')
          .width(52)
          .height(44)
          .backgroundColor(value >= 10 ? AppColors.LIGHT_GRAY : AppColors.PRIMARY)
          .fontColor(value >= 10 ? AppColors.TEXT_DISABLED : AppColors.WHITE)
          .borderRadius(BorderRadius.SMALL)
          .onClick(() => {
            onChange(Math.min(10, value + 1));
          })
      }
      .width('100%')
      .margin({ top: Spacing.SM })
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  ImageCard() {
    Column() {
      this.CardTitle('ImageView / Image')
      Row() {
        Image($r('app.media.home_activity'))
          .width('48%')
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius(BorderRadius.SMALL)
          .backgroundColor(AppColors.LIGHT_GRAY)

        Image($r('app.media.login_logo'))
          .width('48%')
          .height(120)
          .objectFit(ImageFit.Contain)
          .borderRadius(BorderRadius.SMALL)
          .backgroundColor(AppColors.INPUT_BG)
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .width('100%')
      .margin({ top: Spacing.SM })
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  CardTitle(title: string) {
    Text(title)
      .fontSize(FontSizes.NORMAL)
      .fontWeight(FontWeight.Medium)
      .fontColor(AppColors.TEXT_PRIMARY)
  }

  private pad(value: number): string {
    return value < 10 ? `0${value}` : value.toString();
  }

  private clearInputFocus(): void {
    this.getUIContext().getFocusController().clearFocus();
  }

  private showDateDialog(onDateChange: (value: string) => void): void {
    DatePickerDialog.show({
      start: new Date('2024-01-01'),
      end: new Date('2028-12-31'),
      selected: new Date(),
      onAccept: (value: DatePickerResult) => {
        const year = value.year ?? new Date().getFullYear();
        const month = value.month ?? 1;
        const day = value.day ?? 1;
        onDateChange(`${year}-${this.pad(month)}-${this.pad(day)}`);
      }
    });
  }

  private showTimeDialog(onTimeChange: (value: string) => void): void {
    TimePickerDialog.show({
      selected: new Date(),
      onAccept: (value: TimePickerResult) => {
        const hour = value.hour ?? 0;
        const minute = value.minute ?? 0;
        onTimeChange(`${this.pad(hour)}:${this.pad(minute)}`);
      }
    });
  }

  private showRegionDialog(currentValue: string, onChange: (value: string) => void): void {
    const selectedIndex = Math.max(0, this.regions.indexOf(currentValue));
    TextPickerDialog.show({
      range: this.regions,
      selected: selectedIndex,
      onAccept: (value: TextPickerResult) => {
        let index: number = selectedIndex;
        if (typeof value.index === 'number') {
          index = value.index;
        }
        const nextRegion = this.regions[index] ?? this.regions[selectedIndex];
        onChange(nextRegion);
      }
    });
  }
}
