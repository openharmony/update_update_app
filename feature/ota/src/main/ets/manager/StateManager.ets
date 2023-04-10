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
import { ErrorCode, OtaStatus, UpdateState } from '@ohos/common/src/main/ets/const/update_const';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { DialogUtils } from '../dialog/DialogUtils';
import { OtaUpdateManager } from '../manager/OtaUpdateManager';
import VersionUtils from '../util/VersionUtils';
import ToastUtils from '../util/ToastUtils';
import { UpgradeAdapter } from '../UpgradeAdapter';
import { NotificationManager } from '../notify/NotificationManager';

/**
 * 状态工厂
 *
 * @since 2022-06-10
 */
export namespace StateManager {
  /**
   * 是否允许执行该升级行为
   *
   * @param status 状态
   * @param action 行为
   * @return 是否允许
   */
  export function isAllowExecute(status: number, action: UpdateAction): boolean {
    let stateObj: BaseState = OtaUpdateManager.getInstance().getStateObj(status);
    return stateObj.actionSet.indexOf(action) != -1;
  }

  /**
   * 取下载状态描述
   *
   * @param status 状态
   * @return 下载状态描述
   */
  export function getDownloadStateText(status: number): string | Resource {
    return OtaUpdateManager.getInstance().getStateObj(status).downloadStateText;
  }

  /**
   * 取按钮文字
   *
   * @param status 状态
   * @return 按钮文字
   */
  export function getButtonText(status: number): string | Resource {
    return OtaUpdateManager.getInstance().getStateObj(status).buttonText;
  }

  /**
   * 按钮点击是否可点击
   *
   * @param status 状态
   * @return 是否可点击
   */
  export function isButtonEnable(status: number): boolean {
    return OtaUpdateManager.getInstance().getStateObj(status).isButtonClickable;
  }

  /**
   * 取按钮点击行为
   *
   * @param status 状态
   * @return 按钮点击行为
   */
  export function getButtonClickAction(status: number): UpdateAction {
    return OtaUpdateManager.getInstance().getStateObj(status).buttonClickAction;
  }

  /**
   * 创造状态实例
   *
   * @param status 状态
   * @return 实例对象
   */
  export function createInstance(status: OtaStatus | number): BaseState {
    let state: number = (typeof status === 'number') ? status : status?.status;
    let stateObject: BaseState = null;
    switch (state) {
      case UpdateState.DOWNLOAD_CANCEL: // fall through
      case UpdateState.CHECK_SUCCESS:
        stateObject = new CheckSuccess();
        break;
      case UpdateState.DOWNLOADING:
        stateObject = new Downloading();
        break;
      case UpdateState.DOWNLOAD_PAUSE:
        stateObject = new DownloadPause();
        break;
      case UpdateState.DOWNLOAD_SUCCESS:
        stateObject = new DownloadSuccess();
        break;
      case UpdateState.INSTALLING:
        stateObject = new Installing();
        break;
      case UpdateState.INSTALL_FAILED:
        stateObject = new InstallFailed();
        break;
      case UpdateState.DOWNLOAD_FAILED:
        stateObject = new DownloadFailed();
        break;
      case UpdateState.INSTALL_SUCCESS: // fall through
        stateObject = new InstallSuccess();
        break;
      case UpdateState.UPGRADING:
        stateObject = new Upgrading();
        break;
      case UpdateState.UPGRADE_SUCCESS:
        stateObject = new UpgradeSuccess();
        break;
      case UpdateState.UPGRADE_FAILED:
        stateObject = new UpgradeFailed();
        break;
      default:
        stateObject = new Init();
        break;
    }
    if (typeof status !== 'number' && status != null) {
      stateObject.refresh(status);
    }
    return stateObject;
  }
}

/**
 * 升级行为
 *
 * @since 2022-06-10
 */
export enum UpdateAction {
  /**
   * 搜索新版本
   */
  CHECK_NEW_VERSION,

  /**
   * 下载
   */
  DOWNLOAD,

  /**
   * 取消升级
   */
  CANCEL,

  /**
   * 继续下载
   */
  RESUME,

  /**
   * 安装
   */
  INSTALL,

  /**
   * 重启
   */
  REBOOT,

  /**
   * 显示新版本页面
   */
  SHOW_NEW_VERSION,

  /**
   * 显示进度圆圈
   */
  SHOW_PROCESS_VIEW
}

