import { image } from '@kit.ImageKit';
import { buffer } from '@kit.ArkTS';
import { BusinessError } from '@kit.BasicServicesKit';
import { scanCore, generateBarcode } from '@kit.ScanKit';
import { StatusBar } from '../../common/StatusBar';
import { CustomLabel, CustomButton } from '../../common/CommonComponents';
import { showError, getColorType, getTypeNum, getLevelType, showMessage } from '../../common/Utils';
import Logger from '../../common/Logger';

const TAG: string = 'CreateBarcode';

class ScanConstant {
  static readonly colorItems: Array<SelectOption> = [{
    value: 'Black', icon: ''
  },
    {
      value: 'Blue', icon: ''
    },
    {
      value: 'Brown', icon: ''
    },
    {
      value: 'Gray', icon: ''
    },
    {
      value: 'Green', icon: ''
    },
    {
      value: 'Orange', icon: ''
    },
    {
      value: 'Red', icon: ''
    },
    {
      value: 'White', icon: ''
    },
    {
      value: 'Yellow', icon: ''
    }];
  static readonly errorLevelItems: Array<SelectOption> = [{
    value: 'LEVEL_L', icon: ''
  },
    {
      value: 'LEVEL_M', icon: ''
    },
    {
      value: 'LEVEL_Q', icon: ''
    },
    {
      value: 'LEVEL_H', icon: ''
    }];
  static readonly codeTypeItems: Array<SelectOption> = [{
    value: 'AZTEC_CODE', icon: ''
  },
    {
      value: 'CODABAR_CODE', icon: ''
    },
    {
      value: 'CODE93_CODE', icon: ''
    },
    {
      value: 'CODE39_CODE', icon: ''
    },
    {
      value: 'CODE128_CODE', icon: ''
    },
    {
      value: 'DATAMATRIX_CODE', icon: ''
    },
    {
      value: 'EAN8_CODE', icon: ''
    },
    {
      value: 'EAN13_CODE', icon: ''
    }, {
      value: 'ITF14_CODE', icon: ''
    },
    {
      value: 'PDF417_CODE', icon: ''
    },
    {
      value: 'QR_CODE', icon: ''
    },
    {
      value: 'UPC_A_CODE', icon: ''
    },
    {
      value: 'UPC_E_CODE', icon: ''
    }];
}

@Extend(TextInput)
function demoTextInput() {
  .caretColor(Color.Blue)
  .fontSize(14)
  .width(120)
  .height(35)
  .fontWeight(FontWeight.Bold)
  .layoutWeight(1)
}

@Extend(TextArea)
function demoTextArea() {
  .height(34)
  .caretColor(Color.Black)
  .fontSize(14)
  .fontWeight(FontWeight.Bold)
  .fontFamily('sans-serif')
  .fontStyle(FontStyle.Normal)
  .fontColor(Color.Black)
}

@Extend(Select)
function demoSelect() {
  .font({ size: 14 })
  .selectedOptionFont({ size: 14 })
  .optionFont({ size: 14 })
  .height(34)
  .backgroundColor('#eeeeee')
}

@Extend(Row)
function demoRow() {
  .margin({ bottom: 10 })
}

@Extend(Flex)
function FlexRow() {
  .margin({ bottom: 10 })
}

@Entry
@Component
struct GenerateBarcode {
  @State pixelMap: image.PixelMap | undefined = undefined;
  @State mInputContext: string = '123';
  @State mWidth: string = '800';
  @State mHeight: string = '800';
  @State mCodeType: number = scanCore.ScanType.QR_CODE;
  @State mMargin: number = 1;
  @State mBackgroundColor: number = 0xffffff;
  @State mPixelMapColor: number = 0x000000;
  @StorageLink('windowWidthPx') windowWidth: number = 1;
  @State mLevel: generateBarcode.ErrorCorrectionLevel = generateBarcode.ErrorCorrectionLevel.LEVEL_H;

