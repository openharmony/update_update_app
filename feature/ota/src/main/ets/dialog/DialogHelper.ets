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

import update from '@ohos.update';
import { DeviceUtils } from '@ohos/common/src/main/ets/util/DeviceUtils';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { FormatUtils } from '@ohos/common/src/main/ets/util/FormatUtils';
import { UpdateState } from '@ohos/common/src/main/ets/const/update_const';
import { OtaUpdateManager } from '../manager/OtaUpdateManager';
import RouterUtils from '../util/RouterUtils';

  /**
   * 弹框操作接口
   *
   * @since 2022-06-05
   */
  export interface DialogOperator {
    /**
     * 取消
     */
    onCancel(): void;

    /**
     * 确认
     */
    onConfirm(): void;
  }

/**
 * 重试检测动作
 */
class RetryCheckAction implements DialogOperator {
  onConfirm(): void {
    RouterUtils.singletonHomePage();
  }
  onCancel(): void {
    RouterUtils.singletonHomePage();
  }
};

export const retryCheckAction: DialogOperator = new RetryCheckAction();

/**
 * 重试下载动作
 */
class RetryDownloadAction implements DialogOperator {
  onConfirm(): void {
    OtaUpdateManager.getInstance().setUpdateState(UpdateState.CHECK_SUCCESS);
  }
  onCancel(): void {
    OtaUpdateManager.getInstance().setUpdateState(UpdateState.CHECK_SUCCESS);
  }
};

const retryDownloadAction: DialogOperator = new RetryDownloadAction();

/**
 * 重试安装动作
 */
class RetryUpgradeAction implements DialogOperator {
  onConfirm(): void {
    OtaUpdateManager.getInstance().setUpdateState(UpdateState.DOWNLOAD_SUCCESS);
  }
  onCancel(): void {
    OtaUpdateManager.getInstance().setUpdateState(UpdateState.DOWNLOAD_SUCCESS);
  }
}

const retryUpgradeAction: DialogOperator = new RetryUpgradeAction();

/**
 * 弹框辅助者
 *
 * @since 2022-06-05
 */
export namespace DialogHelper {
  /**
   * 网络弹框
   *
   * @param operator 回调
   */
  export function displayNetworkDialog(): void {
    AlertDialog.show(
      {
        title: $r('app.string.software_update'),
        message: $r('app.string.network_request'),
        primaryButton: {
          value: FormatUtils.toUpperCase(globalThis.abilityContext, $r('app.string.cancel')),
          action: () => {
            logInfo('Callback when the first button is clicked');
            onCancel: () => {
            };
          },
          backgroundColor: $r('sys.float.ohos_id_corner_radius_button')
        },
        secondaryButton: {
          value: $r('app.string.ok'),
          action: () => {
            logInfo('Callback when the second button is clicked');
            onConfirm: () => {
              OtaUpdateManager.getInstance().download(update.NetType.CELLULAR);
            };
          },
          backgroundColor: $r('sys.float.ohos_id_corner_radius_button')
        },
        cancel: () => {
          logInfo('Closed callbacks');
        },
        alignment: DeviceUtils.getDialogLocation(),
        offset: ({
          dx: '0vp',
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
  export function displayUpgradeFailDialog(): void {
    defaultNoTitleDialog($r('app.string.update_fail'), retryCheckAction);
  }

  /**
   * 下载失败弹框
   *
   * @param operator 回调
   */
  export function displayDownloadFailDialog(): void {
    defaultNoTitleDialog($r('app.string.download_fail'), retryCheckAction);
  }

  /**
   * 无网弹框
   *
   * @param operator 回调
   */
  export function displayNoNetworkDialog(): void {
    defaultKnowDialog($r('app.string.net_error_title'), $r('app.string.net_error_content'));
  }

  /**
   * 电量不足弹框
   *
   * @param operator 回调
   */
  export function displayNotEnoughBatteryDialog(): void {
    defaultKnowDialog($r('app.string.battery_not_enough_title'), $r('app.string.battery_not_enough_content',
      FormatUtils.getNumberFormat(0.3)));
  }

/**
   * 下载空间不足弹框
   *
   * @param operator 回调
   */
  export function displayDownloadNotEnoughSpaceDialog(): void {
    defaultKnowDialog($r('app.string.space_not_enough_title'), $r('app.string.space_not_enough_content'),
      retryDownloadAction);
  }

  /**
   * 空间不足弹框
   *
   * @param operator 回调
   */
  export function displayUpgradeNotEnoughSpaceDialog(): void {
    defaultKnowDialog($r('app.string.space_not_enough_title'), $r('app.string.space_not_enough_content'),
      retryUpgradeAction);
  }

  /**
   * 文件校验失败弹框
   *
   * @param operator 回调
   */
  export function displayVerifyFailDialog(): void {
    defaultNoTitleDialog($r('app.string.package_verify_fail'), retryCheckAction);
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
  function showDialog(title: string | Resource | null, message: string | Resource, confirmText?: string | Resource,
    operator ?: DialogOperator): void {
    AlertDialog.show(
      {
        title: title,
        message: message,
        confirm: {
          value: confirmText,
          action: () => {
            logInfo('defaultKnowDialog button is clicked');
            if (operator && operator.onConfirm) {
              operator.onConfirm();
            }
          },
          backgroundColor: $r('sys.float.ohos_id_corner_radius_button')
        },
        cancel: () => {
          logInfo('Closed callbacks');
          if(operator && operator.onCancel) {
            operator?.onCancel();
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