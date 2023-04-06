/*
 * Copyright (c) 2023 Huawei Device Co., Ltd.
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

import Logger from '@ohos.hilog';

/**
 * 日志打印工具
 *
 * @since 2022-06-06
 */
export namespace LogUtils {
  const DOMAIN = 0x0A00;

  /**
   * 输出debug日志
   *
   * @param tag 标题
   * @param message 日志信息
   * @param args 附加信息
   */
  export function debug(tag: string, message: string, ...args: (string | number)[]): void {
    Logger.debug(DOMAIN, tag, filterSensitiveInfo(message), ...args);
  }

  /**
   * 输出info日志
   *
   * @param tag 标题
   * @param message 日志信息
   * @param args 附加信息
   */
  export function log(tag: string, message: string, ...args: (string | number)[]): void {
    Logger.info(DOMAIN, tag, filterSensitiveInfo(message), ...args);
  }

  /**
   * 输出info日志
   *
   * @param tag 标题
   * @param message 日志信息
   * @param args 附加信息
   */
  export function info(tag: string, message: string, ...args: (string | number)[]): void {
    Logger.info(DOMAIN, tag, filterSensitiveInfo(message), ...args);
  }

  /**
   * 输出warn日志
   *
   * @param tag 标题
   * @param message 日志信息
   * @param args 附加信息
   */
  export function warn(tag: string, message: string, ...args: (string | number)[]): void {
    Logger.warn(DOMAIN, tag, filterSensitiveInfo(message), ...args);
  }

  /**
   * 输出error日志
   *
   * @param tag 标题
   * @param message 日志信息
   * @param args 附加信息
   */
  export function error(tag: string, message: string, ...args: (string | number)[]): void {
    Logger.error(DOMAIN, tag, filterSensitiveInfo(message), ...args);
  }

  function filterSensitiveInfo(message: string): string {
    let result: string = message;
    if (result) {
      result = filterUrl(result, true);
      result = filterUrl(result, false);
    }
    return result;
  }

  function filterUrl(message: string, isHttps: boolean): string {
    let replaceStr: string = isHttps ? 'https://' : 'http://';
    let result: string = '';
    let tempResult: string = message;
    let startIndex: number = tempResult.indexOf(replaceStr);
    while (startIndex >= 0) {
      result += tempResult.substring(0, startIndex) + replaceStr + '****';
      tempResult = tempResult.substring(startIndex + replaceStr.length);
      let endIndex: number = tempResult.indexOf('/');
      tempResult = endIndex >= 0 ? tempResult.substring(endIndex) : '';
      startIndex = tempResult.indexOf(replaceStr);
    }
    result += tempResult;
    return result;
  }
}