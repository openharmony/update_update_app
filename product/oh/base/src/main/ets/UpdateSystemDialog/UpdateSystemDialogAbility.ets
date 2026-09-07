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

import UIExtensionAbility from '@ohos.app.ability.UIExtensionAbility';
import type Want from '@ohos.app.ability.Want';
import type UIExtensionContentSession from '@ohos.app.ability.UIExtensionContentSession';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';

const TAG = 'UpdateSystemDialogAbility';

export default class UpdateSystemDialogAbility extends UIExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    LogUtils.info(TAG, `onSessionCreate: ${JSON.stringify(want?.parameters)}`);
    const storage = new LocalStorage();
    storage.setOrCreate('session', session);
    storage.setOrCreate('dialogType', (want?.parameters?.dialogType as string) ?? '');
    try {
      session.loadContent('UpdateSystemDialog/pages/UpdateSystemDialogPage', storage);
    } catch (error) {
      LogUtils.error(TAG, `Load system dialog content failed: ${JSON.stringify(error)}`);
      try {
        session.terminateSelf();
      } catch (terminateError) {
        LogUtils.error(TAG, `Terminate invalid session failed: ${JSON.stringify(terminateError)}`);
      }
      return;
    }
    try {
      session.setWindowBackgroundColor('#00000000');
    } catch (error) {
      LogUtils.warn(TAG, `Set transparent background failed: ${JSON.stringify(error)}`);
    }
  }
}
