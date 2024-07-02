import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { audio } from '@kit.AudioKit';
import Logger from '../../../common/logger';

const TAG = 'PromptTone';

export class PromptTone {
  avPlayer: media.AVPlayer;
  private static instance: PromptTone | null = null;
  private audioRendererInfo: audio.AudioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_NOTIFICATION,
    rendererFlags: 0
  };

  constructor(context: common.UIAbilityContext) {
    this.initPlayer(context);
  }

  static getInstance(context: common.UIAbilityContext): PromptTone {
    if (PromptTone.instance === null) {
      PromptTone.instance = new PromptTone(context);
    }
    return PromptTone.instance;
  }

  async initPlayer(context: common.UIAbilityContext): Promise<void> {
    if (!this.avPlayer) {
      this.avPlayer = await media.createAVPlayer();
      this.setAVPlayerCallback();
      let contextUsed = context as common.UIAbilityContext;
      let fileDescriptor: resourceManager.RawFileDescriptor = await contextUsed.resourceManager.getRawFd('di.ogg');
      this.avPlayer.fdSrc = fileDescriptor;
    }
  }

  playDrip(): void {
    try {
      if (this.avPlayer) {
        this.avPlayer.play();
      }
    } catch (error) {
      Logger.error(TAG, `Failed to playDrip. Code: ${error.code}, message: ${error.message}`);
    }
  }

  setAVPlayerCallback(): void {
    // State machine change callback function.
    this.avPlayer.on('stateChange', async (state, _) => {
      switch (state) {
        case 'idle': // The reporting of this state machine is triggered after the reset interface is successfully called.
          this.avPlayer.prepare();
          break;
        case 'initialized': // This state is reported when the avplayer sets the playback source.
          this.avPlayer.audioRendererInfo = this.audioRendererInfo;
          this.avPlayer.prepare().then(() => {
            // 设置音量为 50%
            this.avPlayer.setVolume(0.5);
          }, (error: BusinessError) => {
            Logger.error(TAG, `Failed to prepare avPlayer. Code: ${error.code}, message: ${error.message}`);
          });
          break;
        case 'completed': // After the playback ends, the state machine reporting is triggered.
          break;
        case 'stopped': // After the stop interface is successfully invoked, the state machine is triggered to report the event.
          this.avPlayer.prepare();
          break;
        default:
          break;
      }
    })
  }
}