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

import notification from '@ohos.notificationManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import type common from '@ohos.app.ability.common';
import { Action, PACKAGE_NAME } from '@ohos/common/src/main/ets/const/update_const';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { INotify } from '@ohos/common/src/main/ets/manager/UpgradeInterface';

/**
 * 通知辅助者
 *
 * @since 2022-06-05
 */
export class NotificationHelper implements INotify {
  /**
   * 跳转信息--跳转到搜包页面
   */
  private checkWantAgentInfo = {
    wants: [{
              bundleName: PACKAGE_NAME,
              abilityName: 'ServiceExtAbility',
              action: Action.NOTIFICATION_CHECK
            }],
    operationType: wantAgent.OperationType.START_ABILITY,
    requestCode: 0,
    wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG],
  };

  /**
   * 跳转信息--下载中拉起界面
   */
  private downloadingWantAgentInfo = {
    wants: [{
              bundleName: PACKAGE_NAME,
              abilityName: 'ServiceExtAbility',
              action: Action.NOTIFICATION_DETAIL
            }],
    operationType: wantAgent.OperationType.START_ABILITY,
    requestCode: 0,
    wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG],
  };

  /**
   * 下载进度通知
   *
   * @param version 版本号
   * @param progress 进度
   * @param context 上下文
   */
  async showDownloading(version, progress, context): Promise<void> {
    let templateName: string = 'downloadTemplate';
    if (!globalThis.isSupportTemplate) {
      globalThis.isSupportTemplate = await notification.isSupportTemplate(templateName).catch(err => {
        this.logError('showDownloading isSupportTemplate failed because ' + JSON.stringify(err));
        return false;
      });
    }
    if (!globalThis.isSupportTemplate) {
      this.logError('showDownloading is not supportTemplate');
      return;
    }
    var notificationRequest = {
      content: {
        contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: await context.resourceManager.getString($r('app.string.software_update').id),
          text: await context.resourceManager.getString($r('app.string.software_download_progress').id)
        },
      },
      template: {
        name: 'downloadTemplate',
        data: {
          title: await context.resourceManager.getString($r('app.string.software_download_progress').id),
          fileName: version,
          progressValue: progress
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.downloadingWantAgentInfo),
      id: 5,
      label: '111',
      slotType: notification.SlotType.SERVICE_INFORMATION,
      deliveryTime: new Date().getTime()
    }
    await notification.publish(notificationRequest).catch((err) => {
      this.logError('showDownloading notification publish failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 下载进度通知
   *
   * @param version 版本号
   * @param progress 进度
   * @param context 上下文
   */
  async showInstalling(version, progress, context): Promise<void> {
    let templateName: string = 'installTemplate';
    if (!globalThis.isSupportTemplate) {
      globalThis.isSupportTemplate = await notification.isSupportTemplate(templateName).catch(err => {
        this.logError('showInstalling isSupportTemplate failed because ' + JSON.stringify(err));
        return false;
      });
    }
    if (!globalThis.isSupportTemplate) {
      this.logError('showInstalling is not supportTemplate');
      return;
    }
    var notificationRequest = {
      content: {
        contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: await context.resourceManager.getString($r('app.string.software_update').id),
          text: await context.resourceManager.getString($r('app.string.software_install_progress').id)
        },
      },
      template: {
        name: 'installTemplate',
        data: {
          title: await context.resourceManager.getString($r('app.string.software_install_progress').id),
          fileName: version,
          progressValue: progress
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.downloadingWantAgentInfo),
      id: 5,
      label: '111',
      slotType: notification.SlotType.SERVICE_INFORMATION,
      deliveryTime: new Date().getTime()
    }
    await notification.publish(notificationRequest).catch((err) => {
      this.logError('showInstalling publish failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 弹安装失败通知
   *
   * @param context 实上下文
   */
  async showUpgradeFailed(versionName: string, context: common.Context): Promise<void> {
    let request = {
      content: {
        contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: await context.resourceManager.getString($r('app.string.install_fail_message').id),
          text: versionName
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.checkWantAgentInfo),
      id: 3,
      slotType: notification.SlotType.SERVICE_INFORMATION
    }
    await notification.publish(request).then(() => {
      this.logInfo('showUpgradeFailed publish promise success.');
    }).catch((err) => {
      this.logError('showUpgradeFailed publish promise failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 弹安装成功通知
   *
   * @param context 实上下文
   */
  async showUpgradeSuccess(versionName: string, context: common.Context): Promise<void> {
    let request = {
      content: {
        contentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: await context.resourceManager.getString($r('app.string.install_success_message').id),
          text: versionName
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.checkWantAgentInfo),
      id: 4,
      slotType: notification.SlotType.SERVICE_INFORMATION
    }
    await notification.publish(request).then(() => {
      this.logInfo('showUpgradeSuccess publish promise success.');
    }).catch((err) => {
      this.logError('showUpgradeSuccess publish promise failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 取消所有通知
   */
  async cancelAll(): Promise<void> {
    await notification.cancelAll().then(() => {
      this.logInfo('cancelAll notification success');
    });
  }

  /**
   * 检查notification服务是否启动
   */
  async isServiceReady(): Promise<void> {
    const retryTimes: number = 10;
    let count: number = 0;
    let isReady: boolean = false;
    while (count < retryTimes) {
      try {
        await notification.isDistributedEnabled().then(() => {
          this.logInfo('notification service is ready');
          isReady = true;
        });
        if (isReady) {
          break;
        }
        count++;
        await new Promise<void>((resolve)) => setTimeout(() => resolve(), 1000));
        this.logError('notification service is not ready');
      } catch (err) {
        count++;
        continue;
      }
    };
  }

  /**
   * info级别日志打印
   *
   * @param message 日志内容
   */
  logInfo(message: string): void {
    LogUtils.info('NotificationHelper', message);
  }

  /**
   * error级别日志打印
   *
   * @param message 日志内容
   */
  logError(message: string): void {
    LogUtils.error('NotificationHelper', message);
  }
}