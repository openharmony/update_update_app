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

import type common from '@ohos.app.ability.common';
import { DeviceUtils } from '../util/DeviceUtils';
import { Logutils } from '../LogUtils';

/**
 * 格式化工具
 *
 * @since 2022-06-06
 */
export namespace FormatUtils {
  const DECIMAL_POINT = 2;

  /**
   * 格式化文件大小
   *
   * @param bytes 文件大小
   * @param decimalPoint 精确到小数点后两位
   * @return 格式化后的字符串
   */
  export function formatFileSize(bytes: number, decimalPoint = DECIMAL_POINT): string {
    if (bytes <= 0) {
      return '0 Bytes';
    }
    const MAX_BYTES: number = 1024 * 1024 * 1024;
    const DOWN_POINT: number = 0;
    const UP_POINT: number = 5;
    const ONE_KB = 1024;
    let data: number = Math.min(bytes, MAX_BYTES);
    let point: number = Math.min(Math.max(decimalPoint, DOWN_POINT), UP_POINT);
    let sizes = ['Bytes', 'KB', 'MB', 'GB'];
    let index = Math.floor(Math.log(data) / Math.log(ONE_KB));
    return parseFloat((bytes / Math.pow(ONE_KB, index)).toFixed(point)) + ' ' + sizes[index];
  }

  /**
   * 格式化字符串
   *
   * @param 待格式化的字符串
   * @param args 待匹配的内容
   * @return 格式化后的字符串
   */
  export function formatStr(message: string, ...args: (string | number)[]): string {
    if (!message) {
      return '';
    }
    const PLACE_HOLDER = new RegExp('%s|%d|%[0-9]\\$s');
    let segments = message.split(PLACE_HOLDER);
    let formattedStr: string = '';
    for (let i = 0; i < segments.length; i++) {
      formattedStr += segments[i];
      if (i !== segments.length - 1) {
        formattedStr += args[i] ? args[i] : '';
      }
    }
    return formattedStr;
  }

  /**
   * 字符串或字符串资源转大写
   *
   * @param context 上下文
   * @param text 待格式化的字符串
   * @param args 待匹配的内容
   * @return 转大写后的字符串
   */
  export function toUpperCase(context: common.Context, text: ResourceStr, ...args: (string | number)[]): string {
    if (!text) {
      return '';
    }
    if (typeof text === 'string') {
      return text.toUpperCase();
    } else {
      let message: string = context?.resourceManager.getStringSync(text.id);
      return formatStr(message, ...args).toUpperCase();
    }
  }

  /**
   * 数字格式化
   *
   * @param num 待格式化数字
   * @return 格式化之后的数字
   */
  export function getNumberFormat(num: number): string {
    let language: string = DeviceUtils.getSystemLanguage();
    let numfmt: Intl.NumberFormat = new Intl.NumberFormat(language, {style:'percent', notation:'standard'});
    return numfmt.format(num);
  }

  /**
   * JSON stringify方法封装
   *
   * @param value JS对象
   * @return json字符串
   */
  export function stringify<T>(value: T): string {
    if (value) {
      try {
        return JSON.stringify(value);
      } catch (exception) {
        Logutils.error('FormateUtils', 'JSON.stringify failed !!');
        return '';
      }
    }
    return '';
  }

  /**
   * json 字符串解析
   *
   * @param content json 字符串
   * @return T 解析后返回值
   */
  export function parseJson<T>(content: string): T | null {
    if (!content) {
      return null;
    }
    try {
      return JSON.parse(content) as T;
    } catch (exception) {
      Logutils.error('FormateUtils', 'paramJson failed !!');
    }
    return null;
  }
}