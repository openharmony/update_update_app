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

import deviceInfo from '@ohos.deviceInfo';
import i18n from '@ohos.i18n';

/**
 * 设备信息工具
 *
 * @since 2022-06-06
 */
export namespace DeviceUtils {
 /**
  * 获取设备类型
  *
  * @return 设备类型
  */
  export function getDeviceType(): string {
    return deviceInfo.deviceType;
  }

  /**
   * 获取显示版本号
   *
   * @return 显示版本号
   */
  export function getDisplayVersion(): string {
    return deviceInfo.displayVersion;
  }

  /**
   * 获取系统语言
   *
   * @return 系统语言
   */
  export function getSystemLanguage(): string {
    let language = i18n.getSystemLanguage();
    if (language == 'zh-Hans') {
      language = 'zh-cn';
    } else {
      language = 'en-us';
    }
    return language;
  }

  /**
   * 取dialog位置
   *
   * @return dialog位置
   */
  export function getDialogLocation(): DialogAlignment{
      return DialogAlignment.Bottom;
  }

  /**
   * 取dialog偏移
   *
   * @return dialog偏移
   */
  export function getDialogOffsetY(): string | Resource {
    return $r('app.float.dialog_location_offset_y');
  }
}