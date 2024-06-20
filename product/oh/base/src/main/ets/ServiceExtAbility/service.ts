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

import Extension from '@ohos.app.ability.ServiceExtensionAbility';
import type Want from '@ohos.app.ability.Want';
import type rpc from '@ohos.rpc';
import { FormatUtils } from '@ohos/common/src/main/ets/util/FormatUtils';
import { OtaUpdateManager } from '@ohos/ota/src/main/ets/manager/OtaUpdateManager';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { ServiceExtStub } from './serviceStub';

/**
 * service extension ability.
 * receive want from update_engine
 *
 * @since 2022-05-31
 */
export default class ServiceExtAbility extends Extension {
  private static readonly TAG = 'ServiceExtAbility';
  private static readonly CONNECT_TIMEOUT: string = 'Timeout';
  private static readonly START_ID_CONNECT = 10000;
  private startIdArray: number[] = [];
  private connectTimeout: number = 15;
  private connectTimeoutId: number | null = null;

  onCreate(want: Want): void {
    LogUtils.log(ServiceExtAbility.TAG, 'onCreate:' + FormatUtils.stringify(want));
    globalThis.extensionContext = this.context; // when start ServiceExtAbility ,set context
  }

  async onRequest(want: Want, startId: number): Promise<void> {
    LogUtils.log(ServiceExtAbility.TAG, `onRequest, want: ${want?.abilityName}`);
    this.startIdArray.push(startId);
    globalThis.extensionContext = this.context;
    await OtaUpdateManager.getInstance().handleWant(want, globalThis.extensionContext);
    this.stopSelf(startId);
  }

  onConnect(want: Want): rpc.RemoteObject {
    LogUtils.log(ServiceExtAbility.TAG, `onConnect , want: ${want?.abilityName}`);
    this.startIdArray.push(ServiceExtAbility.START_ID_CONNECT);
    this.connectTimeout = want?.parameters?.[ServiceExtAbility.CONNECT_TIMEOUT] as number ?? this.connectTimeout;
    let objectIpc: rpc.RemoteObject = new ServiceExtStub(ServiceExtAbility.TAG, (message: string) => {
      return this.remoteMessageCallback(message);
    });
    return objectIpc;
  }

  private remoteMessageCallback(message: string): void {
    LogUtils.info(ServiceExtAbility.TAG,
      `remoteMessageCallback, timeout: ${this.connectTimeout}s, message: ${message}.`);
    if (this.connectTimeoutId !== null) {
      clearTimeout(this.connectTimeoutId);
    }
    this.connectTimeoutId = setTimeout(()=> {
      this.connectTimeoutId = null;
      this.stopSelf(ServiceExtAbility.START_ID_CONNECT);
    }, this.connectTimeout * 1000);

    let want: Want = {
      parameters: {
        parameters: FormatUtils.parseJson(message)
      }
    };
    OtaUpdateManager.getInstance().handleWant(want, globalThis.extensionContext);
  }

  onDisconnect(want: want) {
    LogUtils.info(ServiceExtAbility.TAG, `onDisconnect, want: ${want?.abilityName}`);
    this.stopSelf(ServiceExtAbility.START_ID_CONNECT);
  }

  private isTerminal(): boolean {
    let isTerminal: boolean = OtaUpdateManager.getInstance().isTerminal();
    return isTerminal;
  }

  private stopSelf(startId: number): void {
    this.startIdArray.splice(this.startIdArray.indexOf(startId), 1);
    LogUtils.info(ServiceExtAbility.TAG, 'stopSelf length ' + this.startIdArray.length);
    if (this.startIdArray.length === 0 && this.isTerminal()) {
      const terminateDelayTime = 2000;
      setTimeout(()=> {
        LogUtils.info(ServiceExtAbility.TAG, 'stopSelf');
        this.context?.terminateSelf().catch((err) => {
          LogUtils.error(ServiceExtAbility.TAG, 'stopSelf err is ' + JSON.stringify(err));
        });
      }, terminateDelayTime);
    }
  }
}