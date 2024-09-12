import { BreakpointConstants } from '../constants/BreakpointConstants';
import { CommonConstants } from '../constants/CommonConstants';
import { FontSizeScale } from '../model/FontSizeScale';

@Extend(Column)
function iconContainerMaskLayer() {
  .width(48)
  .height(48)
  .borderRadius(48)
  .clip(true)
}

@Extend(Column)
function notSmContainer() {
  .margin({
    left: 4,
    right: 4
  })
}

@Extend(Stack)
function smContainer() {
  .height('100%')
  .margin({
    left: 4,
    right: 4
  })
}

@Extend(Column)
function iconContainer() {
  .width(48)
  .height(48)
  .borderRadius(48)
  .clip(true)
  .alignItems(HorizontalAlign.Center)
  .justifyContent(FlexAlign.Center)
  .backgroundColor($r('sys.color.ohos_id_color_button_normal_transparent'))
}

@Extend(SymbolGlyph)
function icon() {
  .fontColor([$r('sys.color.font_on_primary')])
  .fontWeight(FontWeight.Regular)
  .fontSize('24vp')
}

@Extend(Text)
function iconText() {
  .fontColor($r('sys.color.font_on_primary'))
  .textAlign(TextAlign.Center)
  .fontFamily('HarmonyHeiTi')
  .lineHeight(16)
  .maxLines(2)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
}

@Component
export struct IconPressExcludeText {
  @Prop url: Resource;
  @Prop text: Resource;
  @Prop iconId: string;
  public imageClick: () => void = () => {
  }

  build() {
    Column() {
      Column() {
        SymbolGlyph(this.url)
          .icon()
          .id(this.iconId)
          .onClick(() => {
            this.imageClick();
          })
      }
      .iconContainer()
    }.stateStyles({
      pressed: {
        .iconContainerMaskLayer()
        .backgroundColor($r('sys.color.ohos_id_color_click_effect_transparent'))
      },
      normal: {
        .iconContainerMaskLayer()
        .backgroundColor('#00000000')
      }
    })
  }
}


@Component
export struct IconPress {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_LG;
  @StorageLink('scanFontSizeScale') fontSizeScale: number = 1;
  @Prop url: Resource;
  @Prop text: Resource;
  @Prop iconId: string;
  @Link isAlbumOffset: boolean;
  public imageClick: () => void = () => {
  }

  build() {
    if (this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM) {
      Stack({ alignContent: Alignment.Top }) {
        Text(this.text).iconText()
          .fontSize(FontSizeScale.getLimitFontSize(this.fontSizeScale,
            CommonConstants.SCAN_FONT_SIZE_SCALE_LIMIT_SYMBOL_TEXT, $r('sys.float.Body_S')))
          .offset({
            y: this.isAlbumOffset ? 48 : 64
          })
          .onAreaChange((_: Area, newArea: Area) => {
            let lineHeight = newArea['height'] as number;
            if (!this.isAlbumOffset && lineHeight > 16) {
              this.isAlbumOffset = true;
            }
          })

        IconPressExcludeText({
          url: this.url,
          text: this.text,
          iconId: this.iconId,
          imageClick: (() => {
            this.imageClick();
          })
        })
          .margin({
            top: 12,
            bottom: 12
          })
          .offset({
            y: this.isAlbumOffset ? -16 : 0
          })
      }
      .smContainer()
    } else {
      Column() {
        IconPressExcludeText({
          url: this.url,
          text: this.text,
          iconId: this.iconId,
          imageClick: (() => {
            this.imageClick()
          })
        })
          .margin({
            bottom: 4
          })
        Text(this.text).iconText()
          .fontSize(FontSizeScale.getLimitFontSize(this.fontSizeScale,
            CommonConstants.SCAN_FONT_SIZE_SCALE_LIMIT_SYMBOL_TEXT, $r('sys.float.Body_S')))
      }
      .notSmContainer()
    }
  }
}