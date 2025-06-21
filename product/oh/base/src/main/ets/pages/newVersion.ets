import { DialogUtils } from '../../../../../../../feature/ota/src/main/ets/dialog/DialogUtils';
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

import {
  CountDownDialogType,
  OtaStatus,
  UpdateState,
  UpgradeCallResult,
  UpgradeData
} from '@ohos/common/src/main/ets/const/update_const';
import update from '@ohos.update';
import { TitleBar } from '@ohos/common/src/main/ets/component/TitleBar';
import { FormatUtils } from '@ohos/common/src/main/ets/util/FormatUtils';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { DeviceUtils } from '@ohos/common/src/main/ets/util/DeviceUtils';
import { ChangelogInfo, IPage, VersionPageInfo } from '@ohos/common/src/main/ets/manager/UpgradeInterface';
import { NetUtils } from '@ohos/common/src/main/ets/util/NetUtils';
import { DialogHelper } from '@ohos/ota/src/main/ets/dialog/DialogHelper';
import { ChangelogContent } from '@ohos/ota/src/main/ets/components/ChangelogContent';
import { ProgressContent } from '@ohos/ota/src/main/ets/components/ProgressContent';
import { OtaUpdateManager } from '@ohos/ota/src/main/ets/manager/OtaUpdateManager';
import { CountDownInstallDialogBuilder } from '@ohos/ota/src/main/ets/dialog/CountDownInstallDialogBuilder';
import { MessageDialogBuilder, } from '@ohos/ota/src/main/ets/dialog/MessageDialogBuilder';
import { StateManager, UpdateAction } from '@ohos/ota/src/main/ets/manager/StateManager';
import { UpgradeAdapter } from '@ohos/ota/src/main/ets/UpgradeAdapter';
import { VersionUtils } from '@ohos/ota/src/main/ets/util/VersionUtils';
import { NotificationHelper } from '@ohos/ota/src/main/ets/notify/NotificationHelper';
import prompt from '@ohos.prompt';
import RouterUtils from '@ohos/ota/src/main/ets/util/RouterUtils';

/**
 * 新版本页面
 *
 * @since 2022-06-06
 */
@Entry
@Component
struct NewVersion {
  @State private displayFileSize: string = '';
  @State @Watch('refreshDescription') private changelogArray: Array<ChangelogInfo> = [];
  @State private description: string = '';
  @State private displayNewVersionName: string = '';
  @State private isButtonEnable: boolean = true;
  @State private isButtonVisible: boolean = true;
  @StorageProp('updateStatus')
  @Watch('initDataByStatus') private updateStatus: number = AppStorage.Get('updateStatus');
  @StorageProp('isClickInstall') @Watch('onInstallClick')
  private isClickInstall: number = AppStorage.Get('isClickInstall');
  private dialogText: string | Resource = '';
  @State private isInitComplete: boolean = false;
  private effectiveMode: update.EffectiveMode = update.EffectiveMode.COLD;
  @State otaMode: update.OtaMode = update.OtaMode.AB_STREAM_OTA;
  private dialogType: CountDownDialogType = CountDownDialogType.OTA;
  @State private buttonText: string = '';
  @StorageProp('installStatusRefresh') @Watch('refresh')
  private installStatusRefresh: string = AppStorage.Get('installStatusRefresh');

  private countdownDialogController = new CustomDialogController({
    builder: CountDownInstallDialogBuilder({
      textString: this.dialogText,
      dialogType: this.dialogType,
      cancel: () => {
        globalThis.displayCountdownDialog = false;
      },
      confirm: () => {
        globalThis.displayCountdownDialog = false;
        if (this.isABInstall()) {
          this.reboot();
        } else {
          this.upgrade();
        }
      }
    }),
    autoCancel: false,
    alignment: DeviceUtils.getDialogLocation(),
    offset: ({
      dx: '0vp',
      dy: DeviceUtils.getDialogOffsetY()
    })
  });

  private restartDialogController = new CustomDialogController({
    builder: MessageDialogBuilder({ message: $r('app.string.reboot_wait') }),
    autoCancel: false,
    alignment: DeviceUtils.getDialogLocation(),
    offset: ({
      dx: '0vp',
      dy: DeviceUtils.getDialogOffsetY()
    })
  });

  private refreshDescription(): void {
    this.log('refreshDescription');
    this.description = JSON.stringify(this.changelogArray);
  }

  aboutToAppear() {
    this.log('aboutToAppear');
    globalThis.newVersionThis = this;
  }

  onPageShow() {
    this.log('onPageShow NewVersionPage.');
    globalThis.currentPage = 'pages/newVersion';
    this.initDataByStatus();
    new NotificationHelper().cancelAll();
    this.handleAbnormalState();
  }

