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

import {DeviceUtils} from '../util/DeviceUtils'

/**
 * 主界面LOGO视频/图片
 *
 * @since 2022-06-06
 */
@Component
export struct HomeCardView {
  @Prop @Watch("onChange")
  private playVideo: boolean;
  private indexImage: number = 1;
  private indexVideo: number = 99;
  private aspectRatioHorizontal: number = 16 / 7;
  private aspectRatioVertical: number = 1 / 1;
  private onVideoFinished: () => boolean;
  private videoController: VideoController;
  @State private handleVideoPlay: boolean = false;

  onChange() {
    if (this.playVideo) {
      this.videoController.setCurrentTime(0);
      this.handleVideoPlay = true;
      setTimeout(() => {
        this.videoController.start(); // 500ms ensure to start play, Video NOT beating
      }, 500);
    } else {
      this.videoController.pause();
      this.handleVideoPlay = false;
    }
  }

  @Builder showLogoMedia(constraintSize) {
    Stack({ alignContent: Alignment.Center }) {
      Video({
        src: $r("app.media.video"),
        previewUri: $r('app.media.video_bg'),
        controller: this.videoController
      })
        .visibility(this.handleVideoPlay ? Visibility.Visible : Visibility.Hidden)
        .zIndex(this.indexVideo)
        .controls(false)
        .clip(true)
        .objectFit(ImageFit.Cover)
        .onFinish(() => {
          if (this.onVideoFinished) {
            if (!this.onVideoFinished()) {
              this.videoController.start();
            }
          }
        })
        .onPrepared(() => {
          this.onChange(); // when video Prepared.
        })
      Image($r('app.media.video_bg'))
        .objectFit(ImageFit.Cover)
        .zIndex(this.indexImage)
    }
    .aspectRatio(DeviceUtils.getDeviceType() == 'tablet' ? this.aspectRatioHorizontal : this.aspectRatioVertical)
    .constraintSize(constraintSize)
    .clip(true)
    .borderRadius($r('app.float.card_border_radius'))
    .width(constraintSize?.maxWidth ? "100%" : "67%")
  }

  build() {
    if (DeviceUtils.getDeviceType() == 'tablet') {
      this.showLogoMedia({ minWidth: $r('app.float.home_card_min_width')})
    } else {
      this.showLogoMedia({ minWidth: $r('app.float.home_card_min_width'), maxWidth: $r('app.float.home_card_max_width')})
    }
  }
}
