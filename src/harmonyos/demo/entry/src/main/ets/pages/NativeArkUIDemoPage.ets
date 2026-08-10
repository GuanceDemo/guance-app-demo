import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { FTRUMGlobalManager } from '@guancecloud/ft_sdk';
import { AppColors, BorderRadius, FontSizes, Spacing } from '../constants/UIConstants';
import { AppNavBar } from '../components/AppNavBar';

interface ArkUIListItem {
  id: number;
  title: string;
  description: string;
  level: string;
}

@Entry
@Component
struct NativeArkUIDemoPage {
  @State selectedTab: number = 0;
  @State username: string = 'guance';
  @State switchEnabled: boolean = true;
  @State checkboxSelected: boolean = true;
  @State progress: number = 36;
  @State selectedMode: string = 'standard';
  @State listVersion: number = 3;
  @State dataList: ArkUIListItem[] = [
    {
      id: 1,
      title: 'RUM View 追踪',
      description: '进入页面时 startView，离开页面时 stopView。',
      level: 'View'
    },
    {
      id: 2,
      title: '点击 Action 追踪',
      description: '按钮、Tab、Switch、Checkbox 和列表点击都会写入 Action。',
      level: 'Action'
    },
  ];

  aboutToAppear(): void {
    FTRUMGlobalManager.getInstance().startView('NativeArkUIDemoPage');
  }

  aboutToDisappear(): void {
    FTRUMGlobalManager.getInstance().stopView();
  }

