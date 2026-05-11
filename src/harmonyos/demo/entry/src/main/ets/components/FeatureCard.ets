import {
  AppColors,
  BorderRadius,
  FontSizes,
  Heights,
  Spacing,
  StrokeWidths
} from '../constants/UIConstants';

@Component
export struct FeatureCard {
  title: string = '';
  description: string = '';
  actionText: string = '';
  accentColor: string = AppColors.PRIMARY;
  accentBgColor: string = AppColors.PRIMARY_SOFT;
  onTap: () => void = () => {};

  build() {
    Column() {
      Row() {
        Column()
          .width(StrokeWidths.ACCENT)
          .height(Heights.FEATURE_ACCENT)
          .backgroundColor(this.accentColor)
          .borderRadius(BorderRadius.PILL)
          .margin({ right: Spacing.MD })

        Column() {
          Text(this.title)
            .fontSize(FontSizes.MEDIUM)
            .fontWeight(FontWeight.Bold)
            .fontColor(AppColors.TEXT_PRIMARY)
            .width('100%')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          if (this.description.length > 0) {
            Text(this.description)
              .fontSize(FontSizes.CAPTION)
              .fontColor(AppColors.TEXT_SECONDARY)
              .width('100%')
              .margin({ top: Spacing.XS })
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      if (this.actionText.length > 0) {
        Button(this.actionText)
          .width('100%')
          .height(Heights.BUTTON)
          .fontSize(FontSizes.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.accentColor)
          .backgroundColor(this.accentBgColor)
          .border({ width: StrokeWidths.HAIRLINE, color: this.accentColor })
          .borderRadius(BorderRadius.SMALL)
          .margin({ top: Spacing.MD })
          .onClick(() => {
            this.onTap();
          })
      }
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(Spacing.LG)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(BorderRadius.CARD)
    .border({ width: StrokeWidths.HAIRLINE, color: AppColors.BORDER })
  }
}
