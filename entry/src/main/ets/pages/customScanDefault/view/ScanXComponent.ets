import { XComponentSize } from '../model/ScanSize';
import Logger from '../../../common/logger';

const TAG = 'ScanXComponent';

@Component
export struct ScanXComponent {
  @ObjectLink xComponentSize: XComponentSize;
  @Link surfaceId: string;
  private mXComponentController: XComponentController = new XComponentController();
  public initScan: () => void = () => {
  };

  build() {
    XComponent({
      id: 'componentId',
      type: 'surface',
      controller: this.mXComponentController
    })
      .onLoad(async () => {
        this.surfaceId = this.mXComponentController.getXComponentSurfaceId();
        Logger.info(TAG, `Succeeded in loading XComponent, getXComponentSurfaceId: ${this.surfaceId}`);
        this.initScan();
      })
      .height(this.xComponentSize.height)
      .width(this.xComponentSize.width)
      .position({ x: this.xComponentSize.offsetX, y: this.xComponentSize.offsetY })
      .clip(true)
  }
}