  build() {
    Column() {
      AppNavBar({
        title: 'ArkUI Demo',
        showBack: true,
        onBack: () => {
          router.back();
        }
      })

      Tabs({ barPosition: BarPosition.Start, index: this.selectedTab }) {
        TabContent() {
          this.ControlDemo()
        }
        .tabBar('控件')

        TabContent() {
          this.DynamicListDemo()
        }
        .tabBar('列表')
      }
      .layoutWeight(1)
      .onChange((index: number) => {
        this.selectedTab = index;
        this.trackAction(`arkui_tab_${index}`);
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BACKGROUND)
  }

  @Builder
  ControlDemo() {
    Scroll() {
      Column() {
        this.HeroPanel('ArkUI 控件验证', '覆盖输入、切换、勾选、滑动和 Tab 切换，用于观察 RUM View 与 Action 采集。')
        this.SectionTitle('输入与选择')

        Column() {
          Text('账号信息')
            .fontSize(FontSizes.NORMAL)
            .fontWeight(FontWeight.Medium)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')

          TextInput({ placeholder: '用户名', text: this.username })
            .width('100%')
            .height(44)
            .margin({ top: Spacing.SM })
            .backgroundColor(AppColors.INPUT_BG)
            .borderRadius(BorderRadius.SMALL)
            .onChange((value: string) => {
              this.username = value;
            })

        }
        .width('100%')
        .padding(Spacing.MD)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(BorderRadius.SMALL)

        Row() {
          Column() {
            Text('采集开关')
              .fontSize(FontSizes.NORMAL)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)

            Text(this.switchEnabled ? '当前允许记录交互' : '当前仅保留页面展示')
              .fontSize(FontSizes.SMALL)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ top: Spacing.XS })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.switchEnabled })
            .onChange((isOn: boolean) => {
              this.switchEnabled = isOn;
              this.trackAction(isOn ? 'arkui_switch_on' : 'arkui_switch_off');
            })
        }
        .width('100%')
        .padding(Spacing.MD)
        .margin({ top: Spacing.SM })
        .backgroundColor(AppColors.WHITE)
        .borderRadius(BorderRadius.SMALL)

        Row() {
          Checkbox({ name: 'mask', group: 'arkui_demo' })
            .select(this.checkboxSelected)
            .onChange((isSelected: boolean) => {
              this.checkboxSelected = isSelected;
              this.trackAction(isSelected ? 'arkui_checkbox_selected' : 'arkui_checkbox_unselected');
            })

          Column() {
            Text('Checkbox 控件')
              .fontSize(FontSizes.NORMAL)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)

            Text('用于验证勾选状态变化与 Action 采集')
              .fontSize(FontSizes.SMALL)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ top: Spacing.XS })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
          .margin({ left: Spacing.SM })
        }
        .width('100%')
        .padding(Spacing.MD)
        .margin({ top: Spacing.SM })
        .backgroundColor(AppColors.WHITE)
        .borderRadius(BorderRadius.SMALL)

        this.SectionTitle('Slider 与模式')
        Column() {
          Row() {
            Text('采样比例')
              .fontSize(FontSizes.NORMAL)
              .fontWeight(FontWeight.Medium)
              .fontColor(AppColors.TEXT_PRIMARY)
              .layoutWeight(1)

            this.Badge(`${Math.round(this.progress)}%`, AppColors.PRIMARY)
          }
          .width('100%')

          Slider({ value: this.progress, min: 0, max: 100, step: 1 })
            .width('100%')
            .margin({ top: Spacing.SM })
            .onChange((value: number) => {
              this.progress = value;
            })
        }
        .width('100%')
        .padding(Spacing.MD)
        .backgroundColor(AppColors.WHITE)
        .borderRadius(BorderRadius.SMALL)

        this.ModeSelector()

        Button('记录控件页 Action')
          .width('100%')
          .height(44)
          .margin({ top: Spacing.LG })
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .borderRadius(BorderRadius.SMALL)
          .onClick(() => {
            this.trackAction('arkui_control_confirm');
            promptAction.showToast({ message: `Action 已记录：${this.username}`, duration: 1500 });
          })
      }
      .width('100%')
      .padding(Spacing.MD)
    }
  }

  @Builder
  DynamicListDemo() {
    Column() {
      Column() {
        Row() {
          Column() {
            Text('动态列表')
              .fontSize(FontSizes.MEDIUM)
              .fontWeight(FontWeight.Bold)
              .fontColor(AppColors.TEXT_PRIMARY)

            Text(`${this.dataList.length} 个验证项，支持新增、删除和详情跳转`)
              .fontSize(FontSizes.SMALL)
              .fontColor(AppColors.TEXT_SECONDARY)
              .margin({ top: Spacing.XS })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Button('新增')
            .height(36)
            .backgroundColor(AppColors.PRIMARY)
            .fontColor(AppColors.WHITE)
            .borderRadius(BorderRadius.SMALL)
            .onClick(() => {
              this.addListItem();
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding(Spacing.MD)
      .backgroundColor(AppColors.WHITE)

      List() {
        ForEach(this.dataList, (item: ArkUIListItem) => {
          ListItem() {
            this.ListItemBuilder(item)
          }
        }, (item: ArkUIListItem) => item.id.toString())
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.MD })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  HeroPanel(title: string, description: string) {
    Column() {
      Text(title)
        .fontSize(FontSizes.LARGE)
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
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  SectionTitle(title: string) {
    Text(title)
      .fontSize(FontSizes.MEDIUM)
      .fontWeight(FontWeight.Bold)
      .fontColor(AppColors.TEXT_PRIMARY)
      .width('100%')
      .margin({ top: Spacing.SM, bottom: Spacing.SM })
  }

  @Builder
  Badge(text: string, color: string) {
    Text(text)
      .fontSize(FontSizes.SMALL)
      .fontColor(color)
      .padding({ left: Spacing.SM, right: Spacing.SM, top: Spacing.XS, bottom: Spacing.XS })
      .margin({ right: Spacing.SM })
      .backgroundColor(AppColors.INPUT_BG)
      .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  ModeSelector() {
    Row() {
      this.ModeButton('standard', '标准')
      this.ModeButton('privacy', '隐私')
      this.ModeButton('stress', '压测')
    }
    .width('100%')
    .padding(Spacing.XS)
    .margin({ top: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  @Builder
  ModeButton(value: string, label: string) {
    Button(label)
      .layoutWeight(1)
      .height(40)
      .margin({ right: value === 'stress' ? 0 : Spacing.SM })
      .backgroundColor(this.selectedMode === value ? AppColors.PRIMARY : AppColors.INPUT_BG)
      .fontColor(this.selectedMode === value ? AppColors.WHITE : AppColors.TEXT_PRIMARY)
      .borderRadius(BorderRadius.SMALL)
      .onClick(() => {
        this.selectedMode = value;
        this.trackAction(`arkui_mode_${value}`);
      })
  }

  @Builder
  ListItemBuilder(item: ArkUIListItem) {
    Column() {
      Row() {
        Image($r('app.media.ohos'))
          .width(48)
          .height(48)
          .objectFit(ImageFit.Contain)
          .margin({ right: Spacing.SM })

        Column() {
          Row() {
            Text(item.title)
              .fontSize(FontSizes.NORMAL)
              .fontColor(AppColors.TEXT_PRIMARY)
              .fontWeight(FontWeight.Medium)
              .layoutWeight(1)

            this.Badge(item.level, this.getLevelColor(item.level))
          }
          .width('100%')

          Text(item.description)
            .fontSize(FontSizes.SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ top: Spacing.XS })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')

      Row() {
        Button('详情')
          .height(34)
          .layoutWeight(1)
          .backgroundColor(AppColors.PRIMARY)
          .fontColor(AppColors.WHITE)
          .borderRadius(BorderRadius.SMALL)
          .onClick(() => {
            this.openDetail(item);
          })

        Button('删除')
          .height(34)
          .layoutWeight(1)
          .margin({ left: Spacing.SM })
          .backgroundColor(AppColors.INPUT_BG)
          .fontColor(AppColors.WARNING)
          .borderRadius(BorderRadius.SMALL)
          .onClick(() => {
            this.deleteListItem(item.id);
          })
      }
      .width('100%')
      .margin({ top: Spacing.MD })
    }
    .width('100%')
    .padding(Spacing.MD)
    .margin({ bottom: Spacing.SM })
    .backgroundColor(AppColors.WHITE)
    .borderRadius(BorderRadius.SMALL)
  }

  private addListItem(): void {
    const nextId = this.listVersion + 1;
    this.listVersion = nextId;
    this.dataList = [{
      id: nextId,
      title: `动态验证项 ${nextId}`,
      description: `新增于 ${new Date().toLocaleTimeString()}，用于验证列表变化和动态数据刷新。`,
      level: nextId % 2 === 0 ? 'Action' : 'View'
    }, ...this.dataList];
    this.trackAction('arkui_dynamic_list_add');
  }

  private deleteListItem(itemId: number): void {
    this.dataList = this.dataList.filter((item: ArkUIListItem) => item.id !== itemId);
    this.trackAction(`arkui_dynamic_list_delete_${itemId}`);
    promptAction.showToast({ message: '验证项已删除', duration: 1200 });
  }

  private openDetail(item: ArkUIListItem): void {
    this.trackAction(`arkui_list_${item.id}`);
    router.pushUrl({
      url: 'pages/NativeArkUIDetailPage',
      params: {
        id: item.id.toString(),
        title: item.title,
        description: item.description,
        level: item.level
      }
    });
  }

  private getLevelColor(level: string): string {
    if (level === 'View') {
      return AppColors.INFO;
    }
    return AppColors.PRIMARY;
  }

  private trackAction(actionName: string): void {
    FTRUMGlobalManager.getInstance().addAction(actionName, 'click', {} as Record<string, object>);
  }
}
