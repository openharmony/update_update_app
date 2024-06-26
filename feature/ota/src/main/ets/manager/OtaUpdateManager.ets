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

import type common from '@ohos.app.ability.common';
import update from '@ohos.update';
import type Want from '@ohos.app.ability.Want';
import { ErrorCode } from '@ohos/common/src/main/ets/const/update_const';
import type { OtaStatus, UpgradeData, } from '@ohos/common/src/main/ets/const/update_const';
import { UpdateState, UpgradeCallResult, } from '@ohos/common/src/main/ets/const/update_const';
import type { Message } from '@ohos/common/src/main/ets/manager/UpdateManager';
import {
  UpdateManager,
  MessageQueue,
  OtaStatusHolder,
} from '@ohos/common/src/main/ets/manager/UpdateManager';
import { DeviceUtils } from '@ohos/common/src/main/ets/util/DeviceUtils';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import type { BaseState } from '../manager/StateManager';
import { StateManager } from '../manager/StateManager';
import { NotificationManager } from '../notify/NotificationManager';
import VersionUtils from '../util/VersionUtils';
import { UpgradeAdapter } from '../UpgradeAdapter';
import { FormatUtils } from '@ohos/common/src/main/ets/util/FormatUtils';

/**
 * 升级接口管理类
 *
 * @since 2022-06-05
 */
export class OtaUpdateManager {
  private static readonly KEY = 'EventInfo';
  private _updateStatus: number;
  private _downloadProgress: number;
  private lastStatus: number;
  private stateObj: BaseState;
  private otaStatusHolder: OtaStatusHolder;
  private updateManager: UpdateManager;
  private messageQueue: MessageQueue;

  /**
   * 单例--升级管理类对象实例
   *
   * @return 升级管理类对象实例
   */
  static getInstance(): OtaUpdateManager {
    return globalThis.otaUpdateManager ?? new OtaUpdateManager();
  }

  private constructor() {
    this.log('OtaUpdateManager init.');
    globalThis.otaUpdateManager = this;
    this.otaStatusHolder = new OtaStatusHolder();
    this.messageQueue = new MessageQueue(this.handleMessage.bind(this));

    this.updateManager = new UpdateManager();
    this.updateManager.bind(update.BusinessSubType.FIRMWARE, this.notifyUpdateStatusRemote.bind(this));
  }

  /**
   * 取升级状态
   *
   * @return resolve 状态/reject 错误信息
   */
  async getOtaStatus(): Promise<UpgradeData<OtaStatus>> {
    return new Promise((resolve, reject) => {
      this.updateManager.getOtaStatus().then((result: UpgradeData<OtaStatus>) => {
        if (result?.callResult === UpgradeCallResult.OK) {
          this.refreshState(result?.data);
        }
        resolve(result);
      });
    });
  }

  /**
   * 从due数据库取新版本信息
   *
   * @return resolve 新版本信息/reject 错误信息
   */
  async getNewVersion(): Promise<UpgradeData<update.NewVersionInfo>> {
    return new Promise((resolve, reject) => {
      this.updateManager.getNewVersion().then((result: UpgradeData<update.NewVersionInfo>) => {
        if (result?.callResult === UpgradeCallResult.OK) {
          globalThis.cachedNewVersionInfo = result?.data;
          resolve(result);
        } else {
          resolve(result);
        }
      });
    });
  }

  /**
   * 获取新版本描述文件
   *
   * @return 新版本描述文件
   */
  async getNewVersionDescription(): Promise<UpgradeData<Array<update.ComponentDescription>>> {
    let versionDigest: string = await VersionUtils.getNewVersionDigest();
    return this.updateManager.getNewVersionDescription(versionDigest, update.DescriptionFormat.STANDARD,
      DeviceUtils.getSystemLanguage());
  }

