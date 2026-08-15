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

import type common from '@ohos.app.ability.common';
import type Want from '@ohos.app.ability.Want';
import rpc from '@ohos.rpc';
import { PACKAGE_NAME } from '@ohos/common/src/main/ets/const/update_const';
import type { BusinessError } from '@ohos/common/src/main/ets/const/update_const';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';

const TAG = 'SceneBoardDialogMgr';
const SYSTEM_DIALOG_BUNDLE = 'com.ohos.sceneboard';
const SYSTEM_DIALOG_ABILITY = 'com.ohos.sceneboard.systemdialog';
const UPDATE_DIALOG_ABILITY = 'UpdateSystemDialogAbility';
const START_DIALOG_CMD = 1;
const REQUEST_PARAM_NUM = 3;
const SUCCESS_CODE = 0;

type DialogConnectContext = common.UIAbilityContext | common.ServiceExtensionContext;

export enum SceneBoardDialogType {
  DOWNLOAD_REMINDER = 'downloadReminder'
}

export interface SceneBoardDialogOptions {
  dialogType: SceneBoardDialogType;
}

/**
 * 使用SceneBoard的系统弹窗服务来显示 updateapp UI扩展弹窗
 */
export class SceneBoardDialogManager {
  private static requestingType?: SceneBoardDialogType;

  static async showDialog(context: common.Context, options: SceneBoardDialogOptions): Promise<boolean> {
    const dialogContext = context as DialogConnectContext;
    if (!dialogContext?.connectServiceExtensionAbility) {
      LogUtils.warn(TAG, 'Context does not support connectServiceExtensionAbility.');
      return false;
    }
    if (SceneBoardDialogManager.requestingType !== undefined) {
      LogUtils.info(TAG, `Dialog request is in progress: ${SceneBoardDialogManager.requestingType}`);
      return false;
    }

    SceneBoardDialogManager.requestingType = options.dialogType;
    const want: Want = {
      bundleName: SYSTEM_DIALOG_BUNDLE,
      abilityName: SYSTEM_DIALOG_ABILITY
    };

    return new Promise<boolean>((resolve) => {
      let connectionId: number = -1;
      let settled: boolean = false;
      const finish = (success: boolean): void => {
        if (settled) {
          return;
        }
        settled = true;
        SceneBoardDialogManager.requestingType = undefined;
        if (connectionId >= 0) {
          try {
            dialogContext.disconnectServiceExtensionAbility(connectionId).catch((error: BusinessError) => {
              LogUtils.error(TAG, `Disconnect system dialog failed: ${JSON.stringify(error)}`);
            });
          } catch (error) {
            LogUtils.error(TAG, `Disconnect system dialog exception: ${JSON.stringify(error)}`);
          }
        }
        resolve(success);
      };

      const connectOption: common.ConnectOptions = {
        onConnect(elementName, remote) {
          const data = rpc.MessageSequence.create();
          const reply = rpc.MessageSequence.create();
          const option = new rpc.MessageOption();
          const parameters: Record<string, Object> = {
            'ability.want.params.uiExtensionType': 'sysDialog/common',
            'sysDialogZOrder': 1,
            'dialogType': options.dialogType
          };
          try {
            data.writeInt(REQUEST_PARAM_NUM);
            data.writeString('bundleName');
            data.writeString(PACKAGE_NAME);
            data.writeString('abilityName');
            data.writeString(UPDATE_DIALOG_ABILITY);
            data.writeString('parameters');
            data.writeString(JSON.stringify(parameters));
            remote.sendMessageRequest(START_DIALOG_CMD, data, reply, option).then(() => {
              const result = reply.readInt();
              LogUtils.info(TAG, `Show ${options.dialogType} reply=${result}`);
              finish(result === SUCCESS_CODE);
            }).catch((error: BusinessError) => {
              LogUtils.error(TAG, `Show ${options.dialogType} failed: ${JSON.stringify(error)}`);
              finish(false);
            }).finally(() => {
              data.reclaim();
              reply.reclaim();
            });
          } catch (error) {
            data.reclaim();
            reply.reclaim();
            LogUtils.error(TAG, `Build ${options.dialogType} request failed: ${JSON.stringify(error)}`);
            finish(false);
          }
          LogUtils.info(TAG, `Connected to system dialog: ${elementName?.bundleName}`);
        },
        onDisconnect(elementName) {
          LogUtils.info(TAG, `Disconnected from system dialog: ${elementName?.bundleName}`);
        },
        onFailed(code) {
          LogUtils.error(TAG, `Connect system dialog failed: ${code}`);
          finish(false);
        }
      };

      try {
        connectionId = dialogContext.connectServiceExtensionAbility(want, connectOption) ?? -1;
        LogUtils.info(TAG, `Connect system dialog start, connectionId=${connectionId}`);
      } catch (error) {
        LogUtils.error(TAG, `Connect system dialog exception: ${JSON.stringify(error)}`);
        finish(false);
      }
    });
  }
}