/**
 * 状态基类
 *
 * @since 2022-06-10
 */
export class BaseState {
  /**
   * 状态对象
   */
  otaStatus: OtaStatus;

  /**
   * 进度
   */
  percent: number = 0;

  /**
   * 状态
   */
  state: number = UpdateState.INIT;

  /**
   * 升级行为
   */
  actionSet: Array<UpdateAction> = [];

  /**
   * 下载状态描述
   */
  downloadStateText: string | Resource = "";

  /**
   * 下载安装文字描述
   */
  buttonText: string | Resource = $r('app.string.btn_download');

  /**
   * 按钮是否可点击
   */
  isButtonClickable: boolean = true;

  /**
   * 按钮对应的升级行为
   */
  buttonClickAction: UpdateAction;

  /**
   * 数据刷新
   *
   * @param otaStatus 状态
   */
  refresh(otaStatus: OtaStatus): void {
    this.otaStatus = otaStatus;
    if (this.otaStatus?.percent) {
      this.percent = otaStatus?.percent;
    }
  }

  /**
   * 提醒
   */
  async notify(context?: common.Context, eventId?: update.EventId): Promise<void> {
  }
}

/**
 * 状态--初始状态
 *
 * @since 2022-06-10
 */
export class Init extends BaseState {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.CHECK_NEW_VERSION);
  }

  async notify(): Promise<void> {
    await UpgradeAdapter.getInstance().getNotifyInstance()?.cancelAll();
  }
}

/**
 * 状态--搜包成功
 *
 * @since 2022-06-10
 */
export class CheckSuccess extends BaseState {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.SHOW_NEW_VERSION);
    this.actionSet.push(UpdateAction.CHECK_NEW_VERSION);
    this.actionSet.push(UpdateAction.DOWNLOAD);
    this.state = UpdateState.CHECK_SUCCESS;
    this.buttonClickAction = UpdateAction.DOWNLOAD;
  }

  async notify(context?: common.Context, eventId?: update.EventId): Promise<void> {
    if (this.otaStatus?.endReason) {
      await UpgradeAdapter.getInstance().getNotifyInstance()?.cancelAll();
      switch (this.otaStatus.endReason) {
        case ErrorCode.NETWORK_ERROR:
          let message = await context.resourceManager.getString($r("app.string.network_err_toast").id);
          ToastUtils.showToast(message);
          break;
        case ErrorCode.NO_ENOUGH_MEMORY:
          DialogUtils.showDownloadNotEnoughSpaceDialog(context, this.otaStatus, eventId);
          break;
        default:
          DialogUtils.showDownloadFailDialog(context, this.otaStatus, eventId);
          break;
      }
    }
  }
}

/**
 * 状态--下载中
 *
 * @since 2022-06-10
 */
export class Downloading extends BaseState {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.SHOW_NEW_VERSION);
    this.actionSet.push(UpdateAction.SHOW_PROCESS_VIEW);
    this.state = UpdateState.DOWNLOADING;
    this.downloadStateText = $r('app.string.download_status_downloading');
    this.buttonText = $r('app.string.cancel');
    this.buttonClickAction = UpdateAction.CANCEL;
  }

  async notify(context?: common.Context): Promise<void> {
    if (this.percent == 100) {
      await UpgradeAdapter.getInstance().getNotifyInstance()?.cancelAll();
      return;
    }
    if (!VersionUtils.isInNewVersionPage()) {
      let versionName = await VersionUtils.obtainNewVersionName(globalThis.cachedNewVersionInfo);
      await UpgradeAdapter.getInstance().getNotifyInstance()?.showDownloading(versionName, this.percent, context);
    }
  }
}

/**
 * 状态--下载暂停
 *
 * @since 2022-06-10
 */