  /**
   * 获取当前版本升级日志
   *
   * @return 当前版本描述文件
   */
  async getCurrentVersionDescription(): Promise<UpgradeData<Array<update.ComponentDescription>>> {
    return this.updateManager.getCurrentVersionDescription(update.DescriptionFormat.STANDARD,
      DeviceUtils.getSystemLanguage());
  }

  /**
   * 从服务器取搜索新版本
   *
   * @return resolve 新版本信息/reject 错误信息
   */
  async checkNewVersion(): Promise<UpgradeData<update.CheckResult>> {
    return new Promise((resolve, reject) => {
      this.updateManager.checkNewVersion().then((result: UpgradeData<update.CheckResult>) => {
        if (result?.callResult === UpgradeCallResult.OK) {
          globalThis.cachedNewVersionInfo = result?.data?.newVersionInfo;
          resolve(result);
        } else {
          resolve(result);
        }
      });
    });
  }

  /**
   * 升级
   *
   * @param order 安装指令
   */
  async upgrade(order: update.Order = update.Order.INSTALL_AND_APPLY): Promise<void> {
    let versionDigest: string = await VersionUtils.getNewVersionDigest();
    return new Promise((resolve, reject) => {
      this.updateManager.upgrade(versionDigest, order).then(()=> {
        resolve();
      }).catch(err => {
        let status: OtaStatus = {
          status: order === update.Order.APPLY ? UpdateState.INSTALL_SUCCESS : UpdateState.DOWNLOAD_SUCCESS,
          percent: 100,
          endReason: err?.data?.[0]?.errorCode?.toString() || ErrorCode.DEFAULT_ERROR,
        };
        this.notifyUpdateStatus(status, globalThis.abilityContext);
        this.logError('upgrade err:' + JSON.stringify(err));
        reject(err);
      });
    });
  }

  /**
   * 下载
   *
   * @param downloadNetwork 下载网络类型，默认为wifi
   */
  async download(downloadNetwork: update.NetType = update.NetType.WIFI): Promise<void> {
    UpgradeAdapter.getInstance().getNotifyInstance()?.cancelAll();
    let versionDigest: string = await VersionUtils.getNewVersionDigest();
    this.setDownloadProgress(0);
    this.updateManager.download(versionDigest, downloadNetwork, update.Order.DOWNLOAD)
      .catch(err => {
        let status: OtaStatus = {
          status: UpdateState.CHECK_SUCCESS,
          percent: 0,
          endReason: err?.data?.[0]?.errorCode?.toString() || '',
        };
        this.notifyUpdateStatus(status, globalThis.abilityContext);
      });
  }

  /**
   * 继续下载
   */
  async resumeDownload(): Promise<void>  {
    let versionDigest: string = await VersionUtils.getNewVersionDigest();
    this.setUpdateState(UpdateState.DOWNLOADING);
    this.updateManager.resumeDownload(versionDigest, update.NetType.WIFI).then(result => {
      this.log('resumeDownload result:' + JSON.stringify(result));
    }).catch(err => {
      let status: OtaStatus = {
        status: UpdateState.DOWNLOAD_PAUSE,
        percent: this.getDownloadProgress(),
        endReason: err?.data?.[0]?.errorCode?.toString() || '',
      };
      this.notifyUpdateStatus(status, globalThis.abilityContext);
    });
  }

  /**
   * 取消升级
   */
  async cancel(): Promise<void>  {
    this.setUpdateState(UpdateState.CHECK_SUCCESS);
    this.setDownloadProgress(0);
    await UpgradeAdapter.getInstance().getNotifyInstance()?.cancelAll();
    this.updateManager.cancel();
  }

  /**
   * 取当前版本数据
   *
   * @return resolve 当前版本信息/reject 错误信息
   */
  async getCurrentVersionInfo(): Promise<UpgradeData<update.CurrentVersionInfo>> {
    return this.updateManager.getCurrentVersionInfo();
  }

