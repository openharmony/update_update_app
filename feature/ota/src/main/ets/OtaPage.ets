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
import { ChangelogType, CountDownDialogType } from '@ohos/common/src/main/ets/const/update_const';
import { IPage, VersionPageInfo } from '@ohos/common/src/main/ets/manager/UpgradeInterface';
import { UpdateUtils } from '@ohos/common/src/main/ets/util/UpdateUtils';
import { FormatUtils } from '@ohos/common/src/main/ets/util/FormatUtils';
import VersionUtils from './util/VersionUtils';

/**
 * ota的ux显示数据
 *
 * @since 2022-12-01
 */
export class OtaPage implements IPage {
  /**
   * 取新版本数据
   *
   * @param versionComponents 升级包
   * @param componentDescriptions 更新日志
   * @return Promise<VersionPageInfo> 具体的新版本数据
   */
  public async getNewVersionPageInfo(versionComponents: Array<update.VersionComponent>,
    componentDescriptions?: Array<update.ComponentDescription>): Promise<VersionPageInfo> {
    let component: update.VersionComponent = versionComponents.filter((component: update.VersionComponent) => {
      return component.componentType == update.ComponentType.OTA;
    })?.[0];
    let componentId: string = component?.componentId;
    let description: string = '';
    if (componentDescriptions) {
      description = UpdateUtils.obtainDescription(componentDescriptions, componentId);
    }
    let isABInstall = await VersionUtils.isABInstall();
    const countDownTimes = 20;

    return {
      version: component.displayVersion,
      size: component.size,
      effectiveMode: component.effectiveMode,
      otaMode:component.otaMode,
      changelog: {
        version: component.displayVersion,
        size: FormatUtils.formatFileSize(component.size),
        displayType: ChangelogType.PICTURE_AND_TEXT,
        content: description
      },
      countDownDialogInfo: {
        dialogText: isABInstall ?
          $r('app.string.count_down_message_ab', component.displayVersion, countDownTimes) :
          $r('app.string.count_down_message_recovery', component.displayVersion, countDownTimes),
        dialogType: isABInstall ? CountDownDialogType.OTA_AB : CountDownDialogType.OTA
      }
    };
  }

  /**
   * 取当前版本数据
   *
   * @param versionComponents 升级包
   * @param componentDescriptions 更新日志
   * @return VersionPageInfo 具体的当前版本数据
   */
  public getCurrentVersionPageInfo(versionComponents: Array<update.VersionComponent>,
    componentDescriptions: Array<update.ComponentDescription>): VersionPageInfo {
    let component: update.VersionComponent = versionComponents.filter((component: update.VersionComponent) => {
      return component.componentType == update.ComponentType.OTA;
    })?.[0];
    let componentId: string = component?.componentId;
    let description: string = '';
    if (componentDescriptions) {
      description = UpdateUtils.obtainDescription(componentDescriptions, componentId);
    }
    return {
      version: VersionUtils.getCurrentDisplayVersion(),
      changelog: {
        version: VersionUtils.getCurrentDisplayVersion(),
        content: description
      }
    };
  }
}