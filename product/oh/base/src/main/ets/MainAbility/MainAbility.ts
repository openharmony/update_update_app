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

import Ability from '@ohos.app.ability.UIAbility';
import type Want from '@ohos.app.ability.Want';
import type AbilityConstant from '@ohos.app.ability.AbilityConstant';
import router from '@ohos.router';
import type update from '@ohos.update';
import type window from '@ohos.window';
import type { Configuration } from '@ohos.app.ability.Configuration';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import type { OtaStatus } from '@ohos/common/src/main/ets/const/update_const';
import { StateManager } from '@ohos/ota/src/main/ets/manager/StateManager';
import { NotificationHelper } from '@ohos/ota/src/main/ets/notify/NotificationHelper';

/**
 * 主Ability
 *
 * @since 2022-06-06
 */
export default class MainAbility extends Ability {
  private static readonly WAITING_PREPARE_TIME = 1500;
  private language: string = '';

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.log('BaseAbility onCreate:' + this.context.config.screenDensity);
    globalThis.abilityWant = want;
    globalThis.abilityContext = this.context;
    globalThis.AbilityStatus = null;
    this.language = this.context.config.language;

    this.log('BaseAbility onCreate:' + this.context.config.screenDensity);
  }

  onDestroy(): void {
    this.log('BaseAbility onDestroy');
    globalThis.AbilityStatus = null;
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    globalThis.AbilityStatus = null;
    if (globalThis.abilityWant?.uri === 'pages/newVersion') {
      windowStage.loadContent('pages/newVersion', null);
    } else if (globalThis.abilityWant?.uri === 'pages/setting') {
      windowStage.loadContent('pages/setting', null);
    } else {
      windowStage.loadContent('pages/index', null);
    }
  }

  onNewWant(want: Want): void {
    this.log('BaseAbility onNewWant:' + JSON.stringify(want));
    globalThis.newPage = want.uri;
    if (globalThis.AbilityStatus === 'ON_FOREGROUND') {
      this.routePage();
    }
  }

  onConfigurationUpdate(config: Configuration): void {
    this.log(`onConfigurationUpdated: this.language=${this.language}, config.language=${config?.language}`);
    if (config && this.language !== config.language) {
      this.log(`onConfigurationUpdated: language changed, currentPage=${globalThis.currentPage}`);
      this.language = config.language;
      AppStorage.SetOrCreate('configLanguage', config.language);
    }
  }

  onWindowStageDestroy(): void {
    globalThis.AbilityStatus = null;
    this.log('BaseAbility onWindowStageDestroy');
  }

  onForeground(): void {
    this.log('BaseAbility onForeground');
    new NotificationHelper().cancelAll();
    globalThis.AbilityStatus = 'ON_FOREGROUND';
    setTimeout(() => {
      this.routePage();
      this.handleReceivedUpdatePageMessage();
    }, MainAbility.WAITING_PREPARE_TIME); // for env prepare
  }

  onBackground(): void {
    globalThis.AbilityStatus = null;
    this.log('BaseAbility onBackground');
  }

  private routePage(): void {
    if (globalThis.newPage && globalThis.currentPage) {
      if (globalThis.currentPage !== globalThis.newPage) {
        this.log('router.push page: ' + globalThis.newPage);
        router.pushUrl({
          url: globalThis.newPage,
        });
      }
      globalThis.newPage = null;
    }
  }

  private handleReceivedUpdatePageMessage(): void {
    if (globalThis.reNotify) { // page页面弹出对话框
      let otaStatus: OtaStatus = globalThis.otaStatusFromService;
      let eventId: update.EventId = globalThis.eventIdFromService;
      this.log('handleReceivedUpdatePageMessage otaStatus ' + JSON.stringify(otaStatus) + 'eventId is ' + eventId);
      StateManager.createInstance(otaStatus).notify(globalThis.abilityContext, eventId);
      globalThis.reNotify = undefined;
    }
  }

  protected log(message: string): void {
    LogUtils.log('BaseAbility', message);
  }
}