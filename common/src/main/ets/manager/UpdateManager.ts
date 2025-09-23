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
import { PACKAGE_NAME, UpdateState, UpgradeCallResult, } from '../const/update_const';
import type { BusinessError, OtaStatus, UpgradeData} from '../const/update_const';
import { LogUtils } from '../util/LogUtils';

/**
 * 方法超时控制装饰器
 *
 * @param timeout 超时事件ms
 */
export function enableTimeOutCheck<T>(timeout?: number): MethodDecorator {
  const TIME = 30000;
  let realTimeout: number = timeout ?? TIME;
  return function inner(target: Object, propertyKey: string, descriptor: PropertyDescriptor): void {
    const original = descriptor.value;
    descriptor.value = function (...args): Promise<unknown> {
      return new Promise((resolve, reject) => {
        let upgradeData: UpgradeData<T> = {
          callResult: UpgradeCallResult.OK,
        };
        const requestTimeout = setTimeout(() => {
          upgradeData.callResult = UpgradeCallResult.TIME_OUT;
          resolve(upgradeData);
        }, realTimeout);
        let result: Promise<T>;
        try {
          result = original.call(this, ...args);
        } catch (error) {
          LogUtils.error('UpdateManager', 'error: ' + JSON.stringify(error));
          result = null;
        }
        if (!result) {
          clearTimeout(requestTimeout);
          upgradeData.callResult = UpgradeCallResult.ERROR;
          resolve(upgradeData); // 不处理错误
          return;
        }
        result.then(innerRes => {
          clearTimeout(requestTimeout);
          resolve(innerRes);
        }).catch((err: BusinessError) => {
          LogUtils.error('UpdateManager', 'err: ' + JSON.stringify(err));
          clearTimeout(requestTimeout);
          upgradeData.callResult = UpgradeCallResult.ERROR;
          upgradeData.error = err;
          resolve(upgradeData); // 不处理错误
        });
      });
    };
  };
}

export interface IUpdate {
  getOtaStatus(): Promise<UpgradeData<OtaStatus>>;
  getNewVersion(): Promise<UpgradeData<update.NewVersionInfo>>;
  getNewVersionDescription(descVersionDigest: string, descFormat: update.DescriptionFormat,
    descLanguage: string): Promise<UpgradeData<Array<update.ComponentDescription>>>;
  getCurrentVersionDescription(descFormat: update.DescriptionFormat,
    descLanguage: string): Promise<UpgradeData<Array<update.ComponentDescription>>>;
  checkNewVersion(): Promise<UpgradeData<update.CheckResult>>;
  upgrade(upgradeVersionDigest: string, upgradeOrder: number): Promise<void>;
  download(downloadVersionDigest: string, downloadNetwork: number, downloadOrder: number): Promise<void>;
  cancel(): void;
  getCurrentVersionInfo(): Promise<UpgradeData<update.CurrentVersionInfo>>;
}

/**
 * 升级接口管理类
 *
 * @since 2022-06-05
 */
export class UpdateManager implements IUpdate {
  private otaUpdater: update.Updater;

  public constructor(subType: number, upgradeDeviceId?: string, deviceType?: number, packageName?: string) {
    let upgradeInfo: update.UpgradeInfo = {
      upgradeApp: packageName ?? PACKAGE_NAME,
      businessType: {
        vendor: update.BusinessVendor.PUBLIC,
        subType: subType
      }
    };
    try {
      this.otaUpdater = update.getOnlineUpdater(upgradeInfo);
    } catch (error) {
      LogUtils.error('UpdateManager', `getOnlineUpdater fail ${error?.code} ${error?.message}`);
    }
  }

  /**
   * 绑定UpdateService
   *
   * @param callback 回调
   */
  on(callback: update.UpgradeTaskCallback): void {
    if (!callback) {
      LogUtils.error('UpdateManager', 'on callback null');
      return;
    }
    let eventClassifyInfo: update.EventClassifyInfo = {
      eventClassify: update.EventClassify.TASK,
      extraInfo: ''
    }

    try {
      this.otaUpdater?.on(eventClassifyInfo, callback);
    } catch (error) {
      LogUtils.error('UpdateManager', `otaUpdater on fail ${error?.code} ${error?.message}`);
    }
  }

  /**
   * 取消绑定UpdateService
   *
   * @param callback 回调
   */
  off(callback: update.UpgradeTaskCallback): void {
    if (!callback) {
      LogUtils.error('UpdateManager', 'off callback null');
      return;
    }
    let eventClassifyInfo: update.EventClassifyInfo = {
      eventClassify: update.EventClassify.TASK,
      extraInfo: ''
    }

    try {
      this.otaUpdater?.off(eventClassifyInfo, callback);
    } catch (error) {
      LogUtils.error('UpdateManager', `otaUpdater off fail ${error?.code} ${error?.message}`);
    }
  }

