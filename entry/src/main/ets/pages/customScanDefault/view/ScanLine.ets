import { AnimatorResult, curves, Animator } from '@kit.ArkUI';
import Logger from '../../../common/logger';
import { BreakpointConstants } from '../constants/BreakpointConstants';

const TAG = 'ScanLine';

@Extend(Image)
function imageAnimation(speed: number, linePosition: number, allAngle: number) {
  .position({ x: 0, y: -0.5 })
  .width('100%')
  .height(130)
  .scale({ y: Math.max(speed, 0.007) }) // 0.5 * scanline_height/scan_shadow_height = 0.007
  .position({
    x: 0,
    y: linePosition + '%'
  })
  .rotate({
    x: 1,
    angle: allAngle,
    centerX: 0,
    centerY: 0
  })
}

@Component
export struct ScanLine {
  @StorageLink('currentBreakpoint') currentBreakpoint: string = BreakpointConstants.BREAKPOINT_SM;
  @State isScanned: boolean = false; // Scanned
  @State linePosition: number = 0;
  @State allAngle: number = 180;
  @State lightFactor: number = 0.075;
  @State factor: number = 0.025;
  @State reverse: boolean = false;
  @State speed: number = 0.0;
  @State mNowMaxLight: number = 0.0;
  @State matrix: number[] =
    [1.0, this.lightFactor, this.lightFactor, this.lightFactor, 0.0, this.lightFactor, this.lightFactor + 1.0,
      this.lightFactor, this.lightFactor, 0.0, this.lightFactor, this.lightFactor, this.lightFactor + 1.0,
      this.lightFactor, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0];
  @State isOpenAlbum: boolean = false;
  @State isScanMotion: boolean = true; // Whether to display the scanning effect
  private particlePropertyAnimationDown: ParticlePropertyAnimation<number> = {
    from: 0,
    to: 0.5,
    startMillis: 0,
    endMillis: 100,
    curve: Curve.Smooth
  }
  private particlePropertyAnimationUp: ParticlePropertyAnimation<number> = {
    from: 0.5,
    to: 0,
    startMillis: 400,
    endMillis: 500,
    curve: Curve.Smooth
  }
  private emitterOptions: EmitterOptions<ParticleType.POINT> = {
    particle: {
      type: ParticleType.POINT,
      config: {
        radius: 2
      },
      count: -1,
      lifetime: 2000
    },
    size: ['100%', '100%'],
    emitRate: 80,
    shape: ParticleEmitterShape.RECTANGLE
  }
  private backAnimator: AnimatorResult = Animator.create({
    duration: 2000,
    easing: "smooth",
    delay: 0,
    fill: "none",
    direction: "alternate",
    iterations: -1,
    begin: 0,
    end: 100
  }); // Scan line dynamic effect

  async backAnimatorCreate(): Promise<void> {

    this.backAnimator.onRepeat = () => {
      this.reverse = !this.reverse;
      if (this.reverse) {
        this.allAngle = 0;
      } else {
        this.allAngle = 180;
      }
    }
    this.backAnimator.onCancel = () => {
      this.isScanMotion = false;
    }
    this.backAnimator.onFrame = (value) => {

      if (!this.isScanMotion) {
        this.isScanMotion = true;
      }
      this.isOpenAlbum = false;
      value = value / 100;

      if (value < 0.389) {
        this.speed = curves.cubicBezierCurve(0.4, 0.0, 0.7, 1.0).interpolate(value / 0.389);
      } else {
        this.speed = 1.0 - curves.cubicBezierCurve(0.25, 0.0, 0.4, 1.0).interpolate((value - 0.389) / 0.611);
      }
      this.linePosition = 100 * value;
    }

  }

  async aboutToAppear() {
    try {
      await this.backAnimatorCreate();
      if (this.backAnimator) {
        this.backAnimator.play();
      }
    } catch (error) {
      Logger.error(TAG, `Failed to play backAnimator. Code: ${error.code}, message: ${error.message}`);
    }
  }

  aboutToDisappear() {
    if (this.backAnimator) {
      this.backAnimator.cancel();
    }
  }

  build() {
    Stack() {
      Image($rawfile('scan_light.png')).width('100%').height(2)
        .position({
          x: 0,
          y: this.linePosition + '%'
        })
      Image($rawfile('scan_shadow.png'))
        .imageAnimation(this.speed, this.linePosition, this.allAngle)

      Particle({
        particles: [
          {
            emitter: this.emitterOptions,
            scale: { range: [1, 1.2] },
            color: {
              range: ['#0A8BF5', '#FFFFFF']
            },
            opacity: {
              range: [0, 0.6],
              updater: {
                type: ParticleUpdater.CURVE,
                config: [
                  this.particlePropertyAnimationDown,
                  this.particlePropertyAnimationUp
                ]
              }
            }
          }
        ]
      }).width('80%')
        .height('100%')
        .markAnchor({ y: this.allAngle == 180 ? (60 * this.speed) : 0 })
        .mask(new Rect({ width: '100%', height: 60 * (this.speed) })
          .position({ y: this.linePosition + '%' })
          .fill(Color.White))
    }
    .width(this.currentBreakpoint === BreakpointConstants.BREAKPOINT_SM ? '100%' : '50%')
    .height('100%')
    .opacity(this.isScanned || this.isOpenAlbum ? 0 : 1)
  }
}