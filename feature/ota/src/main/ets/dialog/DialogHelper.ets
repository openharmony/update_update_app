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
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { FormatUtils } from '@ohos/common/src/main/ets/util/FormatUtils';

/**
 * 弹框辅助者
 *
 * @since 2022-06-05
 */
export namespace DialogHelper {
  /**
   * 弹框操作接口
   *
   * @since 2022-06-05
   */
  export interface DialogOperator {
    /**
     * 取消
     */
    onCancel?: () => void;

    /**
     * 确认
     */
    onConfirm?: () => void;
  }

  /**
   * 网络弹框
   *
   * @param operator 回调
   */
  export function displayNetworkDialog(operator: DialogOperator): void {
    AlertDialog.show(
      {
        title: $r('app.string.software_update'),
        message: $r('app.string.network_request'),
        primaryButton: {
          value: FormatUtils.toUpperCase(globalThis.abilityContext, $r('app.string.cancel')),
          action: () => {
            logInfo('Callback when the first button is clicked');
            operator.onCancel?.();
          },
          backgroundColor: $r('sys.float.ohos_id_corner_radius_button')
        },
        secondaryButton: {
          value: $r('app.string.ok'),
          action: () => {
            logInfo('Callback when the second button is clicked');
            operator.onConfirm?.();
          },
          backgroundColor: $r('sys.float.ohos_id_corner_radius_button')
        },
        cancel: () => {
          logInfo('Closed callbacks');
        },
        alignment: DeviceUtils.getDialogLocation(),
        offset: ({
          dx: "0vp",
          dy: DeviceUtils.getDialogOffsetY()
        }),
        autoCancel: false
      }
    )
  }

  /**
   * 升级失败弹框
   *
   * @param operator 回调
   */
  export function displayUpgradeFailDialog(operator ?: DialogOperator): void {
    defaultNoTitleDialog($r('app.string.update_fail'), operator);
  }

  /**
   * 下载失败弹框
   *
   * @param operator 回调
   */
  export function displayDownloadFailDialog(operator ?: DialogOperator): void {
    defaultNoTitleDialog($r('app.string.download_fail'), operator);
  }

  /**
   * 无网弹框
   *
   * @param operator 回调
   */
  export function displayNoNetworkDialog(operator ?: DialogOperator): void {
    defaultKnowDialog($r('app.string.net_error_title'), $r('app.string.net_error_content'), operator);
  }

  /**
   * 电量不足弹框
   *
   * @param operator 回调
   */
  export function displayNotEnoughBatteryDialog(operator ?: DialogOperator): void {
    defaultKnowDialog($r('app.string.battery_not_enough_title'), $r('app.string.battery_not_enough_content',
      FormatUtils.getNumberFormat(0.3)), operator);
  }

  /**
   * 空间不足弹框
   *
   * @param operator 回调
   */
  export function displayNotEnoughSpaceDialog(operator ?: DialogOperator): void {
    defaultKnowDialog($r('app.string.space_not_enough_title'), $r('app.string.space_not_enough_content'), operator);
  }

  /**
   * 文件校验失败弹框
   *
   * @param operator 回调
   */
  export function displayVerifyFailDialog(operator ?: DialogOperator): void {
    defaultNoTitleDialog($r('app.string.package_verify_fail'), operator);
  }

  /**
   * 默认提示弹框
   *
   * @param title 标题
   * @param message 内容
   * @param operator 回调
   */
  function defaultKnowDialog(title: string | Resource, message: string | Resource, operator ?: DialogOperator): void {
    showDialog(title, message, $r('app.string.button_know'), operator);
  }

  /**
   * 默认无标题弹框
   *
   * @param message 内容
   * @param operator 回调
   */
  function defaultNoTitleDialog(message: string | Resource, operator ?: DialogOperator): void {
    showDialog(null, message, $r('app.string.button_know'), operator);
  }

  /**
   * 弹框
   *
   * @param title 标题
   * @param message 内容
   * @param confirmText 确认按钮显示内容
   * @param operator 回调
   */
  function showDialog(title: string | Resource, message: string | Resource, confirmText?: string | Resource,
    operator ?: DialogOperator): void {
    AlertDialog.show(
      {
        title: title,
        message: message,
        confirm: {
          value: confirmText,
          action: () => {
            logInfo('defaultKnowDialog button is clicked');
            if (operator) {
              operator.onConfirm();
            }
          },
          backgroundColor: $r('sys.float.ohos_id_corner_radius_button')
        },
        cancel: () => {
          logInfo('Closed callbacks');
          if(operator) {
            operator.onCancel();
          }
        },
        alignment: DeviceUtils.getDialogLocation(),
        offset: ({
          dx: '0vp',
          dy: DeviceUtils.getDialogOffsetY()
        }),
        autoCancel: false,
      }
    )
  }

  /**
   * info级别日志打印
   *
   * @param message 日志内容
   */
   function logInfo(message: string): void {
     LogUtils.info('DialogHelper', message);
  }
}