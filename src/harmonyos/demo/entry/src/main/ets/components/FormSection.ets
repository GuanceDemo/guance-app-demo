import {
  AppColors,
  BorderRadius,
  FontSizes,
  Spacing,
  StrokeWidths
} from '../constants/UIConstants';

@Builder
function EmptySectionContent() {
}

@Component
export struct FormSection {
  title: string = '';
  description: string = '';
  @BuilderParam content: () => void = EmptySectionContent;

  build() {
    Column() {
      if (this.title.length > 0) {
        Text(this.title)
          .fontSize(FontSizes.MEDIUM)
          .fontWeight(FontWeight.Bold)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')
      }

      if (this.description.length > 0) {
        Text(this.description)
          .fontSize(FontSizes.CAPTION)
          .fontColor(AppColors.TEXT_SECONDARY)
          .width('100%')
          .margin({ top: Spacing.XS })
      }

      Column() {
        this.content()
      }
      .width('100%')
      .margin({ top: this.title.length > 0 || this.description.length > 0 ? Spacing.MD : 0 })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(Spacing.LG)
    .backgroundColor(AppColors.SURFACE)
    .borderRadius(BorderRadius.CARD)
    .border({ width: StrokeWidths.HAIRLINE, color: AppColors.BORDER })
  }
}
