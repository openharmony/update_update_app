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

import promptAction from '@ohos.promptAction';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';

/**
 * Toast工具
 *
 * @since 2023-01-10
 */
export namespace ToastUtils {
  /**
   * Toast调用
   *
   * @param message toast显示内容
   */
  export function showToast(message: string): void {
    LogUtils.info('ToastUtils', 'start showToast');
    promptAction.showToast({
      message: message,
      duration: 2000,
      bottom: getToastLocation(),
    });
  }

  /**
   * 取toast位置
   *
   * @return toast位置
   */
  function getToastLocation(): string {
    return '120vp';
  }
}

export default ToastUtils;
