import common from '@ohos.app.ability.common';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import { BreakpointConstants } from '../constants/BreakpointConstants';
import { curves } from '@kit.ArkUI';

@Extend(Text)
function titleClass(color: ResourceColor) {
  .fontWeight(FontWeight.Bold)
  .fontSize($r('sys.float.ohos_id_text_size_headline8'))
  .fontColor(color)
  .fontFamily('HarmonyHeiTi')
  .textAlign(TextAlign.Center)
  .maxLines(2)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .lineHeight(26)
  .margin({
    top: 15,
    bottom: 15
  })
}

@Extend(Image)
function iconContainer() {
  .width(48)
  .height(48)
}

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
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @State context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  @Prop darkMode: ConfigurationConstant.ColorMode;
  @Prop text: Resource;
  @Prop isPreference: boolean = false;
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
            if (this.isPreference) {
              Image(this.darkMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ? $rawfile('preference_light@3x.png') : $rawfile('preference_dark@3x.png'))
                .iconContainer()
              Text($r('app.string.Scan_preference_title'))
                .titleClass(this.darkMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ? $r('sys.color.ohos_id_color_text_primary') : $r('sys.color.ohos_id_color_text_primary_dark'))
            }
            Text(this.text)
              .textClass(this.darkMode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT ? $r('sys.color.ohos_id_color_text_primary') : $r('sys.color.ohos_id_color_text_primary_dark'), this.isPreference ? TextAlign.Start : TextAlign.Center)
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