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

import rpc from '@ohos.rpc';
import update from '@ohos.update';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';

/**
 * ServiceExtAbility 远端代理存根
 *
 * @since 2024-06-17
 */
export class ServiceExtStub extends rpc.RemoteObject {
  private static readonly TAG = 'ServiceExtStub';
  private static readonly MESSAGE_CODE = 5;
  private remoteMessageCallBack: (message: string) => void;

  constructor(des: string, callBack: (message: string) => void) {
    super(des);
    this.remoteMessageCallBack = callBack;
  }

  async onRemoteMessageRequest(code: number, data: rpc.MessageSequence, reply: rpc.MessageSequence,
    options: rpc.MessageOption): Promise<boolean> {
    let dataMessage = data.readString();
    LogUtils.info(ServiceExtStub.TAG, `onRemoteMessageRequest, code: ${code}, dataMessage: ${dataMessage}.`);
    switch (code) {
      case ServiceExtStub.MESSAGE_CODE:
        LogUtils.info(ServiceExtStub.TAG, `onRemoteMessageRequest, from ota update manager.`);
        reply.writeInt(0);
        this.remoteMessageCallBack(dataMessage);
        return true;
      default:
        LogUtils.info(ServiceExtStub.TAG, `onRemoteMessageRequest, do nothing for error code, code: ${code}.`);
        return true;
    }
  }
}
