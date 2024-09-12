/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import hilog from '@ohos.hilog'

class Logger {
  private domain: number = 0x00001;
  private prefix: string = 'Scan SampleCode';

  debug(...args: string[]): void {
    let format: string = "%{public}s ".repeat(args.length);
    hilog.debug(this.domain, this.prefix, format, args);
  }

  info(...args: string[]): void {
    let format: string = "%{public}s ".repeat(args.length);
    hilog.info(this.domain, this.prefix, format, args);
  }

  warn(...args: string[]): void {
    let format: string = "%{public}s ".repeat(args.length);
    hilog.warn(this.domain, this.prefix, format, args);
  }

  error(...args: string[]): void {
    let format: string = "%{public}s ".repeat(args.length);
    hilog.error(this.domain, this.prefix, format, args);
  }
}

export default new Logger();