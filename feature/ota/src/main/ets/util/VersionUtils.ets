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

import { DeviceUtils } from '@ohos/common/src/main/ets/util/DeviceUtils';

/**
 * 版本工具
 *
 * @since 2022-06-06
 */
export namespace VersionUtils {
  /**
   * 获取当前版本号
   *
   * @return 当前版本号
   */
  export function getCurrentDisplayVersion(): string {
    return DeviceUtils.getDisplayVersion();
  }

  /**
   * 获取主页的显示版本号
   *
   * @return 显示版本号
   */
  export function getDisplayVersionForIndex(): string {
    return DeviceUtils.getDisplayVersion();
  }
}

export default VersionUtils;