  private async handleAbnormalState(): Promise<void> {
    let upgradeData: UpgradeData<OtaStatus> = await OtaUpdateManager.getInstance().getOtaStatus();
    let otaStatus: OtaStatus = upgradeData.callResult == UpgradeCallResult.OK ? upgradeData.data : null;
    let state = otaStatus?.status;
    if (!state || state === UpdateState.INIT || state === UpdateState.UPGRADE_SUCCESS ||
    state === UpdateState.UPGRADE_FAILED || state === UpdateState.INSTALL_FAILED) {
      this.closeUpgradeDialog();
      return;
    }
  }

  onPageHide() {
    this.log('onPageHide NewVersionPage');
  }

  onBackPress() {
    return globalThis.displayCountdownDialog;
  }

  /**
   * raise by notify installWantAgentInfo
   */
  private raiseCountDialogByClick(): void {
    this.showCountdownDialog(UpdateState.DOWNLOAD_SUCCESS);
    globalThis.abilityWant = null;
  }

  private onInstallClick(): void {
    this.log('onInstallClick');
    if (this.isClickInstall) {
      this.raiseCountDialogByClick();
    }
  }

  private async showCountdownDialog(updateStatus: number): Promise<void> {
    this.log('showCountdownDialog');
    if (StateManager.isAllowExecute(updateStatus, UpdateAction.INSTALL)) {
      globalThis.displayCountdownDialog = true; // dialog display
      AppStorage.Set('isClickInstall', 0); // reset
      this.countdownDialogController.open();
    }
  }

  public onLanguageChange(): void {
    this.initDataByStatus();
  }

  private async initDataByStatus(): Promise<void> {
    this.isButtonEnable = StateManager.isButtonEnable(this.updateStatus);
    await this.initNewVersionPageInfo();
    if (this.isClickInstall) {
      this.raiseCountDialogByClick();
    }
    let stateButtonText = StateManager.getButtonText(this.updateStatus);
    this.buttonText = FormatUtils.toUpperCase(globalThis.abilityContext, stateButtonText);
    this.isButtonVisible =
    this.updateStatus !== UpdateState.INSTALL_FAILED &&
    (this.isABInstall() || this.updateStatus !== UpdateState.INSTALL_SUCCESS) &&
    this.updateStatus !== UpdateState.UPGRADING &&
    this.updateStatus !== UpdateState.UPGRADE_FAILED &&
    this.updateStatus !== UpdateState.UPGRADE_SUCCESS &&
    (this.isABStreamInstall() ||
    (this.updateStatus !== UpdateState.INSTALL_PAUSE &&
    this.updateStatus !== UpdateState.INSTALLING));
  }

  public async initNewVersionPageInfo(): Promise<void> {
    let newVersionInfo = globalThis.cachedNewVersionInfo || await OtaUpdateManager.getInstance().getNewVersion()
      .then(upgradeData => {
        this.log(`initDataByStatus upgradeData: ${upgradeData}`);
        return upgradeData.callResult == UpgradeCallResult.OK ? upgradeData.data : null;
      });
    let componentDescription = await OtaUpdateManager.getInstance().getNewVersionDescription();
    if (!newVersionInfo) {
      return;
    }
    let components: update.VersionComponent[] = VersionUtils.sortComponents(newVersionInfo?.versionComponents);
    let pageInfo: VersionPageInfo = await UpgradeAdapter.getInstance()
      .getPageInstance()?.getNewVersionPageInfo(components);
    this.displayNewVersionName = pageInfo?.version;
    this.dialogText = pageInfo?.countDownDialogInfo?.dialogText;
    this.dialogType = pageInfo?.countDownDialogInfo?.dialogType;
    this.effectiveMode = pageInfo?.effectiveMode;
    this.otaMode = pageInfo?.otaMode;
    let size: number = 0;
    let array: ChangelogInfo[] = [];

    for (let index = 0; index < components?.length; index ++) {
      let page: IPage = UpgradeAdapter.getInstance().getPageInstance();
      if (!page) {
        continue;
      }
      let versionPageInfo: VersionPageInfo = await page.getNewVersionPageInfo(components, componentDescription.data);
      size += versionPageInfo.size;
      array.push(versionPageInfo.changelog);
    }
    this.changelogArray = array;
    this.displayFileSize = FormatUtils.formatFileSize(size);
    this.isInitComplete = true;
  }

  private async upgrade(): Promise<void> {
    this.log('upgrade effectiveMode ' + this.effectiveMode);
    this.isButtonEnable = false;
    let order = this.isABInstall() ? update.Order.INSTALL: update.Order.INSTALL_AND_APPLY
    OtaUpdateManager.getInstance().upgrade(order).catch(err => {
      this.isButtonEnable = true;
    });
  }

