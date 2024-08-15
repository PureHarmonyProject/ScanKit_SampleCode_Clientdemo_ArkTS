import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { audio } from '@kit.AudioKit';
import Logger from '../../../common/Logger';

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

  public static getInstance(context: common.UIAbilityContext): PromptTone {
    if (PromptTone.instance === null) {
      PromptTone.instance = new PromptTone(context);
    }
    return PromptTone.instance;
  }

  public async initPlayer(context: common.UIAbilityContext): Promise<void> {
    if (!this.avPlayer) {
      try {
        this.avPlayer = await media.createAVPlayer();
      } catch (error) {
        Logger.error(TAG, `Failed to create avPlayer. Code: ${error.code}`);
      }

      this.setAVPlayerCallback();
      let contextUsed = context as common.UIAbilityContext;
      try {
        let fileDescriptor: resourceManager.RawFileDescriptor = await contextUsed.resourceManager.getRawFd('di.ogg');
        this.avPlayer.fdSrc = fileDescriptor;
      } catch (error) {
        Logger.error(TAG, `Failed to invoke an API of getRawFd. Code: ${error.code}`);
      }
    }
  }

  public playDrip(): void {
    try {
      if (this.avPlayer) {
        this.avPlayer.play().catch((error) => {
          Logger.error(TAG, `Failed to play avPlayer. Code: ${error.code}`);
        });
      }
    } catch (error) {
      Logger.error(TAG, `Failed to play drip. Code: ${error.code}`);
    }
  }

  public prepareAVPlayer(): void {
    try {
      this.avPlayer.prepare().catch((error) => {
        Logger.error(TAG, `Failed to prepare avPlayer. Code: ${error.code}`);
      });
    } catch (error) {
      Logger.error(TAG, `Failed to prepare avPlayer. Code: ${error.code}`);
    }
  }

  public setAVPlayerCallback(): void {
    // State machine change callback function.
    try {
      this.avPlayer.on('stateChange', async (state, _) => {
        switch (state) {
          case 'idle': // The reporting of this state machine is triggered after the reset interface is successfully called.
            this.prepareAVPlayer();
            break;
          case 'initialized': // This state is reported when the avplayer sets the playback source.
            this.avPlayer.audioRendererInfo = this.audioRendererInfo;
            try {
              this.avPlayer.prepare()
                .then(() => {
                  // Set the volume to 50%.
                  this.avPlayer.setVolume(0.5);
                }, (error) => {
                  Logger.error(TAG, `Failed to prepare avPlayer. Code: ${error.code}`);
                });
            } catch (error) {
              Logger.error(TAG, `Failed to prepare avPlayer. Code: ${error.code}`);
            }
            break;
          case 'completed': // After the playback ends, the state machine reporting is triggered.
            break;
          case 'stopped': // After the stop interface is successfully invoked, the state machine is triggered to report the event.
            this.prepareAVPlayer();
            break;
          default:
            break;
        }
      });
    } catch (error) {
      Logger.error(TAG, `Failed to on avPlayer. Code: ${error.code}`);
    }

  }
}