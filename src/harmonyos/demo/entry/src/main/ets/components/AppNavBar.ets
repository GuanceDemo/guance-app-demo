import { AppColors, FontSizes, Heights, IconSizes, Spacing } from '../constants/UIConstants';

@Preview
@Component
export struct AppNavBar {
  title: string = '';
  showBack: boolean = false;
  rightText: string = '';
  onBack: () => void = () => {};
  onRightClick: () => void = () => {};

  build() {
    Row() {
      Row() {
        if (this.showBack) {
          Text('‹')
            .fontSize(IconSizes.NAV)
            .fontColor(AppColors.TEXT_INVERSE)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
        }
      }
      .width(this.showBack ? Heights.TOUCH_TARGET : 0)
      .height(Heights.TOUCH_TARGET)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .borderRadius(Heights.TOUCH_TARGET / 2)
      .onClick(() => {
        if (this.showBack) {
          this.onBack();
        }
      })

      Text(this.title)
        .fontSize(FontSizes.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.TEXT_INVERSE)
        .layoutWeight(1)
        .textAlign(this.showBack ? TextAlign.Center : TextAlign.Start)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        if (this.rightText.length > 0) {
          Text(this.rightText)
            .fontSize(FontSizes.MEDIUM)
            .fontColor(AppColors.TEXT_INVERSE)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
        }
      }
      .width(this.showBack || this.rightText.length > 0 ? Heights.TOUCH_TARGET : 0)
      .height(Heights.TOUCH_TARGET)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .borderRadius(Heights.TOUCH_TARGET / 2)
      .onClick(() => {
        if (this.rightText.length > 0) {
          this.onRightClick();
        }
      })
    }
    .width('100%')
    .height(Heights.NAV_BAR)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ left: Spacing.MD, right: Spacing.MD })
    .backgroundColor(AppColors.PRIMARY)
  }
}
