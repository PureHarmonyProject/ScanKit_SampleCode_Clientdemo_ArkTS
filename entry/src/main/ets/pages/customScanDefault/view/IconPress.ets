import { BreakpointConstants } from '../constants/BreakpointConstants';

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
  .shadow({
    radius: 4,
    type: ShadowType.BLUR,
    color: 'rgba(0,0,0,0.30)',
    offsetX: 0,
    offsetY: 2
  })
}

@Extend(Image)
function icon() {
  .width(24)
  .height(24)
  .objectFit(ImageFit.Contain)
  .draggable(false)
  .responseRegion({ x: '-50%', y: '-50%', width: '200%', height: '200%' })
}

@Extend(Text)
function iconText() {
  .fontSize($r('sys.float.ohos_id_text_size_body3'))
  .fontColor($r('sys.color.ohos_id_color_primary_contrary'))
  .textAlign(TextAlign.Center)
  .fontFamily('HarmonyHeiTi')
  .lineHeight(16)
  .maxLines(2)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .textShadow({
    radius: 4,
    type: ShadowType.BLUR,
    color: 'rgba(0,0,0,0.30)',
    offsetX: 0,
    offsetY: 2
  })
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
        Image(this.url)
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
  @Prop url: Resource;
  @Prop text: Resource;
  @Prop iconId: string;
  @Link isAblumOffset: boolean;
  public imageClick: () => void = () => {
  }

  build() {
    if (this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM) {
      Stack({ alignContent: Alignment.Top }) {
        Text(this.text).iconText()
          .offset({
            y: this.isAblumOffset ? 48 : 64
          })
          .onAreaChange((_: Area, newArea: Area) => {
            let lineHeight = newArea['height'] as number;
            if (!this.isAblumOffset && lineHeight > 16) {
              this.isAblumOffset = true;
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
            y: this.isAblumOffset ? -16 : 0
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
      }
      .notSmContainer()
    }
  }
}