  /**
   * 取升级状态缓存数据
   *
   * @return 升级状态
   */
  getUpdateState(): number {
    return this._updateStatus;
  }

  /**
   * 设置升级状态缓存数据
   *
   * @param value 状态
   */
  setUpdateState(value): void {
    if (this._updateStatus !== Number(value) && value !== undefined && value !== null) {
      this._updateStatus = Number(value);
      AppStorage.Set('updateStatus', this._updateStatus);
    }
  }

  /**
   * 取升级进度
   *
   * @return 升级进度
   */
  getDownloadProgress(): number {
    return this._downloadProgress;
  }

  /**
   * 设置进度
   *
   * @param value 进度
   */
  setDownloadProgress(value): void {
    if (this._downloadProgress !== value && value !== undefined && value !== null) {
      this._downloadProgress = value;
      AppStorage.Set('downloadProgress', this._downloadProgress);
    }
  }

  /**
   * 取状态对象
   *
   * @param status 状态
   */
  getStateObj(status: number): BaseState {
    if (this.stateObj?.state === status) {
      return this.stateObj;
    } else {
      return StateManager.createInstance(status);
    }
  }

  private refreshState(otaStatus: OtaStatus): void {
    if (!this.stateObj || this.lastStatus !== otaStatus.status) {
      this.stateObj = StateManager.createInstance(otaStatus);
    }
    this.stateObj.refresh(otaStatus);
    this.lastStatus = otaStatus.status;
    this.setUpdateState(this.stateObj.state);
    this.setDownloadProgress(this.stateObj.percent);
  }

  /**
   * 状态刷新
   *
   * @param otaStatus 状态
   */
  private async notifyUpdateStatusRemote(eventInfo: update.EventInfo): Promise<void> {
    this.log(`notifyUpdateStatusRemote ${JSON.stringify(eventInfo)}`);
    let message: Message = {
      context: globalThis.extensionContext || globalThis.abilityContext,
      eventInfo: eventInfo,
    };

    this.messageQueue.execute(message);
  }

  private async handleMessage(context: common.Context, eventInfo: update.EventInfo): Promise<void> {
    let otaStatus: OtaStatus = this.getFormattedOtaStatus(eventInfo);
    if (this.isTerminalState(otaStatus)) {
      globalThis.lastVersionName = await VersionUtils.obtainNewVersionName(eventInfo?.taskBody);
    }
    let versionDigest: string = eventInfo?.taskBody?.versionDigestInfo?.versionDigest ?? '';
    await this.notifyUpdateStatus(otaStatus, context, versionDigest, eventInfo?.eventId);
  }

  private async notifyUpdateStatus(otaStatus: OtaStatus, context: common.Context, verDigest?: string,
    eventId?: update.EventId): Promise<void> {
    this.log('notifyUpdateStatus:' + JSON.stringify(otaStatus));
    this.refreshState(otaStatus);

    if (!this.otaStatusHolder.isStatusChangedAndRefresh(otaStatus, eventId)) {
      LogUtils.warn('UpdateManager', 'notifyUpdateStatus is repeating, abandon.');
      return;
    }
    if (!globalThis.cachedNewVersionInfo && !this.isTerminalState(otaStatus)) {
      await this.getNewVersion();
    }

    await StateManager.createInstance(otaStatus).notify(context, eventId);
  }

  private isTerminalState(otaStatus: OtaStatus): boolean {
    let status = otaStatus?.status ?? UpdateState.INIT;
    if (status === UpdateState.INIT || status === UpdateState.DOWNLOAD_FAILED ||
      status === UpdateState.INSTALL_FAILED || status === UpdateState.UPGRADE_SUCCESS ||
      status === UpdateState.UPGRADE_FAILED) {
      return true;
    }
    return false;
  }