export class DownloadPause extends BaseState {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.SHOW_NEW_VERSION);
    this.actionSet.push(UpdateAction.SHOW_PROCESS_VIEW);
    this.actionSet.push(UpdateAction.RESUME);
    this.state = UpdateState.DOWNLOAD_PAUSE;
    this.downloadStateText = $r('app.string.download_status_download_pause');
    this.buttonText = $r('app.string.continue');
    this.buttonClickAction = UpdateAction.RESUME;
  }

  async notify(context?: common.Context, eventId?: update.EventId): Promise<void> {
    if (!VersionUtils.isInNewVersionPage()) {
      return;
    }
    if (this.otaStatus?.endReason) {
      await UpgradeAdapter.getInstance().getNotifyInstance()?.cancelAll();
      switch (this.otaStatus?.endReason) {
        case ErrorCode.NETWORK_ERROR:
          if (eventId == update.EventId.EVENT_DOWNLOAD_PAUSE) {
            DialogUtils.showDownloadNoNetworkDialog(context, this.otaStatus, eventId);
          } else {
            let message = await context.resourceManager.getString($r("app.string.network_err_toast").id);
            ToastUtils.showToast(message);
          }
          break;
        case ErrorCode.NETWORK_NOT_ALLOW:
          if (eventId == update.EventId.EVENT_DOWNLOAD_PAUSE) {
            DialogUtils.showDownloadNoNetworkDialog(context, this.otaStatus, eventId);
          }
          break;
        default:
          DialogUtils.showDownloadFailDialog(context, this.otaStatus, eventId);
          break;
      }
    }
  }
}

/**
 * 状态--下载失败
 *
 * @since 2022-06-10
 */
export class DownloadFailed extends BaseState {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.CHECK_NEW_VERSION);
    this.actionSet.push(UpdateAction.SHOW_PROCESS_VIEW);
    this.state = UpdateState.DOWNLOAD_FAILED;
    this.downloadStateText = $r('app.string.download_status_download_failed');
    this.isButtonClickable = false;
    this.buttonText = $r('app.string.cancel');
    this.buttonClickAction = UpdateAction.CANCEL;
  }

  async notify(context?: common.Context, eventId?: update.EventId): Promise<void> {
    await UpgradeAdapter.getInstance().getNotifyInstance()?.cancelAll();
    switch (this.otaStatus.endReason) {
      case ErrorCode.VERIFY_PACKAGE_FAIL:
        DialogUtils.showVerifyFailDialog(context, this.otaStatus, eventId);
        break;
      default:
        DialogUtils.showDownloadFailDialog(context, this.otaStatus, eventId);
        break;
    }
  }
}

/**
 * 状态--下载成功
 *
 * @since 2022-06-10
 */
export class DownloadSuccess extends BaseState {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.INSTALL);
    this.actionSet.push(UpdateAction.SHOW_NEW_VERSION);
    this.actionSet.push(UpdateAction.SHOW_PROCESS_VIEW);
    this.state = UpdateState.DOWNLOAD_SUCCESS;
    this.percent = 100;
    this.downloadStateText = $r('app.string.download_status_download_success');
    this.buttonText = $r('app.string.btn_upgrade');
    this.buttonClickAction = UpdateAction.INSTALL;
  }

  async notify(context?: common.Context, eventId?: update.EventId): Promise<void> {
    let isABInstall = await VersionUtils.isABInstall();
    if (eventId == update.EventId.EVENT_DOWNLOAD_SUCCESS && isABInstall) {
      OtaUpdateManager.getInstance().upgrade(update.Order.INSTALL);
      return;
    }

    if (eventId == update.EventId.EVENT_UPGRADE_WAIT && !isABInstall) {
      LogUtils.info('StateManager', 'manual download complete to count down');
      if (!VersionUtils.isInNewVersionPage()) {
        NotificationManager.startToNewVersion(context);
      }
      AppStorage.Set('isClickInstall', 1);
      return;
    }

    if (this.otaStatus?.endReason) {
      switch (this.otaStatus.endReason) {
        case ErrorCode.NO_ENOUGH_MEMORY:
          DialogUtils.showUpgradeNotEnoughSpaceDialog(context, this.otaStatus, eventId);
          break;
        case ErrorCode.NO_ENOUGH_BATTERY:
          DialogUtils.showUpgradeNotEnoughBatteryDialog(context, this.otaStatus, eventId);
          break;
        default:
          DialogUtils.showUpgradeFailDialog(context, this.otaStatus, eventId);
          break;
      }
    }
  }
}

/**
 * 状态--解压中
 *
 * @since 2022-06-10
 */
