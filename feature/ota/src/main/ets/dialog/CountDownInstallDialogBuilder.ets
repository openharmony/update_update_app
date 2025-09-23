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

import { CountDownDialogType } from '@ohos/common/src/main/ets/const/update_const';
import { FormatUtils } from '@ohos/common/src/main/ets/util/FormatUtils'

/**
 * 倒计时弹框建造者
 *
 * @since 2022-06-05
 */
@CustomDialog
export struct CountDownInstallDialogBuilder {
  @StorageProp('configLanguage')
  @Watch('onLanguageChange') private configLanguage: string = AppStorage.Get('configLanguage') as string;

  /**
   * 控制器
   */
  controller: CustomDialogController;

  /**
   * 文本显示内容
   */
  textString: Resource | string = '';

  /**
   * 取消按钮显示内容
   */
  @State cancelBtnText: string = '';

  /**
   * 确定按钮显示内容
   */
  @State confirmBtnText: string = '';

  /**
   * 弹窗类型
   */
  dialogType: CountDownDialogType | undefined = undefined;

  /**
   * 倒计时
   */
  @State count: number = 20;

  /**
   * 取消回调
   */
  cancel: () => void = () => {
  };

  /**
   * 确认回调
   */
  confirm: () => void = () => {
  };

  private intervalID: number | null = null;

  aboutToAppear() {
    this.getCount();
    this.initButtonText();
  }

  aboutToDisappear() {

  }

  private getCount() {
    this.intervalID = setInterval(() => {
      this.count--;
      this.initButtonText();
      if (this.count <= 0) {
        clearInterval(this.intervalID);
        this.controller.close();
        this.confirm();
      }
    }, 1000);
  }

  private onLanguageChange(): void {
    this.initButtonText();
  }

  private initButtonText(): void {
    this.cancelBtnText = FormatUtils.toUpperCase(globalThis.abilityContext, $r('app.string.later'));
    let confirmBtnRes: ResourceStr = '';
    if (this.dialogType == CountDownDialogType.OTA) {
      confirmBtnRes = $r('app.string.install_now');
    } else if (this.dialogType == CountDownDialogType.OTA_AB) {
      confirmBtnRes = $r('app.string.reboot_now');
    }
    this.confirmBtnText = FormatUtils.toUpperCase(globalThis.abilityContext, confirmBtnRes, this.count);
  }

  @Styles buttonStyles() {
    .onClick(() => {
      this.controller.close();
      if (this.intervalID != null) {
        clearInterval(this.intervalID);
      }
      this.confirm();
    })
    .backgroundColor($r('sys.color.ohos_id_color_dialog_bg_transparent'))
    .height($r('app.float.dialog_button_height'))
    .layoutWeight(1)
    .padding({
      left: '0vp',
      right: '0vp'
    })
  }

  build() {
    Column() {
      Column() {
        Text($r('app.string.software_update')).width('100%').fontSize($r('app.float.text_size_dialog_title'))
        Text(this.textString)
          .width('100%')
          .fontSize($r('app.float.text_size_dialog_body'))
          .margin({
            top: $r('app.float.dialog_margin_top'),
            bottom: $r('app.float.dialog_content_margin_vertical')
          })
      }
      .margin({
        left: $r('app.float.dialog_margin_horizontal'),
        right: $r('app.float.dialog_margin_horizontal')
      })

      Row() {
        Button(this.cancelBtnText)
          .onClick(() => {
            this.controller.close();
            if (this.intervalID != null) {
              clearInterval(this.intervalID);
            }
            this.cancel();
          })
          .backgroundColor($r('sys.color.ohos_id_color_dialog_bg_transparent'))
          .fontColor($r('app.color.blue'))
          .height($r('app.float.dialog_button_height'))
          .fontSize($r('app.float.text_size_btn'))
          .layoutWeight(1)
          .padding({
            right: '0vp',
            left: '0vp'
          })
        Divider()
          .vertical(true)
          .height($r('app.float.dialog_divider_height'))
          .strokeWidth('0.8vp')
          .color($r('app.color.dialog_divider_color'))
          .margin({
            left: $r('app.float.divider_margin'),
            right: $r('app.float.divider_margin')
          })
        if (this.confirmBtnText) {
          Button() {
            Text(this.confirmBtnText)
              .fontColor($r('app.color.blue'))
              .fontSize($r('app.float.text_size_btn'))
              .textAlign(TextAlign.Center)
          }
          .buttonStyles()
        }
      }
      .margin({
        left: $r('app.float.dialog_row_margin_horizontal'),
        right: $r('app.float.dialog_row_margin_horizontal')
      })
    }
    .margin({
      top: $r('app.float.dialog_margin_top'),
      bottom: $r('app.float.dialog_margin_bottom'),
    })
  }
}