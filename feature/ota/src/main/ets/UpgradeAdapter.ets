
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

import { OtaPage } from './OtaPage';
import { NotificationHelper } from './notify/NotificationHelper';
import type { INotify, IPage } from '@ohos/common/src/main/ets/manager/UpgradeInterface';

/**
 * 升级适配器
 *
 * @since 2022-12-01
 */
export class UpgradeAdapter {
  private _notifyInstance: INotify | undefined = undefined;
  private _page: IPage | undefined = undefined;

  private constructor() {
    globalThis.upgradeAdapter = this;
  }

  /**
   * 取单例对象
   *
   * @return 适配器对象
   */
  static getInstance(): UpgradeAdapter {
    return (globalThis.upgradeAdapter as UpgradeAdapter) ?? new UpgradeAdapter();
  }

  /**
   * 取支持的升级类型以及UX实例
   *
   * @return 支持的升级类型以及UX实例
   */
  getPageInstance(): IPage {
    if (!this._page) {
      this._page = new OtaPage();
    }
    return this._page;
  }

  /**
   * 取提醒对象
   *
   * @return 提醒对象
   */
  getNotifyInstance(): INotify {
    if (!this._notifyInstance) {
      this._notifyInstance = new NotificationHelper();
    }
    return this._notifyInstance;
  }
}