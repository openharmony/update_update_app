/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
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

import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { OtaUpdateManager } from 'ota/src/main/ets/manager/OtaUpdateManager';
import update from '@ohos.update';
import { JSON } from '@kit.ArkTS';

const TAG = 'SettingsViewModel';

/**
 * 设置页面视图控制
 *
 * @since 2026-04-13
 */
export class SettingsViewModel {
  private isAutoDownload: boolean = false;
  private isAutoUpgrade: boolean = false;

  constructor() {
  }

  isAutoDownloadOpen(): boolean {
    LogUtils.info(TAG, `isAutoDownloadOpen: ${this.isAutoDownload}`);
    return this.isAutoDownload;
  }

  isAutoUpgradeOpen(): boolean {
    LogUtils.info(TAG, `isAutoUpgradeOpen: ${this.isAutoUpgrade}`);
    return this.isAutoUpgrade;
  }

  async initUpdatePolicy(): Promise<void> {
    OtaUpdateManager.getInstance().getUpdatePolicy().then((upgradePolicy: update.UpgradePolicy) => {
      LogUtils.info(TAG, `initUpdatePolicy: ${JSON.stringify(upgradePolicy)}`);
      if (!upgradePolicy.downloadStrategy && upgradePolicy.autoUpgradeStrategy) {
        // 不能出现夜间安装打开，自动下载关闭的情况
        upgradePolicy.downloadStrategy = false;
        upgradePolicy.autoUpgradeStrategy = false;
        OtaUpdateManager.getInstance().setUpdatePolicy(upgradePolicy);
      }
      this.refreshSwitches(upgradePolicy);
    })
  }

  async autoDownloadToggleChange(isOn: boolean): Promise<void> {
    LogUtils.info(TAG, `autoDownloadToggleChange isOn: ${isOn}`);
    let upgradePolicy = await OtaUpdateManager.getInstance().getUpdatePolicy();
    if (isOn) {
      this.isAutoDownload = true;
      upgradePolicy.downloadStrategy = true;
    } else {
      this.isAutoDownload = false;
      this.isAutoUpgrade = false;
      upgradePolicy.downloadStrategy = false;
      // 关闭自动下载，夜间安装也要随之关闭
      upgradePolicy.autoUpgradeStrategy = false;
    }
    OtaUpdateManager.getInstance().setUpdatePolicy(upgradePolicy);
  }

  async nightUpgradeToggleChange(isOn: boolean): Promise<void> {
    LogUtils.info(TAG, `nightUpgradeToggleChange isOn: ${isOn}`);
    let upgradePolicy = await OtaUpdateManager.getInstance().getUpdatePolicy();
    if (isOn) {
      this.isAutoUpgrade = true;
      this.isAutoDownload = true;
      upgradePolicy.autoUpgradeStrategy = true;
      // 打开夜间升级，自动下载也要随之打开
      upgradePolicy.downloadStrategy = true;
    } else {
      this.isAutoUpgrade = false;
      upgradePolicy.autoUpgradeStrategy = false;
    }
    OtaUpdateManager.getInstance().setUpdatePolicy(upgradePolicy);
  }

  refreshSwitches(upgradePolicy: update.UpgradePolicy): void {
    this.isAutoDownload = upgradePolicy.downloadStrategy;
    this.isAutoUpgrade = upgradePolicy.autoUpgradeStrategy;
  }
}