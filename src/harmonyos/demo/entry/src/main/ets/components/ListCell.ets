import {
  AppColors,
  BorderRadius,
  FontSizes,
  Heights,
  IconSizes,
  Spacing
} from '../constants/UIConstants';

@Component
export struct ListCell {
  title: string = '';
  description: string = '';
  iconText: string = '';
  iconBgColor: string = AppColors.PRIMARY_SOFT;
  iconColor: string = AppColors.PRIMARY;
  valueText: string = '';
  showChevron: boolean = true;
  onTap: () => void = () => {};

  build() {
    Row() {
      if (this.iconText.length > 0) {
        Text(this.iconText)
          .fontSize(FontSizes.MEDIUM)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.iconColor)
          .textAlign(TextAlign.Center)
          .width(IconSizes.CELL)
          .height(IconSizes.CELL)
          .backgroundColor(this.iconBgColor)
          .borderRadius(BorderRadius.SMALL)
          .margin({ right: Spacing.MD })
      }

      Column() {
        Text(this.title)
          .fontSize(FontSizes.BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppColors.TEXT_PRIMARY)
          .width('100%')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (this.description.length > 0) {
          Text(this.description)
            .fontSize(FontSizes.SMALL)
            .fontColor(AppColors.TEXT_SECONDARY)
            .width('100%')
            .margin({ top: Spacing.XS })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      if (this.valueText.length > 0) {
        Text(this.valueText)
          .fontSize(FontSizes.CAPTION)
          .fontColor(AppColors.TEXT_HINT)
          .margin({ left: Spacing.SM })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      if (this.showChevron) {
        Text('›')
          .fontSize(FontSizes.TITLE)
          .fontColor(AppColors.TEXT_HINT)
          .margin({ left: Spacing.SM })
      }
    }
    .width('100%')
    .height(Heights.LIST_CELL)
    .padding({ left: Spacing.MD, right: Spacing.MD, top: Spacing.SM, bottom: Spacing.SM })
    .backgroundColor(AppColors.SURFACE_MUTED)
    .borderRadius(BorderRadius.CARD)
    .onClick(() => {
      this.onTap();
    })
  }
}
