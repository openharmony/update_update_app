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

import router from '@ohos.router';
import { UpdateState, UpgradeCallResult } from '@ohos/common/src/main/ets/const/update_const';
import { StateManager, UpdateAction } from '../manager/StateManager';
import { OtaUpdateManager } from '../manager/OtaUpdateManager';

/**
 * 一秒对应的时间(1000)
 */
const SECOND_INTERVAL = 1000;

/**
 * 拉起主页面的等待时间(单位秒)
 */
const SECONDS_FOR_PAGE = 0.1;

/**
 * 路由工具
 *
 * @since 2022-06-06
 */
namespace RouterUtils {
  function waitForSeconds(timeInSeconds: number): Promise<void> {
    return new Promise(resolver => {
      setTimeout(resolver, timeInSeconds * SECOND_INTERVAL);
    });
  }

  /**
   * 拉起主页面，并清除其他页面
   */
  export async function singletonHomePage(): Promise<void> {
    router.clear();
    await waitForSeconds(SECONDS_FOR_PAGE);
    router.replace({ url: 'pages/index' });
  }

  /**
   * 打开新版本页面
   */
  export function openNewVersionPage(): void {
    router.push({ url: 'pages/newVersion' });
  }

  /**
   * 打开当前版本页面
   */
  export function openCurrentVersion(): void {
    router.push({ url: 'pages/currentVersion' });
  }

  /**
   * 清理所有页面
   */
  export function clearAllPage(): void {
    router.clear();
  }

  /**
   * 是否能够跳转新版本页面
   *
   * @return 是否能够跳转
   */
  export async function isCanToNewVersion(): Promise<boolean> {
    return new Promise((resolve, reject) => {
      OtaUpdateManager.getInstance().getOtaStatus().then((upgradeData) => {
        if (upgradeData?.callResult === UpgradeCallResult.OK) {
          if (upgradeData.data?.status === UpdateState.UPGRADING) {
            resolve(false);
          } else {
            let isAllow: boolean = StateManager.isAllowExecute(upgradeData.data?.status as number,
              UpdateAction.SHOW_NEW_VERSION);
            resolve(isAllow);
          }
        } else {
          resolve(false);
        }
      });
    });
  }
}

export default RouterUtils;
