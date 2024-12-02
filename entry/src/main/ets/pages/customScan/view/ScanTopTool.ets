import { LengthMetrics, router } from '@kit.ArkUI';
import Logger from '../../../common/Logger';
import { BreakpointConstants } from '../constants/BreakpointConstants';
import { BreakpointType } from '../model/BreakpointType';
import { ScanService } from '../model/ScanService';

const TAG = 'ScanTopTool';

@Component
export struct ScanTopTool {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @State scanService: ScanService = ScanService.getInstance();
  @Prop navHeight: number;
  @Prop scanResultSize: number;
  public backToScan: () => void = () => {
  };

  build() {
    Button({
      type: ButtonType.Circle,
      stateEffect: true
    }) {
      SymbolGlyph($r('sys.symbol.xmark'))
        .fontWeight(FontWeight.Regular)
        .fontColor([$r('sys.color.font_on_primary')])
        .fontSize('24vp')
    }
    .width(40)
    .height(40)
    .backgroundColor('rgba(255,255,255,0.15)')
    .id('scan_page_goBack')
    .margin({
      top: LengthMetrics.vp(this.navHeight + 8),
      start: LengthMetrics.vp(new BreakpointType(16,
        24,
        32).getValue(this.currentBreakpoint))
    })
    .onClick(async () => {
      if (this.scanResultSize > 1) {
        Logger.info(TAG, 'Start to backToScan.');
        this.scanService.resetRetryScanTimes();
        this.backToScan();
      } else {
        router.back();
      }
    })
  }
}
