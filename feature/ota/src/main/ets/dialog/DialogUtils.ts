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
import update from '@ohos.update';
import type { OtaStatus } from '@ohos/common/src/main/ets/const/update_const';
import { MAIN_ABILITY_NAME, PACKAGE_NAME, UpdateState } from '@ohos/common/src/main/ets/const/update_const';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { UpdateUtils } from '@ohos/common/src/main/ets/util/UpdateUtils';
import { OtaUpdateManager } from '../manager/OtaUpdateManager';
import RouterUtils from '../util/RouterUtils';
import { DialogHelper } from './DialogHelper';

const TIME_OUT_FOR_START_ABILITY = 500;

/**
 * 装饰器--弹框时，前台判断处理
 */
function foregroundCheck<T>() {
  return function inner(target: unknown, propertyKey: string, descriptor: PropertyDescriptor): void {
    const original = descriptor.value;
    descriptor.value = function (context: common.Context, otaStatus: OtaStatus,
      eventId?: update.EventId, ...args): void {
      if (globalThis.AbilityStatus !== 'ON_FOREGROUND') {
        globalThis.reNotify = true;
        globalThis.otaStatusFromService = otaStatus;
        globalThis.eventIdFromService = eventId;
        LogUtils.log('foregroundCheck', 'do startMainAbilityIndex.');

        // 应用在后台时，无法弹框，需杀掉ability后，重新拉起界面弹框
        globalThis.abilityContext?.terminateSelf();
        setTimeout(() => {
          startMainAbilityIndex(context);
        }, TIME_OUT_FOR_START_ABILITY);
        return;
      }
      original.call(this, ...args);
    };
  };
}

function startMainAbilityIndex(context: common.Context): void {
  let want = {
    bundleName: PACKAGE_NAME,
    abilityName: MAIN_ABILITY_NAME,
    uri: 'pages/newVersion',
  };
  UpdateUtils.startAbility(context, want, null);
}

/**
 * 重试下载动作
 */
const retryDownloadAction = {
  onConfirm: (): void => {
    OtaUpdateManager.getInstance().setUpdateState(UpdateState.CHECK_SUCCESS);
  },
  onCancel: (): void => {
    OtaUpdateManager.getInstance().setUpdateState(UpdateState.CHECK_SUCCESS);
  },
};

/**
 * 重试安装动作
 */
const retryUpgradeAction = {
  onConfirm: (): void => {
    OtaUpdateManager.getInstance().setUpdateState(UpdateState.DOWNLOAD_SUCCESS);
  },
  onCancel: (): void => {
    OtaUpdateManager.getInstance().setUpdateState(UpdateState.DOWNLOAD_SUCCESS);
  },
};

/**
 * 重试检测动作
 */
const retryCheckAction = {
  onConfirm: (): void => {
    RouterUtils.singletonHomePage();
  }, onCancel: (): void => {
    RouterUtils.singletonHomePage();
  },
};

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
    DialogHelper.displayNotEnoughSpaceDialog(retryDownloadAction);
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
  static showVerifyFailDialog(context: common.Context, otaStatus: OtaStatus, eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showVerifyFailDialog');
    DialogHelper.displayVerifyFailDialog(retryCheckAction);
  }

  /**
   * 下载失败默认弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showDownloadFailDialog(context: common.Context, otaStatus: OtaStatus, eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showDownloadFailDialog');
    DialogHelper.displayDownloadFailDialog(retryCheckAction);
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
    DialogHelper.displayNotEnoughSpaceDialog(retryUpgradeAction);
  }

  /**
   * 鉴权连接服务器失败弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showAuthServerConnectFailDialog(context: common.Context, otaStatus: OtaStatus,
    eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showAuthServerConnectFailDialog');
    DialogHelper.displayServerConnectFailDialog();
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
   * 鉴权失败弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showAuthFailDialog(context: common.Context, otaStatus: OtaStatus, eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showAuthFailDialog');
    DialogHelper.displayAuthenticateFailDialog(retryCheckAction);
  }

  /**
   * 安装失败默认弹框
   *
   * @param context 上下文
   */
  @foregroundCheck()
  static showUpgradeFailDialog(context: common.Context, otaStatus: OtaStatus, eventId?: update.EventId): void {
    LogUtils.log('DialogUtils', 'showUpgradeFailDialog');
    DialogHelper.displayUpgradeFailDialog(retryCheckAction);
  }
}