export class Installing extends BaseState {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.SHOW_NEW_VERSION);
    this.actionSet.push(UpdateAction.SHOW_PROCESS_VIEW);
    this.state = UpdateState.INSTALLING;
    this.buttonText = $r('app.string.btn_upgrade')
    this.isButtonClickable = false;
    this.downloadStateText = $r('app.string.new_version_status_installing');
  }

  async notify(context?: common.Context): Promise<void> {
    if (this.percent == 100) {
      await UpgradeAdapter.getInstance().getNotifyInstance()?.cancelAll();
      return;
    }
    if (!VersionUtils.isInNewVersionPage()) {
      let versionName = await VersionUtils.obtainNewVersionName(globalThis.cachedNewVersionInfo);
      await UpgradeAdapter.getInstance().getNotifyInstance()?.showInstalling(versionName, this.percent, context);
    }
  }
}

/**
 * 状态--下载成功
 *
 * @since 2022-06-10
 */
export class InstallSuccess extends BaseState {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.REBOOT);
    this.actionSet.push(UpdateAction.SHOW_NEW_VERSION);
    this.actionSet.push(UpdateAction.SHOW_PROCESS_VIEW);
    this.state = UpdateState.INSTALL_SUCCESS;
    this.percent = 100;
    this.downloadStateText = $r('app.string.new_version_status_install_success');
    this.buttonText = $r('app.string.btn_reboot');
    this.buttonClickAction = UpdateAction.REBOOT;
  }

  async notify(context?: common.Context, eventId?: update.EventId): Promise<void> {
    if (eventId == update.EventId.EVENT_APPLY_WAIT) {
      LogUtils.info('StateManager', 'ab install complete to count down');
      if (!VersionUtils.isInNewVersionPage()) {
        NotificationManager.startToNewVersion(context);
      }
      AppStorage.Set('isClickInstall', 1);
    }
  }
}

/**
 * 状态--升级失败
 *
 * @since 2022-06-10
 */
export class InstallFailed extends BaseState {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.CHECK_NEW_VERSION);
    this.actionSet.push(UpdateAction.SHOW_PROCESS_VIEW);
    this.state = UpdateState.INSTALL_FAILED;
    this.percent = 100;
    this.buttonText = $r('app.string.btn_upgrade');
    this.isButtonClickable = false;
  }

  async notify(context?: common.Context): Promise<void> {
    AppStorage.Set('installStatusRefresh', JSON.stringify(this.otaStatus));
    await UpgradeAdapter.getInstance().getNotifyInstance()?.cancelAll();
    if (VersionUtils.isInNewVersionPage()) {
      DialogUtils.showUpgradeFailDialog(context, this.otaStatus);
    } else {
      let versionName = globalThis.lastVersionName;
      LogUtils.log('StateManager', "InstallFailed versionName is " + versionName);
      await UpgradeAdapter.getInstance().getNotifyInstance()?.showUpgradeFailed(versionName, context);
    }

  }
}

/**
 * 状态--升级中
 *
 * @since 2022-06-10
 */
export class Upgrading extends Installing {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.SHOW_NEW_VERSION);
    this.actionSet.push(UpdateAction.SHOW_PROCESS_VIEW);
    this.state = UpdateState.UPGRADING;
    this.percent = 100;
    this.isButtonClickable = false;
    this.downloadStateText = $r('app.string.new_version_status_installing');
  }

  async notify(context?: common.Context): Promise<void> {
    AppStorage.Set('installStatusRefresh', JSON.stringify(this.otaStatus));
  }
}

/**
 * 状态--升级成功
 *
 * @since 2022-06-10
 */
export class UpgradeSuccess extends BaseState {
  constructor() {
    super();
    this.actionSet.push(UpdateAction.CHECK_NEW_VERSION);
    this.actionSet.push(UpdateAction.SHOW_PROCESS_VIEW);
    this.state = UpdateState.UPGRADE_SUCCESS;
    this.percent = 100;
    this.buttonText = $r('app.string.btn_upgrade');
    this.isButtonClickable = false;
  }

  async notify(context?: common.Context): Promise<void> {
    AppStorage.Set('installStatusRefresh', JSON.stringify(this.otaStatus));
    await UpgradeAdapter.getInstance().getNotifyInstance()?.cancelAll();
    let versionName = globalThis.lastVersionName;
    LogUtils.log('StateManager', "UpgradeSuccess versionName is " + versionName);
    await UpgradeAdapter.getInstance().getNotifyInstance()?.showUpgradeSuccess(versionName, context);
  }
}

/**
 * 状态--升级失败
 *
 * @since 2022-06-10
 */
export class UpgradeFailed extends InstallFailed {
  constructor() {
    super();
    this.state = UpdateState.UPGRADE_FAILED;
  }
}