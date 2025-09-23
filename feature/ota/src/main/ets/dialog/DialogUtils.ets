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
import type update from '@ohos.update';
import type { OtaStatus } from '@ohos/common/src/main/ets/const/update_const';
import { MAIN_ABILITY_NAME, PACKAGE_NAME, UpdateState } from '@ohos/common/src/main/ets/const/update_const';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { UpdateUtils } from '@ohos/common/src/main/ets/util/UpdateUtils';
import { foregroundCheck } from '@ohos/common/src/main/ets/util/CommonUtils';
import { OtaUpdateManager } from '../manager/OtaUpdateManager';
import RouterUtils from '../util/RouterUtils';
import { DialogHelper } from './DialogHelper';

/**
 * 弹框操作接口
 * @since 2025-06-09
 */
interface DialogOperator {
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
 * 弹框工具类
 *
 * @since 2022-12-05
 */
export class DialogUtils {
  /**
   * 下载空间不足弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showDownloadNotEnoughSpaceDialog(context: common.Context, otaStatus: OtaStatus,
    eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showDownloadNotEnoughSpaceDialog');
    DialogHelper.displayDownloadNotEnoughSpaceDialog();
  }

  /**
   * 下载断网弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showDownloadNoNetworkDialog(context: common.Context, otaStatus: OtaStatus,
    eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showDownloadNoNetworkDialog');
    DialogHelper.displayNoNetworkDialog();
  }

  /**
   * 校验失败弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showVerifyFailDialog(context: common.Context, otaStatus?: OtaStatus, eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showVerifyFailDialog');
    DialogHelper.displayVerifyFailDialog();
  }

  /**
   * 下载失败默认弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showDownloadFailDialog(context: common.Context, otaStatus?: OtaStatus, eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showDownloadFailDialog');
    DialogHelper.displayDownloadFailDialog();
  }

  /**
   * 安装空间不足弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showUpgradeNotEnoughSpaceDialog(context: common.Context, otaStatus: OtaStatus,
    eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showUpgradeNotEnoughSpaceDialog');
    DialogHelper.displayUpgradeNotEnoughSpaceDialog();
  }

  /**
   * 安装电量不足弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showUpgradeNotEnoughBatteryDialog(context: common.Context, otaStatus: OtaStatus,
    eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showUpgradeNotEnoughBatteryDialog');
    DialogHelper.displayNotEnoughBatteryDialog();
  }

  /**
   * 安装失败默认弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showUpgradeFailDialog(context: common.Context, otaStatus?: OtaStatus, eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showUpgradeFailDialog');
    DialogHelper.displayUpgradeFailDialog();
  }
}