  /**
   * 取升级状态
   *
   * @return resolve 状态/reject 错误信息
   */
  @enableTimeOutCheck()
  async getOtaStatus(): Promise<UpgradeData<OtaStatus>> {
    return new Promise((resolve, reject) => {
      this.otaUpdater?.getTaskInfo().then((result: update.TaskInfo) => {
        this.log(`getOtaStatus result is ${JSON.stringify(result)}`);
        let upgradeData: UpgradeData<OtaStatus> = {
          callResult: UpgradeCallResult.OK
        };
        let taskStatus = result?.existTask ? result?.taskBody?.status : UpdateState.INIT;
        let otaStatus: OtaStatus = {
          status: taskStatus,
          percent: result?.taskBody?.progress ?? 0,
          endReason: result?.taskBody?.errorMessages?.[0]?.errorCode?.toString()
        };
        upgradeData.data = otaStatus;
        resolve(upgradeData);
      }).catch((err: BusinessError) => {
        this.logError(`getOtaStatus error is ${JSON.stringify(err)}`);
        let upgradeData: UpgradeData<OtaStatus> = {
          callResult: UpgradeCallResult.ERROR,
          error: err
        };
        resolve(upgradeData);
      });
    });
  }

  /**
   * 从UpdateService数据库取新版本信息
   *
   * @return resolve 新版本信息/reject 错误信息
   */
  @enableTimeOutCheck()
  async getNewVersion(): Promise<UpgradeData<update.NewVersionInfo>> {
    return new Promise((resolve, reject) => {
      this.otaUpdater?.getNewVersionInfo().then((result: update.NewVersionInfo) => {
        this.log('getNewVersion result:' + JSON.stringify(result));
        let upgradeData: UpgradeData<update.NewVersionInfo> = {
          callResult: UpgradeCallResult.OK,
          data: result
        };
        resolve(upgradeData);
      }).catch((err: BusinessError) => {
        this.logError('getNewVersion result:' + JSON.stringify(err));
        let upgradeData: UpgradeData<update.NewVersionInfo> = {
          callResult: UpgradeCallResult.ERROR,
          error: err
        };
        resolve(upgradeData);
      });
    });
  }

  /**
   * 获取新版本描述文件
   *
   * @param descVersionDigest 版本摘要
   * @param descFormat 描述文件格式
   * @param descLanguage 描述文件语言
   * @return 新版本描述文件
   */
  @enableTimeOutCheck()
  async getNewVersionDescription(descVersionDigest: string, descFormat: update.DescriptionFormat,
    descLanguage: string): Promise<UpgradeData<Array<update.ComponentDescription>>> {
    let versionDigestInfo: update.VersionDigestInfo = {
      versionDigest: descVersionDigest, // 检测结果中的版本摘要信息
    };
    let descriptionOptions: update.DescriptionOptions = {
      format: descFormat,
      language: descLanguage
    };
    return new Promise((resolve, reject) => {
      this.otaUpdater?.getNewVersionDescription(versionDigestInfo,
        descriptionOptions).then((result: Array<update.ComponentDescription>) => {
        this.log('getNewVersionDescription result:' + JSON.stringify(result));
        let upgradeData: UpgradeData<Array<update.ComponentDescription>> = {
          callResult: UpgradeCallResult.OK,
          data: result
        };
        resolve(upgradeData);
      }).catch((err: BusinessError) => {
        this.logError('getNewVersionDescription err:' + JSON.stringify(err));
        let upgradeData: UpgradeData<Array<update.ComponentDescription>> = {
          callResult: UpgradeCallResult.ERROR,
          error: err
        };
        resolve(upgradeData);
      });
    });
  }

  /**
   * 获取当前版本升级日志
   *
   * @param descFormat 描述文件格式
   * @param descLanguage 描述文件语言
   * @return 当前版本描述文件
   */
  @enableTimeOutCheck()
  async getCurrentVersionDescription(descFormat: update.DescriptionFormat,
    descLanguage: string): Promise<UpgradeData<Array<update.ComponentDescription>>> {
    let options: update.DescriptionOptions = {
      format: descFormat,
      language: descLanguage
    };
    return new Promise((resolve, reject) => {
      this.otaUpdater?.getCurrentVersionDescription(options, (err, result) => {
        this.log('getCurrentVersionDescription result:' + JSON.stringify(result));
        let upgradeData: UpgradeData<Array<update.ComponentDescription>> = {
          callResult: UpgradeCallResult.OK,
          data: result,
          error: {
            data: [{ errorCode: err?.data?.[0]?.errorCode }]
          }
        };
        if (!result && err) {
          this.logError('getCurrentVersionDescription error is ${JSON.stringify(err)}');
          upgradeData.callResult = UpgradeCallResult.ERROR;
        }
        resolve(upgradeData);
      });
    });
  }

