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
import {
  BusinessError,
  Action,
  PACKAGE_NAME,
  NIGHT_UPGRADE_START,
  NIGHT_UPGRADE_END
} from '@ohos/common/src/main/ets/const/update_const';
import { FormatUtils } from '@ohos/common/src/main/ets/util/FormatUtils';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { INotify } from '@ohos/common/src/main/ets/manager/UpgradeInterface';

/**
 * 通知辅助者
 *
 * @since 2022-06-05
 */
export class NotificationHelper implements INotify {
  /**
   * 下载提醒通知
   *
   * @param versionName 版本号
   * @param context 上下文
   */
  async showDownloadReminder(versionName: string, context: common.Context): Promise<void> {
    let request: notification.NotificationRequest = {
      content: {
        notificationContentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: await context.resourceManager.getString($r('app.string.software_update').id),
          text: await context.resourceManager.getString($r('app.string.desktop_download_dialog_content').id),
          additionalText: versionName
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.downloadingWantAgentInfo),
      id: 5,
      isAlertOnce: true,
      notificationSlotType: notification.SlotType.SERVICE_INFORMATION,
      deliveryTime: new Date().getTime()
    };
    await notification.publish(request).then(() => {
      this.logInfo('showDownloadReminder publish promise success.');
    }).catch((err: BusinessError) => {
      this.logError('showDownloadReminder publish promise failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 跳转信息--跳转到搜包页面
   */
  private checkWantAgentInfo: wantAgent.WantAgentInfo = {
    wants: [{
              bundleName: PACKAGE_NAME,
              abilityName: 'ServiceExtAbility',
              action: Action.NOTIFICATION_CHECK
            }],
    actionType: wantAgent.OperationType.START_ABILITY,
    requestCode: 0,
    wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG],
  };

  /**
   * 跳转信息--下载中拉起界面
   */
  private downloadingWantAgentInfo: wantAgent.WantAgentInfo = {
    wants: [{
              bundleName: PACKAGE_NAME,
              abilityName: 'ServiceExtAbility',
              action: Action.NOTIFICATION_DETAIL
            }],
    actionType: wantAgent.OperationType.START_ABILITY,
    requestCode: 0,
    wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG],
  };

  /**
   * 跳转信息--夜间升级直接安装
   */
  private installWantAgentInfo: wantAgent.WantAgentInfo = {
    wants: [{
              bundleName: PACKAGE_NAME,
              abilityName: 'ServiceExtAbility',
              action: Action.NOTIFICATION_INSTALL
            }],
    actionType: wantAgent.OperationType.START_ABILITY,
    requestCode: 0,
    wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG],
  };

  /**
   * 跳转信息--夜间升级设置页
   */
  private settingsWantAgentInfo: wantAgent.WantAgentInfo = {
    wants: [{
              bundleName: PACKAGE_NAME,
              abilityName: 'ServiceExtAbility',
              action: Action.NOTIFICATION_SETTINGS
            }],
    actionType: wantAgent.OperationType.START_ABILITY,
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
  async showDownloading(version: string, progress: number, context: common.Context): Promise<void> {
    let templateName: string = 'downloadTemplate';
    let downloadText: string = await context.resourceManager.getString($r('app.string.software_download_progress').id);
    let downloadTitle: string = downloadText + '：' + progress + '%';
    this.logInfo('showDownloading start, version=' + version + ', progress=' + progress);
    if (!globalThis.isSupportTemplate) {
      globalThis.isSupportTemplate = await notification.isSupportTemplate(templateName).catch((err: BusinessError) => {
        this.logError('showDownloading isSupportTemplate failed because ' + JSON.stringify(err));
        return false;
      });
    }
    if (!globalThis.isSupportTemplate) {
      this.logError('showDownloading is not supportTemplate');
      return;
    }
    let notificationRequest: notification.NotificationRequest = {
      content: {
        notificationContentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: downloadTitle,
          text: version
        },
      },
      template: {
        name: 'downloadTemplate',
        data: {
          title: downloadTitle,
          fileName: version,
          progressValue: progress
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.downloadingWantAgentInfo),
      id: 5,
      label: '111',
      isAlertOnce: true,
      notificationSlotType: notification.SlotType.SERVICE_INFORMATION,
      deliveryTime: new Date().getTime()
    }
    await notification.publish(notificationRequest).then(() => {
      this.logInfo(`showDownloading publish promise success.`);
    }).catch((err: BusinessError) => {
      this.logError('showDownloading notification publish failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 下载暂停通知
   *
   * @param version 版本号
   * @param progress 进度
   * @param context 上下文
   */
  async showDownloadPaused(version: string, progress: number, context: common.Context): Promise<void> {
    let pausedText: string = await context.resourceManager.getString($r('app.string.download_status_download_pause').id);
    let request: notification.NotificationRequest = {
      content: {
        notificationContentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: pausedText,
          text: version
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.downloadingWantAgentInfo),
      id: 5,
      label: '111',
      isAlertOnce: true,
      notificationSlotType: notification.SlotType.SERVICE_INFORMATION,
      deliveryTime: new Date().getTime()
    }
    await notification.publish(request).then(() => {
      this.logInfo('showDownloadPaused publish promise success.');
    }).catch((err: BusinessError) => {
      this.logError('showDownloadPaused publish promise failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 升级包校验失败通知
   *
   * @param context 上下文
   */
  async showVerifyFailed(context: common.Context): Promise<void> {
    let request: notification.NotificationRequest = {
      content: {
        notificationContentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: await context.resourceManager.getString($r('app.string.download_verify_fail_notification_title').id),
          text: await context.resourceManager.getString($r('app.string.download_verify_fail_notification_content').id)
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.checkWantAgentInfo),
      id: 5,
      isAlertOnce: true,
      notificationSlotType: notification.SlotType.SERVICE_INFORMATION,
      deliveryTime: new Date().getTime()
    };
    await notification.publish(request).then(() => {
      this.logInfo('showVerifyFailed publish promise success.');
    }).catch((err: BusinessError) => {
      this.logError('showVerifyFailed publish promise failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 下载进度通知
   *
   * @param version 版本号
   * @param progress 进度
   * @param context 上下文
   */
  async showInstalling(version: string, progress: number, context: common.Context): Promise<void> {
    let templateName: string = 'installTemplate';
    let installText: string = await context.resourceManager.getString($r('app.string.software_install_progress').id);
    let installProgressText: string = installText + ' ' + progress + '%';
    if (!globalThis.isSupportTemplate) {
      globalThis.isSupportTemplate = await notification.isSupportTemplate(templateName).catch((err: BusinessError) => {
        this.logError('showInstalling isSupportTemplate failed because ' + JSON.stringify(err));
        return false;
      });
    }
    if (!globalThis.isSupportTemplate) {
      this.logError('showInstalling is not supportTemplate');
      return;
    }
    let notificationRequest: notification.NotificationRequest = {
      content: {
        notificationContentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: await context.resourceManager.getString($r('app.string.software_update').id),
          text: installProgressText
        },
      },
      template: {
        name: 'installTemplate',
        data: {
          title: installText,
          fileName: installProgressText,
          progressValue: progress
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.downloadingWantAgentInfo),
      id: 5,
      label: '111',
      isAlertOnce: true,
      notificationSlotType: notification.SlotType.SERVICE_INFORMATION,
      deliveryTime: new Date().getTime()
    }
    await notification.publish(notificationRequest).catch((err: BusinessError) => {
      this.logError('showInstalling publish failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 弹安装失败通知
   *
   * @param context 实上下文
   */
  async showUpgradeFailed(versionName: string, context: common.Context): Promise<void> {
    let request: notification.NotificationRequest = {
      content: {
        notificationContentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: await context.resourceManager.getString($r('app.string.install_fail_message').id),
          text: versionName
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.checkWantAgentInfo),
      id: 3,
      notificationSlotType: notification.SlotType.SERVICE_INFORMATION
    }
    await notification.publish(request).then(() => {
      this.logInfo('showUpgradeFailed publish promise success.');
    }).catch((err: BusinessError) => {
      this.logError('showUpgradeFailed publish promise failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 弹安装成功通知
   *
   * @param context 实上下文
   */
  async showUpgradeSuccess(versionName: string, context: common.Context): Promise<void> {
    let request: notification.NotificationRequest = {
      content: {
        notificationContentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: await context.resourceManager.getString($r('app.string.install_success_message').id),
          text: versionName
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.checkWantAgentInfo),
      id: 4,
      notificationSlotType: notification.SlotType.SERVICE_INFORMATION
    }
    await notification.publish(request).then(() => {
      this.logInfo('showUpgradeSuccess publish promise success.');
    }).catch((err: BusinessError) => {
      this.logError('showUpgradeSuccess publish promise failed because ' + JSON.stringify(err));
    });
  }

  /**
   * 夜间升级设置通知
   *
   * @param context 实际上下文
   */
  async showNightUpgradeNotice(context: common.Context): Promise<void> {
    let description: string = await context.resourceManager.getString($r('app.string.setting_auto_update_description').id);
    let detailText: string = await context.resourceManager.getString($r('app.string.detail_info').id);
    let installText: string = await context.resourceManager.getString($r('app.string.btn_install_now').id);
    let request: notification.NotificationRequest = {
      content: {
        notificationContentType: notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: await context.resourceManager.getString($r('app.string.setting_auto_update_title').id),
          text: FormatUtils.formatStr(description, FormatUtils.getDateRangeFormat(NIGHT_UPGRADE_START, NIGHT_UPGRADE_END))
        }
      },
      wantAgent: await wantAgent.getWantAgent(this.downloadingWantAgentInfo),
      actionButtons: [
        {
          title: detailText,
          wantAgent: await wantAgent.getWantAgent(this.downloadingWantAgentInfo)
        },
        {
          title: installText,
          wantAgent: await wantAgent.getWantAgent(this.installWantAgentInfo)
        }
      ],
      id: 6,
      notificationSlotType: notification.SlotType.SERVICE_INFORMATION
    }
    await notification.publish(request).then(() => {
      this.logInfo('showNightUpgradeNotice publish promise success.');
    }).catch((err: BusinessError) => {
      this.logError('showNightUpgradeNotice publish promise failed because ' + JSON.stringify(err));
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
        await new Promise<void>((resolve) => setTimeout(() => resolve(), 1000));
        this.logError('notification service is not ready');
      } catch (err) {
        count++;
        this.logError('notification service throw abnormal');
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
