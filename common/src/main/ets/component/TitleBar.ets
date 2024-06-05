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
import { LogUtils } from '../util/LogUtils';

/**
 * titleBar
 *
 * @since 2022-06-06
 */
@Component
export struct TitleBar {
  private static readonly TAG = 'TitleBar';
  private title: string | Resource;
  private onBack?: () => boolean;

  build() {
    Flex({ justifyContent: FlexAlign.SpaceBetween }) {
      Row() {
        Row() {
          Image($r('app.media.back'))
            .width($r('app.float.title_bar_icon_width'))
            .height($r('app.float.title_bar_icon_height'))
            .objectFit(ImageFit.Contain)
        }.height($r('app.float.title_bar_height'))
        .margin({ left: $r('app.float.title_bar_icon_margin_left') })
        .onClick(() => {
          let isCanNotBack = this.onBack?.();
          if (isCanNotBack) {
            LogUtils.info(TitleBar.TAG, 'can not router back');
            return;
          }
          LogUtils.info(TitleBar.TAG, 'terminateSelf.');
          router.back();
        })

        Text(this.title)
          .fontSize($r('app.float.text_size_title_bar'))
          .fontColor(Color.Black)
          .margin({ left: $r('app.float.title_bar_text_margin_left') })
          .fontWeight(FontWeight.Bold)
      }.flexGrow(1)
      .height($r('app.float.title_bar_height'))
    }
  }
}
