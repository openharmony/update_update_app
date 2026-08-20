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
import type UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { AlertDialog } from '@kit.ArkUI';
import { MAIN_ABILITY_NAME, PACKAGE_NAME } from '@ohos/common/src/main/ets/const/update_const';
import { DeviceUtils } from '@ohos/common/src/main/ets/util/DeviceUtils';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { UpdateUtils } from '@ohos/common/src/main/ets/util/UpdateUtils';
import { SceneBoardDialogType } from 'ota/src/main/ets/notify/SceneBoardDialogManager';

const TAG = 'UpdateSystemDialogPage';
const storage = LocalStorage.getShared();

@Entry(storage)
@Component
struct UpdateSystemDialogPage {
  private session?: UIExtensionContentSession = storage?.get('session') as UIExtensionContentSession;
  private context = getContext(this) as common.UIExtensionContext;
  private dialogType: string = (storage?.get('dialogType') as string) ?? '';
  private actionHandled: boolean = false;

  private downloadDialogController = new CustomDialogController({
    builder: AlertDialog({
      primaryTitle: $r('app.string.software_update'),
      content: $r('app.string.desktop_download_dialog_content'),
      primaryButton: {
        value: $r('app.string.later'),
        action: () => {
          this.closeSession();
        }
      },
      secondaryButton: {
        value: $r('app.string.btn_download'),
        action: () => {
          this.startDownload();
        }
      }
    }),
    alignment: DeviceUtils.getDialogLocation(),
    offset: {
      dx: '0vp',
      dy: DeviceUtils.getDialogOffsetY()
    },
    autoCancel: false,
    cancel: () => {
      this.closeSession();
    }
  });

  aboutToAppear(): void {
    LogUtils.info(TAG, `aboutToAppear, dialogType=${this.dialogType}`);
    if (this.dialogType === SceneBoardDialogType.DOWNLOAD_REMINDER) {
      this.downloadDialogController.open();
      return;
    }
    LogUtils.error(TAG, `Unsupported dialog type: ${this.dialogType}`);
    this.closeSession();
  }

  private startDownload(): void {
    if (this.actionHandled) {
      return;
    }
    this.actionHandled = true;
    UpdateUtils.startAbility(this.context, {
      bundleName: PACKAGE_NAME,
      abilityName: MAIN_ABILITY_NAME,
      uri: 'pages/newVersion',
      parameters: {
        autoDownload: true
      }
    });
    this.closeSession();
  }

  private closeSession(): void {
    try {
      this.session?.terminateSelf();
    } catch (error) {
      LogUtils.error(TAG, `Terminate system dialog session failed: ${JSON.stringify(error)}`);
    }
  }

  build() {
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor('#00000000')
  }
}
