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

import { SettingOptions } from '@ohos/common/src/main/ets/component/SettingOptions'
import { TitleBar } from '@ohos/common/src/main/ets/component/TitleBar';
import { NIGHT_UPGRADE_START, NIGHT_UPGRADE_END } from '@ohos/common/src/main/ets/const/update_const';
import { FormatUtils } from '@ohos/common/src/main/ets/util/FormatUtils';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { SettingsViewModel } from '../viewmodel/settingsViewModel';

const TAG = 'SettingsView'

/**
 * 更新选项
 *
 * @since 2026-04-13
 */
@Entry
@Component
struct SettingsView {
  @State private viewModel: SettingsViewModel = new SettingsViewModel();

  aboutToAppear(): void {
    LogUtils.info(TAG, 'aboutToAppear SettingsView');
    globalThis.newVersionThis = this;
  }

  onPageShow(): void {
    LogUtils.info(TAG, 'onPageShow SettingsView');
    globalThis.currentPage = 'pages/settingsView';
    this.viewModel.initUpdatePolicy();
  }

  onPageHide(): void {
    LogUtils.info(TAG, 'onPageHide SettingsView');
  }

  onBackPress(): boolean | void {
    LogUtils.info(TAG, 'onBackPress SettingsView');
  }

  build() {
    NavDestination() {
      this.pageContent();
    }
    .hideTitleBar(true)
    .onShown((): void => this.onPageShow())
    .id(`${TAG}_NavDestination`)
  }

  @Builder
  pageContent() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
      TitleBar({
        title: $r('app.string.local_settings')
      })

      Scroll() {
        Column({ space: '24vp' }) {
          SettingOptions({
            title: $r('app.string.setting_auto_download_title'),
            description: $r('app.string.setting_auto_download_description'),
            toggleChange: (isOn: boolean) => {
              this.viewModel.autoDownloadToggleChange(isOn)
            },
            isOn: this.viewModel.isAutoDownloadOpen()
          })

          SettingOptions({
            title: $r('app.string.setting_auto_update_title'),
            description: $r('app.string.setting_auto_update_description',
              FormatUtils.getDateRangeFormat(NIGHT_UPGRADE_START, NIGHT_UPGRADE_END)),
            toggleChange: (isOn: boolean) => {
              this.viewModel.nightUpgradeToggleChange(isOn);
            },
            isOn: this.viewModel.isAutoUpgradeOpen()
          })
        }
        .padding({
          top: '16vp'
        })
        .id(`${TAG}_pageContent_Column`)
      }
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    .backgroundColor($r('app.color.page_background'))
  }
}
