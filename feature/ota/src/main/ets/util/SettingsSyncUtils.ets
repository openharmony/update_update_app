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

import Settings from '@ohos.settings';
import type common from '@ohos.app.ability.common';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import type { OtaStatus } from '@ohos/common/src/main/ets/const/update_const';
import { UpdateState } from '@ohos/common/src/main/ets/const/update_const';

const TAG = 'SettingsSyncUtils';
const HW_NEW_SYSTEM_UPDATE = 'hw_new_system_update';
const HW_NEW_SYSTEM_UPDATE_STATUS = 'hw_new_system_update_status';

enum NewVersionViewStatus {
  VIEW_INIT = 0,
  VIEW_CHECK_SUCCESS,
  VIEW_DOWNLOADING,
  VIEW_DOWNLOAD_PAUSE,
  VIEW_DOWNLOAD_VERIFYING,
  VIEW_DOWNLOAD_SUCCESS,
  VIEW_UPGRADE_VERIFYING,
  VIEW_UPGRADE_REBOOTING,
  VIEW_UPGRADE_HOT_INSTALLING,
  VIEW_PRE_INSTALLING,
  VIEW_INSTALLING,
  VIEW_INSTALL_SUCCESS,
  VIEW_INSTALL_WAIT,
}

interface SettingsUpdateView {
  badge: number;
  status: NewVersionViewStatus;
}

export class SettingsSyncUtils {
  static syncCheckResult(hasNewVersion: boolean, context?: common.Context): void {
    if (hasNewVersion) {
      SettingsSyncUtils.writeView({ badge: 1, status: NewVersionViewStatus.VIEW_CHECK_SUCCESS }, context);
      return;
    }
    SettingsSyncUtils.syncReset(context);
  }

  static syncCancel(context?: common.Context): void {
    SettingsSyncUtils.writeView({ badge: 1, status: NewVersionViewStatus.VIEW_CHECK_SUCCESS }, context);
  }

  static syncReset(context?: common.Context): void {
    SettingsSyncUtils.writeView({ badge: 0, status: NewVersionViewStatus.VIEW_INIT }, context);
  }

  static syncFromOtaStatus(otaStatus: OtaStatus, context?: common.Context): void {
    const view = SettingsSyncUtils.mapStatus(otaStatus?.status);
    if (!view) {
      return;
    }
    SettingsSyncUtils.writeView(view, context);
  }

  private static mapStatus(status?: number): SettingsUpdateView | undefined {
    switch (status) {
      case UpdateState.INIT:
        return { badge: 0, status: NewVersionViewStatus.VIEW_INIT };
      case UpdateState.CHECK_SUCCESS:
        return { badge: 1, status: NewVersionViewStatus.VIEW_CHECK_SUCCESS };
      case UpdateState.DOWNLOADING:
        return { badge: 1, status: NewVersionViewStatus.VIEW_DOWNLOADING };
      case UpdateState.DOWNLOAD_PAUSE:
        return { badge: 1, status: NewVersionViewStatus.VIEW_DOWNLOAD_PAUSE };
      case UpdateState.DOWNLOAD_SUCCESS:
        return { badge: 1, status: NewVersionViewStatus.VIEW_DOWNLOAD_SUCCESS };
      case UpdateState.INSTALLING:
      case UpdateState.UPGRADING:
        return { badge: 1, status: NewVersionViewStatus.VIEW_INSTALLING };
      case UpdateState.INSTALL_SUCCESS:
        return { badge: 1, status: NewVersionViewStatus.VIEW_INSTALL_SUCCESS };
      case UpdateState.DOWNLOAD_CANCEL:
      case UpdateState.DOWNLOAD_FAILED:
      case UpdateState.INSTALL_FAILED:
      case UpdateState.UPGRADE_FAILED:
        return { badge: 1, status: NewVersionViewStatus.VIEW_CHECK_SUCCESS };
      case UpdateState.UPGRADE_SUCCESS:
        return { badge: 0, status: NewVersionViewStatus.VIEW_INIT };
      default:
        return undefined;
    }
  }

  private static writeView(view: SettingsUpdateView, context?: common.Context): void {
    const resolvedContext = SettingsSyncUtils.getContext(context);
    if (!resolvedContext) {
      LogUtils.warn(TAG, 'writeView skip because context is empty');
      return;
    }

    SettingsSyncUtils.setSettingsValue(resolvedContext, HW_NEW_SYSTEM_UPDATE, String(view.badge));
    SettingsSyncUtils.setSettingsValue(resolvedContext, HW_NEW_SYSTEM_UPDATE_STATUS, String(view.status));
  }

  private static getContext(context?: common.Context): common.Context | undefined {
    return globalThis.abilityContext || context || globalThis.stageContext || globalThis.extensionContext;
  }

  private static setSettingsValue(context: common.Context, key: string, value: string): void {
    try {
      const result = Settings.setValueSync(context, key, value);
      LogUtils.info(TAG, `setSettingsValue key=${key}, value=${value}, result=${JSON.stringify(result)}`);
      if (!result) {
        LogUtils.warn(TAG, `setSettingsValue returned false, key=${key}`);
      }
    } catch (err) {
      LogUtils.error(TAG, `setSettingsValue failed, key=${key}, err=${JSON.stringify(err)}`);
    }
  }
}