  /**
   * 从服务器取搜索新版本
   *
   * @return resolve 新版本信息/reject 错误信息
   */
  @enableTimeOutCheck()
  async checkNewVersion(): Promise<UpgradeData<update.CheckResult>> {
    return new Promise((resolve, reject) => {
      this.otaUpdater?.checkNewVersion().then((result: update.CheckResult) => {
        this.log('checkNewVersion result:' + JSON.stringify(result));
        let upgradeData: UpgradeData<update.CheckResult> = {
          callResult: UpgradeCallResult.OK,
          data: result,
        };
        if (!result?.isExistNewVersion || !result?.newVersionInfo) {
          upgradeData.callResult = UpgradeCallResult.ERROR;
        }
        resolve(upgradeData);
      }).catch((err: BusinessError) => {
        this.logError('checkNewVersion err:' + JSON.stringify(err));
        let upgradeData: UpgradeData<update.CheckResult> = {
          callResult: UpgradeCallResult.ERROR,
          error: err
        };
        resolve(upgradeData);
      });
    });
  }

  /**
   * 升级
   *
   * @param upgradeVersionDigest 版本摘要
   * @param upgradeOrder 升级命令
   * @return 调用结果
   */
  upgrade(upgradeVersionDigest: string, upgradeOrder: number): Promise<void> {
    return new Promise((resolve, reject) => {
      let versionDigestInfo: update.VersionDigestInfo = {
        versionDigest: upgradeVersionDigest
      };
      let upgradeOptions: update.UpgradeOptions = {
        order: upgradeOrder
      };
      this.otaUpdater?.upgrade(versionDigestInfo, upgradeOptions).then(() => {
        resolve();
      }).catch((err: BusinessError) => {
        this.logError('upgrade err:' + JSON.stringify(err));
        reject(err);
      });
    });
  }

  /**
   * 下载
   *
   * @param upgradeVersionDigest 版本摘要
   * @param downloadNetwork 下载网络
   * @param upgradeOrder 下载命令
   * @return 调用结果
   */
  download(downloadVersionDigest: string, downloadNetwork: number, downloadOrder: number): Promise<void> {
    return new Promise((resolve, reject) => {
      let versionDigestInfo: update.VersionDigestInfo = {
        versionDigest: downloadVersionDigest
      };
      let downloadOptions: update.DownloadOptions = {
        allowNetwork: downloadNetwork,
        order: downloadOrder
      };
      this.otaUpdater?.download(versionDigestInfo, downloadOptions).then(() => {
        this.log('download succeeded.');
        resolve();
      }).catch((err: BusinessError) => {
        this.logError('download err:' + JSON.stringify(err));
        reject(err);
      });
    });
  }

  /**
   * 继续下载
   *
   * @param upgradeVersionDigest 版本摘要
   * @param downloadNetwork 下载网络
   * @return 调用结果
   */
  resumeDownload(downloadVersionDigest: string, downloadNetwork: number): Promise<void> {
    return new Promise((resolve, reject) => {
      let versionDigestInfo: update.VersionDigestInfo = {
        versionDigest: downloadVersionDigest
      };

      let resumeDownloadOptions: update.ResumeDownloadOptions = {
        allowNetwork: downloadNetwork
      };
      this.otaUpdater?.resumeDownload(versionDigestInfo, resumeDownloadOptions).then(() => {
        this.log('download succeeded.');
        resolve();
      }).catch((err: BusinessError) => {
        this.logError('resumeDownload err:' + JSON.stringify(err));
        reject(err);
      });
    });
  }

  /**
   * 取消升级
   */
  cancel(): void {
    (<any> this.otaUpdater).cancel();
  }