  /**
   * 收到推送消息
   *
   * @param otaStatus 状态数据
   */
  async onReceivedUpdateServiceMessage(eventInfo: update.EventInfo): Promise<void> {
    this.log('receives from onReceivedUpdateServiceMessage:' + JSON.stringify(eventInfo));
    let message: Message = {
      context: globalThis.extensionContext,
      eventInfo: eventInfo,
    };
    await this.messageQueue.execute(message);
  }

  /**
   * 收到page推送消息
   *
   * @param otaStatus 状态数据
   */
  async onReceivedUpdatePageMessage(otaStatus: OtaStatus): Promise<void> {
    this.log('receives from onReceivedUpdatePageMessage:' + JSON.stringify(otaStatus));
    this.notifyUpdateStatus(otaStatus, globalThis.abilityContext);
  }

  /**
   * 处理推送消息
   *
   * @param want 推送数据
   * @param context 上下文
   */
  public async handleWant(want: Want, context: common.Context): Promise<void> {
    let action: string = want?.action ?? '';
    if (await NotificationManager.handleAction(action, context)) {
      this.log('handleWant:' + FormatUtils.stringify(want));
      return;
    }
    let eventInfo = this.wantParser(want);
    this.log('handleWant:' + ' eventInfo is ${FormatUtils.stringify(eventInfo)}');
    if (!eventInfo?.eventId) {
      this.log('eventInfo?.eventId is null');
      return;
    }
    await this.onReceivedUpdateServiceMessage(eventInfo);
  }

  /**
   * 是否升级终止
   *
   * @return 是否升级终止
   */
  public isTerminal(): boolean {
    return this.isTerminalState(this.stateObj?.otaStatus);
  }

  private wantParser(want: Want): update.EventInfo {
    let eventInfo: update.EventInfo = want?.parameters?.[OtaUpdateManager.KEY] as update.EventInfo;
    if (typeof eventInfo === 'string') {
      eventInfo = FormatUtils.parseJson(eventInfo);
    }
    return eventInfo;
  }

  private log(message: string): void {
    LogUtils.log('UpdateManager', message);
  }

  private logError(message: string): void {
    LogUtils.error('UpdateManager', message);
  }

  /**
   * 通过eventInfo获取OtaStatus
   * 同时对status、percent数据进行调整
   *
   * @param eventInfo 事件
   * @return OtaStatus 实例
   */
  private getFormattedOtaStatus(eventInfo: update.EventInfo): OtaStatus {
    let endReason: string = eventInfo.taskBody?.errorMessages?.[0]?.errorCode?.toString();
    let otaStatus: OtaStatus = {
      status: eventInfo.taskBody?.status,
      percent: eventInfo.taskBody?.progress,
      endReason: !endReason || endReason === '0' ? null : endReason,
    };
    if (!otaStatus.status) {
      otaStatus.status = this.getUpdateStateFromEventId(eventInfo.eventId);
    }
    return otaStatus;
  }

  private getUpdateStateFromEventId(eventId: update.EventId): UpdateState {
    let status: UpdateState;
    switch (eventId) {
      case update.EventId.EVENT_TASK_RECEIVE:
        status = UpdateState.CHECK_SUCCESS;
        break;
      case update.EventId.EVENT_TASK_CANCEL:
        status = UpdateState.INIT;
        break;
      case update.EventId.EVENT_DOWNLOAD_START:
        status = UpdateState.DOWNLOADING;
        break;
      case update.EventId.EVENT_DOWNLOAD_SUCCESS:
        status = UpdateState.DOWNLOAD_SUCCESS;
        break;
      case update.EventId.EVENT_DOWNLOAD_FAIL:
        status = UpdateState.DOWNLOAD_FAILED;
        break;
      case update.EventId.EVENT_UPGRADE_SUCCESS:
        status = UpdateState.UPGRADE_SUCCESS;
        break;
      case update.EventId.EVENT_UPGRADE_FAIL:
        status = UpdateState.UPGRADE_FAILED;
        break;
      default:
        break;
    }
    return status;
  }
}