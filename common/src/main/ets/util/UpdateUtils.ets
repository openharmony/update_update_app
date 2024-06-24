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
import { LogUtils } from './LogUtils';

/**
 * 日志TAG
 */
const TAG = 'UpdateUtils';

/**
 * 接口工具
 *
 * @since 2022-06-06
 */
export namespace UpdateUtils {
  /**
   * 获取changelog信息
   *
   * @param componentDescriptions 新版本更新日志集合
   * @param componentId 组件id
   * @return changelog
   */
  export function obtainDescription(componentDescriptions: Array<update.ComponentDescription>, componentId: string): string {
    if (!componentDescriptions || componentId == null) {
      return '';
    }
    let descArray: update.ComponentDescription[] = componentDescriptions;
    for (let index = 0; index < descArray.length; index++) {
      if (componentId === descArray[index]?.componentId) {
        let description = descArray[index]?.descriptionInfo?.content;
        let descriptionType = descArray[index]?.descriptionInfo?.descriptionType;
        if (descriptionType != update.DescriptionType.CONTENT || description == null) {
          description = '';
        }
        return description;
      }
    }
    return '';
  }
  /**
   * 启动Ability
   *
   * @param context 要启动Ability的context
   * @param want 要启动Ability的want
   * @param options 配置项
   */
  export function startAbility(context: any, want, options): void {
    if (!context || !want) {
      LogUtils.error(TAG, 'Failed to start ability with error: context or want is null.');
      return;
    }
    context.startAbility(want, options).then((data) => {
      LogUtils.info(TAG, 'Succeed to start ability with data: ' + JSON.stringify(data));
    }).catch((error) => {
      LogUtils.error(TAG, 'Failed to start ability with error: ' + JSON.stringify(error));
    });
  }

  /**
   * 接口调用结果判断
   *
   * @param err 返回信息
   * @param return 接口调用结果
   */
  export function isSuccessCallback(result: unknown, err: any): boolean {
    return result && !err;
  }
}