/**
 * 由于globalThis在ts文件，因此采用鸿蒙推荐的暂时规避手段，在ts中引用globalThis，ets中应用ts
 * 随着ets语法调整，globalThis可能被删除。后续可以考虑对globalThis进行彻底清理，通过其他方式传递全局参数
 */
export class GlobalThisUtil {
  public static setProperty<T>(name: string, value: T): void {
    globalThis[name] = value;
  }

  public static getProperty<T>(name: string): T {
    return globalThis[name];
  }
}