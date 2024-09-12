import { ConfigurationConstant } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';
import { funcDelayer } from '../../../common/Utils';
import { CommonConstants } from '../constants/CommonConstants';
import { FontSizeScale } from '../model/FontSizeScale';

@Extend(Text)
function textClass(color: ResourceColor, textAlign: TextAlign) {
  .fontWeight(FontWeight.Regular)
  .fontColor(color)
  .fontFamily('HarmonyHeiTi')
  .textAlign(textAlign)
  .lineHeight(22)
  .opacity(0.9)
}

@Extend(Button)
function buttonClass() {
  .width('100%')
  .height(40)
}

@Extend(Column)
function componentContainer() {
  .width('100%')
  .height('100%')
  .padding({ left: 16, right: 16 })
  .backgroundColor($r('sys.color.ohos_id_color_mask_thin'))
  .justifyContent(FlexAlign.End)
  .position({
    x: 0, y: 0
  })
}

@Extend(Column)
function dialogBoxContainer(color: ResourceColor) {
  .padding({
    left: 16,
    top: 24,
    right: 16,
    bottom: 16
  })
  .backgroundColor(color)
  .borderRadius($r('sys.float.ohos_id_corner_radius_dialog'))
  .constraintSize({
    maxWidth: 400
  })
}

@Extend(Column)
function dialogContentContainer() {
  .margin({
    left: 8,
    right: 8,
    bottom: 8
  })
}

@Component
export struct PickerDialog {
  @StorageLink('scanFontSizeScale') fontSizeScale: number = 1;
  @StorageLink('scanColorMode') darkMode: ConfigurationConstant.ColorMode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  @Prop text: Resource;
  @Prop dialogScale: number = 0.85;
  @State dialogWidth: number = 368;
  public cancel: () => void = () => {
  };

  @Builder
  DialogText() {
      Text(this.text)
        .textClass(this.darkMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
        $r('sys.color.ohos_id_color_text_primary_dark') : $r('sys.color.ohos_id_color_text_primary'), TextAlign.Center)
        .fontSize(FontSizeScale.getLimitFontSize(this.fontSizeScale,
          CommonConstants.SCAN_FONT_SIZE_SCALE_LIMIT_DIALOG_TEXT, $r('sys.float.Body_L')))
  }

  @Builder
  DialogButton() {
    Button($r('app.string.Scan_diaLog_got_it'), { buttonStyle: ButtonStyleMode.TEXTUAL })
      .buttonClass()
      .width(this.dialogWidth - 32)
      .onClick(() => {
        animateTo({
          duration: 250,
          curve: Curve.Friction,
          delay: 0,
          iterations: 1,
          playMode: PlayMode.Alternate,
        }, () => {
          this.dialogScale = 0.85;
          funcDelayer(() => {
            this.cancel();
          }, 100);
        });
      })
  }

  appearAnimation() {
    animateTo({
      duration: 250,
      curve: curves.cubicBezierCurve(0.38, 1.33, 0.6, 1),
      delay: 0,
      iterations: 1,
      playMode: PlayMode.Alternate,
    }, () => {
      this.dialogScale = 1;
    });
  }

  build() {
    Column() {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Center
      }) {
        Column() {
          Column() {
            this.DialogText()
          }.dialogContentContainer()

          this.DialogButton()
        }
        .dialogBoxContainer(
          this.darkMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ?
          $r('sys.color.ohos_id_blur_style_component_ultra_thick_color_dark') :
          $r('sys.color.ohos_id_blur_style_component_ultra_thick_color')
        )
        .backgroundBlurStyle(BlurStyle.COMPONENT_THICK, {
          colorMode: this.darkMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? ThemeColorMode.DARK :
          ThemeColorMode.LIGHT,
          adaptiveColor: AdaptiveColor.DEFAULT,
        })
        .onAreaChange((_: Area, newArea: Area) => {
          this.dialogWidth = Number(newArea.width);
        })
        .scale({ x: this.dialogScale, y: this.dialogScale })
      }
    }
    .componentContainer()
    .onAppear(() => {
      this.appearAnimation();
    })
  }
}