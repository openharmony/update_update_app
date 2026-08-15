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

const TAG = 'SettingOptions'

/**
 * 设置选项组件
 *
 * @since 2026-04-10
 */
@Component
export struct SettingOptions {
  private title?: string | Resource;
  private description?: string | Resource;
  @Prop private isEnabled: boolean = true;
  private toggleChange?: (isOn: boolean) => void;
  @Prop private isOn: boolean = false;
  private themeColor?: ResourceColor;

  @Builder
  private optionToggle(isEnabled: boolean) {
    Toggle({ type: ToggleType.Switch, isOn: this.isOn })
      .width('36vp')
      .height('20vp')
      .flexShrink(0)
      .enabled(isEnabled)
      .onChange((isOn) => {
        this.toggleChange?.(isOn)
      })
      .hoverEffect(HoverEffect.None)
      .selectedColor(this.themeColor)
      .id(`${TAG}_Toggle_01`)
  }

  build() {
    Column() {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
        Text(this.title)
          .fontSize($r('sys.float.ohos_id_text_size_body1'))
          .width('100%')
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontWeight(FontWeight.Medium)
          .draggable(false)
          .id(`${TAG}_Text_02`)

        if ((this.isEnabled)) {
          this.optionToggle(true);
        } else {
          this.optionToggle(false);
        }
      }
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .padding({
        top: $r('app.float.setting_options_padding_vertical'),
        right: $r('app.float.setting_options_padding_horizontal'),
        bottom: $r('app.float.setting_options_padding_vertical'),
        left: $r('app.float.setting_options_padding_horizontal')
      })
      .id(`${TAG}_Flex_01`)
      .constraintSize({ minHeight: $r('app.float.setting_options_height') })
      .borderRadius($r('app.float.setting_border_radius'))

      Text(this.description)
        .fontSize($r('app.float.text_size_body'))
        .width('100%')
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .padding({
          top: $r('app.float.setting_options_margin_top'),
          right: $r('app.float.setting_options_padding_horizontal'),
          left: $r('app.float.setting_options_padding_horizontal')
        })
        .draggable(false)
        .id(`${TAG}_Text_01`)
    }
    .margin({
      right: $r('app.float.page_left_or_right_margin'),
      left: $r('app.float.page_left_or_right_margin')
    })
    .id(`${TAG}_Column_01`)
  }
}