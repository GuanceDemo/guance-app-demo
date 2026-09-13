import {
  AppColors,
  BorderRadius,
  FontSizes,
  Heights,
  Spacing
} from '../constants/UIConstants';

@Component
export struct FormTextInput {
  label: string = '';
  placeholder: string = '';
  @Prop text: string = '';
  @Prop error: string = '';
  onValueChange: (value: string) => void = () => {};

  build() {
    Column() {
      Text(this.label)
        .fontSize(FontSizes.NORMAL)
        .fontColor(AppColors.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: Spacing.SM })

      TextInput({ placeholder: this.placeholder, text: this.text })
        .width('100%')
        .height(Heights.INPUT)
        .fontSize(FontSizes.NORMAL)
        .fontColor(AppColors.TEXT_PRIMARY)
        .placeholderColor(AppColors.TEXT_HINT)
        .backgroundColor(AppColors.INPUT_BG)
        .borderRadius(BorderRadius.SMALL)
        .onChange((value: string) => {
          this.onValueChange(value);
        })

      if (this.error.length > 0) {
        Text(this.error)
          .fontSize(FontSizes.SMALL)
          .fontColor(AppColors.ERROR)
          .width('100%')
          .margin({ top: Spacing.XS })
      }
    }
    .width('100%')
    .margin({ bottom: Spacing.MD })
  }
}
