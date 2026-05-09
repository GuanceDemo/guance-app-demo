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
      if (this.showBack) {
        Text('‹')
          .fontSize(28)
          .fontColor(AppColors.WHITE)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onBack();
          })
      }

      Text(this.title)
        .fontSize(FontSizes.TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor(AppColors.WHITE)
        .layoutWeight(1)
        .textAlign(this.showBack ? TextAlign.Center :TextAlign.LEFT)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      if (this.rightText.length > 0) {
        Text(this.rightText)
          .fontSize(IconSizes.LARGE)
          .fontColor(AppColors.WHITE)
          .width(IconSizes.LARGE)
          .height(32)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.onRightClick();
          })
      } else {
        Row()
          .width(IconSizes.LARGE)
          .height(32)
      }
    }
    .width('100%')
    .height(Heights.TOOLBAR)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .padding({ left: Spacing.LG, right: Spacing.LG })
    .backgroundColor(AppColors.PRIMARY)
  }
}