  /**
   * 取当前版本数据
   *
   * @return resolve 当前版本信息/reject 错误信息
   */
  @enableTimeOutCheck()
  async getCurrentVersionInfo(): Promise<UpgradeData<update.CurrentVersionInfo>> {
    return new Promise((resolve, reject) => {
      this.otaUpdater?.getCurrentVersionInfo().then((result: update.CurrentVersionInfo) => {
        this.log('getCurrentVersionInfo result:' + JSON.stringify(result));
        let upgradeData: UpgradeData<update.CurrentVersionInfo> = {
          callResult: UpgradeCallResult.OK,
          data: result
        };
        resolve(upgradeData);
      }).catch((err: BusinessError) => {
        this.logError('getCurrentVersionInfo err:' + JSON.stringify(err));
        let upgradeData: UpgradeData<update.CurrentVersionInfo> = {
          callResult: UpgradeCallResult.ERROR,
          error: err
        };
        resolve(upgradeData);
      });
    });
  }

  private log(message: string): void {
    LogUtils.log('UpdateManager', message);
  }

  private logError(message: string): void {
    LogUtils.error('UpdateManager', message);
  }
}

/**
 * OtaStatus缓存/数据处理
 *
 * @since 2022-07-30
 */
export class OtaStatusHolder {
  private lastStatusHolder: StatusHolder;

  /**
   * 比较otaStatus与lastStatusHolder，并刷新lastStatusHolder
   *
   * @param otaStatus otaStatus
   * @return otaStatus是否是重复事件
   */
  isStatusChangedAndRefresh(otaStatus: OtaStatus, eventId?: update.EventId): boolean {
    const STATUS_ALIVE_TIME = 1000;
    const newStatus = this.makeStatusHolder(otaStatus, eventId);
    let isChanged: boolean;

    if (this.lastStatusHolder != null &&
    (newStatus.initTime - this.lastStatusHolder.initTime) < STATUS_ALIVE_TIME &&
      newStatus.status === this.lastStatusHolder.status) {
      isChanged = false;
    } else {
      isChanged = true;
    }
    this.lastStatusHolder = newStatus;
    return isChanged;
  }

  /**
   * 序列化otaStatus，保存在StatusHolder
   *
   * @param otaStatus
   * @param isCompareProgress 是否考虑进度标志位
   */
  private makeStatusHolder(otaStatus: OtaStatus, eventId?: update.EventId): StatusHolder {
    let otaStatusHolder: StatusHolder = { status: '', initTime: new Date().getTime() };
    if (otaStatus.status == null) {
      otaStatusHolder.status = '_';
    } else {
      otaStatusHolder.status = otaStatus.status + '_';
    }
    let status: number = otaStatus.status;
    let isCompareStatusProgress: boolean = this.isCompareStatusProgress(status);
    if (otaStatus.percent == null || !isCompareStatusProgress) {
      otaStatusHolder.status += '_';
    } else {
      otaStatusHolder.status += otaStatus.percent + '_';
    }
    otaStatusHolder.status += otaStatus.endReason;
    otaStatusHolder.status += eventId;

    return otaStatusHolder;
  }

  private isCompareStatusProgress(status: number): boolean {
    return status === UpdateState.DOWNLOADING || status === UpdateState.INSTALLING;
  }
}

/**
 * 保存每次ota_status的信息
 *
 * @since 2022-07-18
 */
export interface StatusHolder {
  /**
   * 序列化后的status
   */
  status: string;

  /**
   * status接收的时间，ms
   */
  initTime: number;
}

/**
 * 信息
 *
 * @since 2022-10-25
 */
export interface Message {
  /**
   * 上下文
   */
  context: common.Context;

  /**
   * 事件
   */
  eventInfo: update.EventInfo;
}

/**
 * 通知的消息队列
 *
 * @since 2022-08-01
 */
export class MessageQueue {
  private queue: Array<Message>;
  private handleMessage: (message: Message) => Promise<void>;

  constructor(handleMessage: (message: Message) => Promise<void>) {
    this.queue = new Array<Message>();
    this.handleMessage = handleMessage;
  }

  async execute(message: Message): Promise<void> {
    if (!message) {
      return;
    }
    this.offer(message);
    if (this.queue.length === 1) {
      await this.loop();
    }
  }

  isEmpty(): boolean {
    return this.queue?.length === 0;
  }

  private async loop(): Promise<void> {
    let message: Message = this.peek();
    if (message) {
      await this.handleMessage?.(message).catch((err: BusinessError) => {
        LogUtils.error('MessageQueue', 'loop err:' + JSON.stringify(err));
      });
      this.poll();
      await this.loop();
    }
  }

  private offer(message: Message): void {
    if (!message) {
      return;
    }
    this.queue.push(message);
  }

  private poll(): void {
    if (this.queue.length !== 0) {
      this.queue.shift();
    }
  }

  private peek(): Message {
    if (this.queue.length !== 0) {
      return this.queue[0];
    }
    return null;
  }
}