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
import { StartOptions } from '@kit.AbilityKit';
import {
  Action,
  PACKAGE_NAME,
  MAIN_ABILITY_NAME
} from '@ohos/common/src/main/ets/const/update_const';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { UpdateUtils } from '@ohos/common/src/main/ets/util/UpdateUtils';
import RouterUtils from '../util/RouterUtils';

/**
 * 日志TAG
 */
const TAG = 'NotificationManager';

/**
 * 通知点击事件管理类
 *
 * @since 2022-06-05
 */
export class NotificationManager {
  /**
   * 处理通知点击动作
   *
   * @param action 具体动作
   */
  static async handleAction(action: string, context: common.Context): Promise<boolean> {
    switch (action) {
      case Action.NOTIFICATION_CHECK:
        NotificationManager.handleCheckAction(context);
        return true;
      case Action.NOTIFICATION_DETAIL:
        await NotificationManager.handleDetailAction(context);
        return true;
      default:
        return false;
    }
  }

  private static handleCheckAction(context: common.Context): void {
    LogUtils.log(TAG, 'handleCheckAction');
    NotificationManager.startAbility('pages/index', context);
  }

  private static async handleDetailAction(context: common.Context): Promise<void> {
    LogUtils.log(TAG, 'handleDetailAction');
    if (await RouterUtils.isCanToNewVersion()) {
      NotificationManager.startAbility('pages/newVersion', context);
    } else {
      NotificationManager.startAbility('pages/index', context);
    }
  }

  public static async startToNewVersion(context: common.Context): Promise<void> {
    if (await RouterUtils.isCanToNewVersion()) {
      NotificationManager.startAbility('pages/newVersion', context);
    }
  }

  private static startAbility(uri: string, context: common.Context): void {
    let want: Want = {
      bundleName: PACKAGE_NAME,
      abilityName: MAIN_ABILITY_NAME,
      uri: uri
    };
    let options: StartOptions = {
      windowMode: 0,
      displayId: 2
    };
    UpdateUtils.startAbility(context, want, options);
  }
}