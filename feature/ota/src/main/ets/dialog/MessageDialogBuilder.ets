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

/**
 * 安装流程框构造者
 *
 * @since 2022-06-05
 */
@CustomDialog
export struct MessageDialogBuilder {
  /**
   * 内容
   */
  message: ResourceStr;

  /**
   * 控制器
   */
  controller: CustomDialogController;

  build() {
    Column() {
      Row() {
        LoadingProgress()
          .width($r('app.float.message_dialog_loading_progress_width'))
          .height($r('app.float.message_dialog_loading_progress_height'))
          .color(Color.Gray)
        Text(this.message)
          .width('100%')
          .fontSize($r('app.float.text_size_dialog_body'))
          .padding({ left: $r('app.float.message_dialog_text_padding_left') })
      }
    }
    .margin({
      left: $r('app.float.dialog_margin_horizontal'),
      right: $r('app.float.dialog_margin_horizontal'),
      top: $r('app.float.message_dialog_margin_vertical'),
      bottom: $r('app.float.message_dialog_margin_vertical')
    })
  }
}