@Extend(Text)
function labelText() {
  .fontSize(14).fontColor(0x000000)
  .textAlign(TextAlign.Start)
}

@Extend(Button)
function buttonScanStyle() {
  .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
  .fontColor($r('sys.color.ohos_id_color_text_primary_activated'))
  .align(Alignment.Center)
  .type(ButtonType.Capsule)
  .margin({ bottom: 12 })
}

@Component
export struct CustomButton {
  @Prop mText: string | Resource = '';
  private mHeight: number = 40;
  @StorageLink('windowWidthPx') windowWidth: number = 1;
  public mOnClick: () => void = () => {
  };

  build() {
    if (px2vp(this.windowWidth) <= 480) {
      Column() {
        Button(this.mText)
          .height(this.mHeight)
          .buttonScanStyle()
          .width('100%')
          .onClick(this.mOnClick);
      }.margin({ right: 16, left: 16 })
    } else {
      Column() {
        Button(this.mText)
          .height(this.mHeight)
          .buttonScanStyle()
          .width(448)
          .onClick(this.mOnClick);
      }
    }
  }
}

@Component
export struct CustomLabel {
  @Prop text: string | Resource = ''

  build() {
    Column() {
      Text(this.text).labelText().width(65)
    }.justifyContent(FlexAlign.Center).height(34)
  }
}

export class ScanConstant {
  static readonly HMS_CORE_BUNDLE_NAME = 'com.huawei.hms.hmscore'
  static readonly OHOS_PERMISSION_MANAGER = 'com.ohos.permissionmanager'
  static readonly OHOS_PERMISSION_MANAGER_ABILITY = 'com.ohos.permissionmanager.MainAbility'
  static readonly pdf_code: Record<string, string> = {
    'scanType': 'pdf', 'originalValue': 'acon'
  }
  static readonly qr_code: Record<string, string> = {
    'scanType': 'qrcode', 'originalValue': 'TEC-IT'
  }
  static readonly SCAN_TYPE: string[] =
    ['aztec', 'codebar', 'code39', 'code93', 'code128', 'dm', 'ean8', 'ean13', 'itf', 'pdf', 'qrcode', 'upca', 'upce',
      'harmony']
  static readonly code_items_value: Record<string, string> = {
    'aztec': 'whicheffec',
    'code39': 'N34-7M',
    'code93': 'N34007M',
    'code128': 'V83',
    'codebar': 'A34',
    'dm': 'We',
    'ean13': '123',
    'ean8': '4567',
    'harmony': 'xYENoolFgQgRxPW',
    'itf': '3071',
    'pdf': 'acon',
    'qrcode': 'TEC-IT',
    'upca': '3677',
    'upce': '0123'
  }
  static readonly type_items: string[] =
    ['aztec', 'code39', 'code93', 'code128', 'codebar', 'dm', 'ean13', 'ean8', 'harmony', 'itf', 'pdf', 'qrcode',
      'upca', 'upce']
  static readonly type_reflect: Record<string, string> = {
    'aztec': 'AZTEC_CODE',
    'code39': 'CODE39_CODE',
    'code93': 'CODE93_CODE',
    'code128': 'CODE128_CODE',
    'codebar': 'CODABAR_CODE',
    'dm': 'DATAMATRIX_CODE',
    'ean13': 'EAN13_CODE',
    'ean8': 'EAN8_CODE',
    'harmony': 'MULTIFUNCTIONAL_CODE',
    'itf': 'ITF14_CODE',
    'pdf': 'PDF417_CODE',
    'qrcode': 'QR_CODE',
    'upca': 'UPC_A_CODE',
    'upce': 'UPC_E_CODE'
  }
  static readonly od_items: string[] =
    ['code39', 'code93', 'code128', 'codebar', 'ean13', 'ean8', 'itf', 'upca', 'upce']
  static readonly td_items: string[] = ['aztec', 'dm', 'pdf', 'qrcode']
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
  static readonly SCAN_RESULT_TYPE_ALBUM_DETECT_LOGIC = "{ 'scanType': 8, 'originalValue': '6920459905036' }"
  static readonly PNG_IMG_ARR: string[] = ['duoma_1_6_12_7', 'type_3', 'type_5', 'type_14', 'album_logic']
}