  private async reboot(): Promise<void> {
    this.log('reboot!');
    if (this.isABInstall()) {
      OtaUpdateManager.getInstance().upgrade(update.Order.APPLY);
    }
  }

  private async handleButtonClick(): Promise<void> {
    this.log('handleButtonClick');
    switch (StateManager.getButtonClickAction(this.updateStatus)) {
      case UpdateAction.DOWNLOAD:
        if (await NetUtils.isCellularNetwork()) {
          DialogHelper.displayNetworkDialog({
            onConfirm: () => {
              if (this.isABStreamInstall()) {
                this.upgrade();
              } else {
                OtaUpdateManager.getInstance().download(update.NetType.CELLULAR);
              }
            } });
        } else {
          if (this.isABStreamInstall()) {
            this.upgrade();
          } else {
            OtaUpdateManager.getInstance().download();
          }
        }
        break;
      case UpdateAction.INSTALL:
        this.upgrade();
        break;
      case UpdateAction.REBOOT:
        this.reboot();
        break;
      case UpdateAction.CANCEL:
        OtaUpdateManager.getInstance().cancel();
        break;
      case UpdateAction.RESUME:
        if (this.isABStreamInstall()) {
          this.upgrade();
        } else {
          OtaUpdateManager.getInstance().resumeDownload();
        }
        break;
      default:
        break;
    }
  }

  build() {
    Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
      Column() {
        TitleBar({ title: $r('app.string.title_new_version'), onBack: this.onBackPress.bind(this)});
      }.flexShrink(0);
      Column() {
        Scroll() {
          Column() {
            ProgressContent();
            if (this.isInitComplete) {
              Text(this.displayNewVersionName)
                .fontSize($r('app.float.text_size_version_name'))
                .maxLines(5)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .padding({
                  right: $r('app.float.changelog_detail_content_padding_horizontal'),
                  left: $r('app.float.changelog_detail_content_padding_horizontal'),
                })
                .fontWeight(FontWeight.Medium);
              Text(this.displayFileSize)
                .fontSize($r('app.float.text_size_version_size')).fontWeight(FontWeight.Regular).opacity(0.6)
                .margin({
                  top: $r('app.float.new_version_size_margin_top'),
                  bottom: $r('app.float.new_version_size_margin_bottom')
                })
              ChangelogContent({
                isCurrentPage: false,
                isNeedFold: this.changelogArray?.length > 1,
                description: this.description
              })
            }
          }.width('100%').flexShrink(0)
        }
        .width('100%')
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
      }.flexGrow(1)

      Column() {
        Button() {
          Text(this.buttonText)
            .fontSize($r('app.float.text_size_btn')).fontColor(Color.White).fontWeight(FontWeight.Medium)
            .margin({ left: $r('app.float.custom_button_text_margin_left'),
              right: $r('app.float.custom_button_text_margin_right') })
        }
        .type(ButtonType.Capsule)
        .constraintSize({ minWidth: $r('app.float.custom_button_width') })
        .height($r('app.float.custom_button_height'))
        .backgroundColor($r('app.color.blue'))
        .opacity(this.isButtonEnable ? 1 : 0.4)
        .visibility(this.isButtonVisible ? Visibility.Visible : Visibility.None)
        .onClick(() => {
          if(this.isButtonEnable) {
            this.handleButtonClick();
          }
        })
      }
      .flexShrink(0)
      .padding({
        top: $r('app.float.new_version_button_padding_top'),
        bottom: $r('app.float.new_version_button_padding_bottom')
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  private log(message: string): void {
    LogUtils.log('NewVersion', message);
  }

  private closeUpgradeDialog() {
    this.restartDialogController.close();
  }

  private isABInstall(): boolean {
    return this.effectiveMode === update.EffectiveMode.LIVE_AND_COLD || this.isABStreamInstall();
  }

  private isABStreamInstall(): boolean {
    return this.otaMode === update.OtaMode.AB_STREAM_OTA;
  }

  private refresh() {
    if (this.isABInstall()) {
      return;
    }
    let otaStatus: OtaStatus = JSON.parse(this.installStatusRefresh);
    let status: UpdateState = otaStatus?.status;
    if (status === UpdateState.INSTALL_FAILED || status === UpdateState.UPGRADE_FAILED ||
      status === UpdateState.UPGRADE_SUCCESS) {
      this.closeUpgradeDialog();
    } else if (status === UpdateState.UPGRADING) {
      this.restartDialogController.open();
    }
  }
}