  build() {
    Column() {
      RelativeContainer() {
        StatusBar({ title: $r('app.string.generate_QR_code') })
      }
      .height(60)

      Flex({
        direction: FlexDirection.Row,
        wrap: FlexWrap.Wrap,
        alignItems: ItemAlign.Center,
        justifyContent: FlexAlign.Center
      }) {
        Flex({
          direction: FlexDirection.Row,
          wrap: FlexWrap.Wrap,
          alignItems: ItemAlign.Center,
          justifyContent: FlexAlign.Center
        }) {
          Flex({
            wrap: FlexWrap.NoWrap,
          }) {
            CustomLabel({
              text: $r('app.string.barcode_content')
            })
              .margin({ left: 5 })

            TextArea({ placeholder: this.mInputContext })
              .demoTextArea()
              .onChange((value: string) => {
                this.mInputContext = value
              })
          }.FlexRow()

          Flex({
            wrap: FlexWrap.NoWrap,
            justifyContent: FlexAlign.SpaceBetween
          }) {
            Flex({
              wrap: FlexWrap.NoWrap,
            }) {
              CustomLabel({
                text: $r('app.string.barcode_width')
              })

              TextInput({ placeholder: '800' }).demoTextInput()
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.mWidth = value
                }).width('100%')
            }.width('48%')

            Flex({
              wrap: FlexWrap.NoWrap,
            }) {
              CustomLabel({
                text: $r('app.string.barcode_height')
              })
              TextInput({ placeholder: '800' }).demoTextInput()
                .type(InputType.Number)
                .onChange((value: string) => {
                  this.mHeight = value
                }).width('100%')
            }.width('50%')
          }.FlexRow()


          Row() {
            CustomLabel({
              text: $r('app.string.barcode_type')
            })
            Select(ScanConstant.codeTypeItems)
              .value('QR_CODE')
              .selected(10)
              .demoSelect()
              .onSelect((_: number, value?: string) => {
                this.mCodeType = getTypeNum(value)
              })
              .width(px2vp(this.windowWidth) <= 480 ? '60%' : '80%')

          }.width('50%').demoRow()

          Row() {
            CustomLabel({
              text: $r('app.string.barcode_margin')
            })
            TextInput({ placeholder: '1' }).demoTextInput()
              .type(InputType.Number)
              .onChange((value: string) => {
                this.mMargin = Number.parseInt(value)
              }).width(px2vp(this.windowWidth) <= 480 ? '60%' : '80%')
          }.width('50%').demoRow()

          Row() {
            CustomLabel({
              text: $r('app.string.barcode_color')
            })
            Select(ScanConstant.colorItems)
              .selected(0)
              .value('Black')
              .demoSelect()
              .onSelect((_: number, value?: string) => {
                this.mPixelMapColor = getColorType(value)
              })
              .width(px2vp(this.windowWidth) <= 480 ? '60%' : '80%')

          }.width('50%').demoRow()

          Row() {
            CustomLabel({
              text: $r('app.string.barcode_background_color')
            })
            Select(ScanConstant.colorItems)
              .selected(7)
              .value('White')
              .demoSelect()
              .onSelect((_: number, value?: string) => {
                this.mBackgroundColor = getColorType(value)
              })
              .align(Alignment.Center)
              .width(px2vp(this.windowWidth) <= 480 ? '60%' : '80%')
          }.width('50%').demoRow()

          Row() {
            CustomLabel({
              text: $r('app.string.barcode_error_level')
            })
            Select(ScanConstant.errorLevelItems)
              .align(Alignment.Center)
              .width(px2vp(this.windowWidth) <= 480 ? '60%' : '80%')
              .selected(3)
              .value('LEVEL_H')
              .demoSelect()
              .onSelect((_: number, value?: string) => {
                this.mLevel = getLevelType(value)
              })

          }.width('50%').demoRow()

          Row() {
          }.width('50%').demoRow()
        }.padding(16)

        Column() {
          CustomButton({
            mText: $r('app.string.generate_barcode'), mOnClick: () => {
              this.pixelMap = undefined;
              let content = this.mInputContext;
              let options: generateBarcode.CreateOptions = {
                scanType: this.mCodeType,
                height: Number(this.mHeight),
                width: Number(this.mWidth),
                margin: Number(this.mMargin),
                level: this.mLevel,
                backgroundColor: this.mBackgroundColor,
                pixelMapColor: this.mPixelMapColor,
              }

              try {
                generateBarcode.createBarcode(content, options).then((result: image.PixelMap) => {
                  this.pixelMap = result;
                  Logger.info(TAG, 'Succeeded in creating barCode.');
                }).catch((error: BusinessError) => {
                  showError(error);
                  Logger.error(TAG, `Failed to create barCode. Code: ${error.code}, message: ${error.message}`);
                })
              } catch (error) {
                showError(error);
                Logger.error(TAG, `Failed to create barCode. Code: ${error.code}, message: ${error.message}`);
              }
            }
          })

          CustomButton({
            mText: $r('app.string.generate_trip_barcode'), mOnClick: () => {
              this.pixelMap = undefined;
              let content = this.mInputContext;
              let pattern = /^[0-9a-fA-F]+$/;
              if (content && !pattern.test(content)) {
                showMessage($r('app.string.trip_barcode_tip'));
                return;
              }
              if (content.length % 2 !== 0) {
                content = '0' + content;
              }
              let contentBuffer: ArrayBuffer = buffer.from(content, 'hex').buffer;
              let options: generateBarcode.CreateOptions = {
                scanType: this.mCodeType,
                height: Number(this.mHeight),
                width: Number(this.mWidth),
                margin: Number(this.mMargin),
                level: this.mLevel,
                backgroundColor: this.mBackgroundColor,
                pixelMapColor: this.mPixelMapColor,
              }

              try {
                generateBarcode.createBarcode(contentBuffer, options).then((result: image.PixelMap) => {
                  this.pixelMap = result;
                  Logger.info(TAG, 'Succeeded in creating barCode.');
                }).catch((error: BusinessError) => {
                  showError(error);
                  Logger.error(TAG, `Failed to create barCode. Code: ${error.code}, message: ${error.message}`);
                })
              } catch (error) {
                showError(error);
                Logger.error(TAG, `Failed to create barCode. Code: ${error.code}, message: ${error.message}`);
              }
            }
          })

          Column() {
            if (this.pixelMap) {
              Image(this.pixelMap).width(300).height(300).objectFit(ImageFit.Contain)
            }
          }.width(300).height(300).margin(10)
        }
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
}




