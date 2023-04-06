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

import { TitleBar } from '@ohos/common/src/main/ets/component/TitleBar';
import { HomeCardView } from '@ohos/common/src/main/ets/component/HomeCardView';
import { CheckingDots } from '@ohos/common/src/main/ets/component/CheckingDots';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { FormatUtils } from '@ohos/common/src/main/ets/util/FormatUtils';
import RouterUtils from '@ohos/ota/src/main/ets/util/RouterUtils';
import { VersionUtils } from '@ohos/ota/src/main/ets/util/VersionUtils';

/**
 * 搜包的状态
 *
 * @since 2022-06-12
 */
enum NewVersionStatus {
  CHECKING = 'CHECKING',
  NO_NEW_VERSION = 'NO_NEW_VERSION',
  HAS_NEW_VERSION = 'HAS_NEW_VERSION',
}

/**
 * 主页index
 *
 * @since 2022-06-06
 */
@Entry
@Component
struct Index {
  @State newVersionActionText: Resource = $r('app.string.check_version_status_no_new');
  @State dotTextPlay: boolean = false;
  @State newVersionStatus: string = NewVersionStatus.NO_NEW_VERSION;
  private displayVersion: string = VersionUtils.getDisplayVersionForIndex();
  private videoController: VideoController = new VideoController();
  private actionCallBack: Array<() => void> = [];
  private checkTimes: number= 0;
  private checkIntervalId: number;
  private checkLoopTimes: number = 0;
  @State private buttonText: string = '';

  /**
   * 是否已经有搜包结果
   */
  private checkEndStatus: NewVersionStatus = null;

  /**
   * 用来控制视频显示或者隐藏，解决卡顿
   */
  @State private displayVideo: boolean = true;

  private onCheckAction(): boolean {
    this.log(`onCheckAction ${this.checkEndStatus}`);
    if (!this.checkEndStatus || this.checkEndStatus === NewVersionStatus.CHECKING) {
      return false;
    }
    this.uiCheckLoop(false);
    for (let fun of this.actionCallBack) {
      fun();
    }
    this.actionCallBack = [];
    if (this.checkEndStatus == NewVersionStatus.HAS_NEW_VERSION) {
      this.newVersionStatus = NewVersionStatus.HAS_NEW_VERSION;
      this.newVersionActionText = $r('app.string.check_version_status_has_new');
      this.log('afterNewVersionFound');
      setTimeout(() => {
        RouterUtils.openNewVersionPage();
      }, 50);
    } else if (this.checkEndStatus == NewVersionStatus.NO_NEW_VERSION) {
      this.newVersionStatus = NewVersionStatus.NO_NEW_VERSION;
      this.newVersionActionText = $r('app.string.check_version_status_no_new');
    }
    this.checkEndStatus = null;
    return true;
  }

  private notifyNewVersionStatus(newVersionStatus): void {
    this.log('perform updateNewVersionStatus:' + newVersionStatus);
    this.checkEndStatus = newVersionStatus; // 延时更新
    if (newVersionStatus == NewVersionStatus.CHECKING) {
      this.newVersionStatus = newVersionStatus;
      this.newVersionActionText = $r('app.string.check_version_status_checking');
    }
  }

  /**
   * 执行搜包
   */
  private async checkNewVersionIfNeed(): Promise<void> {
    this.log('checkNewVersionIfNeed.');
    this.uiCheckLoop(true);
    this.checkLoopTimes = 0;
    this.notifyNewVersionStatus(NewVersionStatus.CHECKING);
    setTimeout(() => {
      this.notifyNewVersionStatus(NewVersionStatus.NO_NEW_VERSION);
    }, 2000)
  }

  /**
   * 开启text与video的轮播
   * 包含了一个setTimeout， 视频不播放不执行 onCheckAction()
   *
   * @param running
   */
  private uiCheckLoop(running: boolean): void {
    this.displayVideo = running;
    this.dotTextPlay = running;
    if (this.checkIntervalId != null) {
      clearInterval(this.checkIntervalId);
      this.checkIntervalId = null;
    }
    if (running) {
      this.checkTimes = 0;
      this.checkIntervalId = setInterval(() => {
        if (this.checkTimes === 0 && this.onCheckAction()) {
          clearInterval(this.checkIntervalId);
          this.checkIntervalId = null;
        }
      }, 7000);
    }
  }

