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

import { StateManager, UpdateAction } from '../manager/StateManager';

/**
 * 获取显示进度值
 *
 * @param progress 进度值
 * @return 显示进度值
 */
function getDisplayProgress(progress): number {
  let displayProgress = 0;
  if (!isNaN(progress)) {
    displayProgress = (progress).toFixed(0);
  }
  return displayProgress;
}

/**
 * 下载进度组件
 *
 * @since 2022-06-06
 */
@Component
export struct ProgressContent {
  @StorageProp('updateStatus')
  private updateStatus: number = AppStorage.Get('updateStatus');
  @StorageProp('downloadProgress')
  private downloadProgress: number = AppStorage.Get('downloadProgress');

  @Builder ProgressView() {
    Stack({ alignContent: Alignment.Center }) {
      Progress({ value: this.downloadProgress, style: ProgressStyle.Ring })
        .style({ strokeWidth: $r('app.float.progress_stroke_width') })
        .color($r('app.color.blue'))
        .width($r('app.float.new_version_progress_bar_size'))
      Flex({ alignItems: ItemAlign.Baseline, justifyContent: FlexAlign.Center }) {
        Text(`${getDisplayProgress(this.downloadProgress)}`)
          .fontColor(Color.Black)
          .fontSize($r('app.float.text_size_progress_bar'))
          .fontWeight(FontWeight.Medium)
          .margin({ right: $r('app.float.progress_number_margin_right') })
        Text('%')
          .fontColor(Color.Black)
          .fontSize($r('app.float.text_size_progress_bar_percent'))
          .fontWeight(FontWeight.Medium)
          .opacity(0.6)
      }
    }
    .width($r('app.float.new_version_progress_bar_size'))
    .height($r('app.float.new_version_progress_bar_size'))
  }

  build() {
    Column() {
      if (StateManager.isAllowExecute(this.updateStatus, UpdateAction.SHOW_PROCESS_VIEW)) {
        Flex().height($r('app.float.new_version_progress_bar_margin_top'))
        this.ProgressView()
        Flex().height($r('app.float.new_version_progress_bar_margin_bottom'))
        Text(StateManager.getDownloadStateText(this.updateStatus))
          .fontSize($r('app.float.text_size_body'))
          .fontWeight(FontWeight.Regular)
          .opacity(0.6)
          .margin({ bottom: $r('app.float.new_version_download_status_label_margin_bottom')})
      } else {
        Column() {
          Image($r('app.media.logo'))
            .height($r('app.float.progress_logo_other_height'))
            .width($r('app.float.progress_logo_other_width'))
        }
        .padding({
          top: $r('app.float.progress_logo_other_padding_top'),
          bottom: $r('app.float.progress_logo_other_padding_bottom')
        })
      }
    }.flexShrink(0)
  }
}