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
import { UpgradeCallResult } from '@ohos/common/src/main/ets/const/update_const';
import { TitleBar } from '@ohos/common/src/main/ets/component/TitleBar';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { VersionPageInfo } from '@ohos/common/src/main/ets/manager/UpgradeInterface';
import { UpgradeAdapter } from '@ohos/ota/src/main/ets/UpgradeAdapter';
import { ChangelogContent } from '@ohos/ota/src/main/ets/components/ChangelogContent';
import { OtaUpdateManager } from '@ohos/ota/src/main/ets/manager/OtaUpdateManager';
import { VersionUtils } from '@ohos/ota/src/main/ets/util/VersionUtils';

/**
 * 当前版本页面
 *
 * @since 2022-06-06
 */
@Entry
@Component
struct CurrentVersion {

  @State private versionArray: Array<VersionPageInfo> = null;

  aboutToAppear() {
  }

  public onLanguageChange(): void {
//    this.initCurrentVersionPageInfo();
  }

  private async initCurrentVersionPageInfo(): Promise<void> {
    let upgradeData = await OtaUpdateManager.getInstance().getCurrentVersionInfo();
    let componentDescription = await OtaUpdateManager.getInstance().getCurrentVersionDescription();
    if (upgradeData.callResult == UpgradeCallResult.OK) {
      if (!upgradeData.data) {
        return;
      }
      let components: Array<update.VersionComponent> = VersionUtils.sortComponents(
        upgradeData.data?.versionComponents);
      this.versionArray = components.map((component: update.VersionComponent) => {
        return UpgradeAdapter.getInstance()
          .getPageInstance()?.getCurrentVersionPageInfo(components, componentDescription?.data);
      }).filter((versionPageInfo: VersionPageInfo) => {
        return versionPageInfo != null;
      });
    }
  }

  onPageShow(): void {
    this.logInfo('onPageShow CurrentVersionPage');
    globalThis.currentPage = 'pages/currentVersion';
//    this.initCurrentVersionPageInfo();
  }

  onPageHide(): void {
    this.logInfo('onPageHide CurrentVersionPage');
  }


  onBackPress() {
    return false;
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
      Column() {
        TitleBar({ title: $r('app.string.title_current_version'), onBack: this.onBackPress.bind(this) })
      }.flexShrink(0)

      Scroll() {
        Column() {
          Column() {
            Column() {
              Image($r('app.media.logo'))
                .height($r('app.float.progress_logo_other_height'))
                .width($r('app.float.progress_logo_other_width'))
            }
            .padding({
              top: $r('app.float.progress_logo_other_padding_top'),
              bottom: $r('app.float.progress_logo_other_padding_bottom')
            })
          }.flexShrink(0)

          if (this.versionArray) {
            Column() {
              ForEach(this.versionArray, (pageInfo: VersionPageInfo) => {
                Text(pageInfo.version)
                  .fontSize($r('app.float.text_size_version_name'))
                  .maxLines(5)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .fontWeight(FontWeight.Medium)
                  .width('100%')
                  .textAlign(this.versionArray.length > 1 ? TextAlign.Start : TextAlign.Center)
                  .padding({
                    right: $r('app.float.version_padding'),
                    left: $r('app.float.version_padding'),
                    bottom: this.versionArray.length > 1 ? $r('app.float.current_version_name_margin_bottom') :
                    $r('app.float.current_version_name_margin_bottom_single')
                  })
                ChangelogContent({
                  isCurrentPage: true,
                  isNeedFold: this.versionArray?.length > 1,
                  description: JSON.stringify([pageInfo.changelog])
                })
              })
            }.flexShrink(0).margin({ bottom: $r('app.float.current_version_changelog_margin_bottom') })
          }
        }.width('100%').flexShrink(0)
      }.width('100%')
      .scrollable(ScrollDirection.Vertical)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  private logInfo(message: string): void {
    LogUtils.info('CurrentVersion', message);
  }
}