  aboutToAppear() {
    this.log('aboutToAppear');
    this.checkNewVersionIfNeed();
  }

  onBackPress() {
    this.log('index back');
    globalThis.abilityContext.terminateSelf();
    return true;
  }

  onPageShow() {
    this.log('onPageShow index');
    RouterUtils.clearAllPage();
    globalThis.currentPage = 'pages/index';
    this.initButtonInfo();
    if (this.newVersionStatus === NewVersionStatus.CHECKING) {
      this.uiCheckLoop(true);
    }
  }

  public onLanguageChange(): void {
    this.initButtonInfo();
  }

  private initButtonInfo(): void {
    this.buttonText = FormatUtils.toUpperCase(globalThis.abilityContext, $r('app.string.btn_check_new_version'));
  }

  onPageHide() {
    this.log('onPageHide index');
    this.uiCheckLoop(false);
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
      TitleBar({
        title: $r('app.string.software_update'),
        onBack: this.onBackPress.bind(this)
      })
      Column() {
        Scroll() {
          Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
            HomeCardView({ playVideo: this.displayVideo, videoController: this.videoController, onVideoFinished: () => {
              this.checkTimes++;
              return this.onCheckAction.call(this);
            } })
            Text(this.displayVersion)
              .fontSize($r('app.float.home_text_size_version_name'))
              .fontWeight(FontWeight.Medium)
              .margin({
                top: $r('app.float.index_version_name_margin_top'),
                bottom: $r('app.float.index_version_name_margin_bottom')
              })
            Row() {
              Text(this.newVersionActionText)
                .fontSize($r('app.float.text_size_body'))
                .fontColor(this.newVersionStatus !== NewVersionStatus.CHECKING ?
                $r('app.color.blue') : Color.Black)
                .opacity(this.newVersionStatus !== NewVersionStatus.CHECKING ? 1 : 0.6)
                .fontWeight(FontWeight.Regular)
                .align(Alignment.Start)
                .onClick(() => this.handleStateClicked())
              CheckingDots({ dotTextPlay: this.dotTextPlay })
              if (this.newVersionStatus == NewVersionStatus.HAS_NEW_VERSION) {
                Circle({ width: '8vp', height: '8vp' })
                  .margin({ left: $r('app.float.index_has_new_version_margin_left') })
                  .fill($r('app.color.has_new_version_circle_fill'))
              }
            }
          }.padding({
            left: $r('app.float.index_content_padding_horizontal'),
            right: $r('app.float.index_content_padding_horizontal'),
            bottom: $r('app.float.index_content_padding_bottom')
          }).width('100%')
        }.width('100%')
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.On)
      }.flexGrow(1)
      Column() {
        Button() {
          Text(this.buttonText)
            .fontSize($r('app.float.text_size_btn')).fontColor(Color.White).fontWeight(FontWeight.Medium)
            .margin({ left: $r('app.float.custom_button_text_margin_left'),
              right: $r('app.float.custom_button_text_margin_right') })
        }
        .type(ButtonType.Capsule)
        .constraintSize({ minWidth: $r('app.float.custom_button_width') })
        .height($r('app.float.custom_button_height'))
        .backgroundColor($r('app.color.blue'))
        .opacity(this.newVersionStatus != NewVersionStatus.CHECKING ? 1 : 0.4)
        .onClick(()=>{
          if(this.newVersionStatus != NewVersionStatus.CHECKING) {
            this.checkNewVersionIfNeed()
          }
        })
      }.padding({
        left: $r('app.float.index_content_padding_horizontal'),
        right: $r('app.float.index_content_padding_horizontal'),
        bottom: $r('app.float.index_content_padding_bottom')
      })
    }
    .backgroundColor($r('app.color.page_background'))
    .width('100%')
    .height('100%')
  }

  private log(message: string): void {
    LogUtils.log('Index', message);
  }

  private async handleStateClicked() {
    this.log('handleStateClicked.');
  }
}