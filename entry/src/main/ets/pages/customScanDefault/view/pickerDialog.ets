import { common, ConfigurationConstant } from '@kit.AbilityKit';
import { curves } from '@kit.ArkUI';

@Extend(Text)
function textClass(color: ResourceColor, textAlign: TextAlign) {
  .fontWeight(FontWeight.Regular)
  .fontSize($r('sys.float.ohos_id_text_size_body1'))
  .fontColor(color)
  .fontFamily('HarmonyHeiTi')
  .textAlign(textAlign)
  .maxLines(3)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .lineHeight(22)
  .opacity(0.9)
}

@Extend(Button)
function buttonClass() {
  .fontWeight(FontWeight.Medium)
  .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
  .fontSize($r('sys.float.ohos_id_text_size_button1'))
  .width('100%')
  .height(40)
  .backgroundColor('#00000000')
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
function dialogBoxContainer() {
  .padding({
    left: 16,
    top: 24,
    right: 16,
    bottom: 16
  })
  .backgroundColor($r('sys.color.ohos_id_blur_style_component_ultra_thick_color'))
  .backgroundBlurStyle(BlurStyle.Regular)
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
export struct pickerDialog {
  @State context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @Prop darkMode: ConfigurationConstant.ColorMode;
  @Prop text: Resource;
  @State dialogWidth: number = 368;
  @Prop dialogScale: number = 0.85;
  cancel: () => void = () => {

  };

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
            Text(this.text)
              .textClass(this.darkMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ? $r('sys.color.ohos_id_color_text_primary') : $r('sys.color.ohos_id_color_text_primary_dark'), TextAlign.Center)
          }.dialogContentContainer()
          Button($r('app.string.Scan_diaLog_got_it'))
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
                setTimeout(() => {
                  this.cancel();
                }, 100)
              });
            })
        }
        .dialogBoxContainer()
        .onAreaChange((_: Area, newArea: Area) => {
          this.dialogWidth = Number(newArea.width);
        })
        .scale({ x: this.dialogScale, y: this.dialogScale })
      }
    }
    .componentContainer()
    .onAppear(() => {
      this.appearAnimation()
    })
  }
}