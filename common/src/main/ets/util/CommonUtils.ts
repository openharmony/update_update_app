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

import type update from '@ohos.update';
import type common from '@ohos.app.ability.common';
import { StartOptions } from '@kit.AbilityKit';
import { MAIN_ABILITY_NAME, PACKAGE_NAME, UpdateState, OtaStatus } from '../const/update_const';
import type { BusinessError } from '../const/update_const';
import { LogUtils } from './LogUtils';

const TIME_OUT_FOR_START_ABILITY = 500;
type unionContext = common.UIAbilityContext | common.ServiceExtensionContext | common.UIExtensionContext;

/**
 * 接口工具
 *
 * @since 2025-06-07
 */
export class CommonUtils {
  /**
   * 判空处理
   *
   * @param value 值
   * @return 是否为空
   */
  static isEmpty<T>(value: T): boolean {
    return value === null || value === undefined;
  }


  /**
   * JSON stringify方法封装
   *
   * @param value JS对象
   * @return json字符串
   */
  static stringify<T>(value: T): string {
    if (value) {
      try {
        return JSON.stringify(value);
      } catch (exception) {
        LogUtils.error('CommonUtils', 'JSON.stringify failed !!');
        return '';
      }
    }
    return '';
  }

  /**
   * json 字符串解析
   *
   * @param content json 字符串
   * @return T 解析后返回值
   */
  static parseJson<T>(content: string): T {
    if (!content) {
      return null;
    }
    try {
      return JSON.parse(content) as T;
    } catch (exception) {
      LogUtils.error('CommonUtils', 'paramJson failed !!');
    }
    return null;
  }

  /**
   * string判空处理
   *
   * @param value string值
   * @return 是否为空
   */
  static isStringEmpty(value: string | undefined | null): boolean {
    return value === null || value === undefined || value === '';
  }
}

/**
 * 装饰器--弹框时，前台判断处理
 */
export function foregroundCheck() {
  return (target: Object, propertyKey: string, descriptor: PropertyDescriptor): void => {
    const original = descriptor.value;
    descriptor.value = (context: common.Context, otaStatus: OtaStatus,
      eventId?: update.EventId, ...args): void => {
      if (globalThis.AbilityStatus !== 'ON_FOREGROUND') {
        globalThis.reNotify = true;
        globalThis.otaStatusFromService = otaStatus;
        globalThis.eventIdFromService = eventId;
        LogUtils.log('foregroundCheck', 'do startMainAbilityIndex.');

        // 应用在后台时，无法弹框，需杀掉ability后，重新拉起界面弹框
        globalThis.abilityContext?.terminateSelf();
        setTimeout(() => {
          startMainAbilityIndex(context);
        }, TIME_OUT_FOR_START_ABILITY);
        return;
      }
      original.call(this, ...args);
    };
  };
}

/**
 * 启动Ability
 *
 * @param context 要启动Ability的context
 * @param want 要启动Ability的want
 * @param options 配置项
 */
export function startAbility(context: common.Context, want: Want, options?: StartOptions): void {
  if (!context || !want) {
    LogUtils.error('CommonUtils', 'Failed to start ability with error: context or want is null.');
    return;
  }
  (context as unionContext).startAbility(want, options).then(() => {
    LogUtils.info('CommonUtils', 'Succeed to start ability' );
  }).catch((error: BusinessError) => {
    LogUtils.error('CommonUtils', 'Failed to start ability with error: ' + JSON.stringify(error));
  });
}

export function startMainAbilityIndex(context: common.Context): void {
  let want: Want = {
    bundleName: PACKAGE_NAME,
    abilityName: MAIN_ABILITY_NAME,
    uri: 'pages/newVersion',
  };
  startAbility(context, want, undefined);
}