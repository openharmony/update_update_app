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
import type { UpgradeData } from '@ohos/common/src/main/ets/const/update_const';
import { UpgradeCallResult } from '@ohos/common/src/main/ets/const/update_const';
import { DeviceUtils } from '@ohos/common/src/main/ets/util/DeviceUtils';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { UpdateUtils } from '@ohos/common/src/main/ets/util/UpdateUtils';
import { OtaUpdateManager } from '../manager/OtaUpdateManager';
import { UpgradeAdapter } from '../UpgradeAdapter';

const TAG = 'VersionUtils';

/**
 * 版本工具
 *
 * @since 2022-06-06
 */
export namespace VersionUtils {
  /**
   * 计算升级包大小
   *
   * @param newVersionInfo 新版本信息
   * @return 升级包大小
   */
  export function calculatePackageSize(newVersion: update.NewVersionInfo): number {
    let totalSize: number = 0;
    for (let index = 0; index < newVersion?.versionComponents?.length; index++) {
      totalSize += Number(newVersion?.versionComponents?.[index]?.size);
    }
    LogUtils.info(TAG, 'calculatePackageSize, totalSize: ' + totalSize);
    return totalSize;
  }

  /**
   * 获取新版本名称
   *
   * @param info 新版本信息
   * @return 新版本名称
   */
  export async function obtainNewVersionName(info: update.NewVersionInfo | update.TaskBody): Promise<string> {
    let component: update.VersionComponent = sortComponents(info?.versionComponents)?.[0];
    if (!component) {
      return '';
    }
    return (await UpgradeAdapter.getInstance()
      .getPageInstance()?.getNewVersionPageInfo(info?.versionComponents))?.version ?? '';
  }

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
    return getAbbrUiVersion(DeviceUtils.getDisplayVersion());
  }

  /**
   * 获取鸿蒙缩略版本号 OXF-AN00 2.0.0.150(SP1C00E1R2P3) 返回2.0.0.150
   * 大屏场景：2.0.0.150(SP1C00E1R2P3) 返回2.0.0.150
   *
   * @param originalVersion 原始版本号
   * @return 鸿蒙缩略版本号
   */
  function getAbbrUiVersion(originalVersion: string): string {
    if (!originalVersion) {
      return '';
    }
    const beginIndex: number = originalVersion?.indexOf(' ') + 1;
    let endIndex: number = originalVersion?.indexOf('(');
    endIndex = endIndex < 0 ? originalVersion.length : endIndex;
    if (beginIndex === 0 || endIndex < beginIndex || endIndex > originalVersion.length) {
      return '';
    }
    return originalVersion.substring(beginIndex, endIndex);
  }

  /**
   * 排序
   *
   * @param components 升级包集合
   * @return 升级包集合
   */
  export function sortComponents(components: Array<update.VersionComponent>): Array<update.VersionComponent> {
    if (components) {
      return components.sort((component: update.VersionComponent, nextComponent: update.VersionComponent) => {
        return component.componentType - nextComponent.componentType;
      });
    }
    return null;
  }

  export async function getNewVersionDigest(): Promise<string> {
    let newVersionInfo: update.NewVersionInfo = globalThis.cachedNewVersionInfo ||
      await OtaUpdateManager.getInstance().getNewVersion().then((upgradeData: UpgradeData<update.NewVersionInfo>) => {
        return upgradeData.callResult === UpgradeCallResult.OK ? upgradeData.data : null;
      });

    if (newVersionInfo) {
      LogUtils.info(TAG, 'getNewVersionDigest, versionDigestInfo: ' + newVersionInfo.versionDigestInfo.versionDigest);
      return newVersionInfo.versionDigestInfo.versionDigest;
    }

    return '';
  }

  /**
   * 是否在新版本界面
   *
   * @return 是否在新版本界面
   */
  export function isInNewVersionPage(): boolean {
    return globalThis.AbilityStatus === 'ON_FOREGROUND' && globalThis.currentPage === 'pages/newVersion';
  }

  /**
   * 是否是AB升级
   *
   * @return 是否是AB升级
   */
  export async function isABInstall(): Promise<boolean> {
    let newVersionInfo = globalThis.cachedNewVersionInfo || await OtaUpdateManager.getInstance().getNewVersion()
      .then(upgradeData => {
        this.log(`initDataByStatus upgradeData: ${upgradeData}`);
        return upgradeData.callResult == UpgradeCallResult.OK ? upgradeData.data : null;
      });
    let components: Array<update.VersionComponent> = VersionUtils.sortComponents(newVersionInfo?.versionComponents);
    let component: update.VersionComponent = components?.filter((component: update.VersionComponent) => {
      return component.componentType == update.ComponentType.OTA;
    })?.[0];
    return component?.effectiveMode === update.EffectiveMode.LIVE_AND_COLD;
  }
}

export default VersionUtils;