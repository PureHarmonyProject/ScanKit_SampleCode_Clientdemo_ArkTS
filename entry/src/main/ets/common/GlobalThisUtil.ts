/**
 * Given the definition of globalThis within a ts file, we've implemented HarmonyOS's suggested interim solution by referencing globalThis in ts and employing ts within ets.
 * Due to the adjustment of ets syntax, globalThis may be removed. A thorough cleanup of globalThis needs to be considered in the future and alternative ways need to explored to pass global parameters.
 */
export class GlobalThisUtil {
  public static setProperty<T>(name: string, value: T): void {
    globalThis[name] = value;
  }

  public static getProperty<T>(name: string): T {
    return globalThis[name];
  }
}