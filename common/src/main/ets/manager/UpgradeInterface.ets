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
import type { Features, ChangelogType, CountDownDialogType } from '../const/update_const';

/**
 * 升级控制接口
 *
 * @since 2022-12-01
 */
export interface IUpgradeControl {
  /**
   * 升级UX
   */
  page: IPage,

  /**
   * 升级提醒
   */
  notify: INotify
}

/**
 * 更新日志
 *
 * @since 2022-12-01
 */
export interface ChangelogInfo {
  /**
   * 版本号
   */
  version?: string;

  /**
   * 版本大小
   */
  size?: string;

  /**
   * 更新日志
   */
  content: string;

  /**
   * 更新日志类型
   */
  displayType?: ChangelogType;

  /**
   * 更新日志--概述
   */
  headFeatures?: Features;

  /**
   * 更新日志--更新注意事项
   */
  endFeatures?: Features;

  /**
   * 更新日志--具体内容
   */
  contentFeatures?: Array<Features>;
}

/**
 * 倒计时弹框信息
 *
 * @since 2022-12-01
 */
export interface CountDownDialogInfo {
  /**
   * 弹框消息体
   */
  dialogText: Resource;

  /**
   * 弹框类型
   */
  dialogType: CountDownDialogType;
}

/**
 * 界面数据
 *
 * @since 2022-12-01
 */
export interface VersionPageInfo {
  /**
   * 版本号
   */
  version: string;

  /**
   * 版本大小
   */
  size?: number;

  /**
   * 生效模式
   */
  effectiveMode?: update.EffectiveMode;

  /**
   * 更新日志
   */
  changelog: ChangelogInfo;

  /**
   * 倒计时弹框显示内容
   */
  countDownDialogInfo?: CountDownDialogInfo;
}

/**
 * ux页面显示内容
 *
 * @since 2022-12-01
 */
export interface IPage {
  /**
   * 取新版本数据
   *
   * @param versionComponents 升级包
   * @param componentDescriptions 更新日志
   * @return Promise<VersionPageInfo> 具体的新版本数据
   */
  getNewVersionPageInfo(versionComponents: Array<update.VersionComponent>,
    componentDescriptions?: Array<update.ComponentDescription>): Promise<VersionPageInfo>;

  /**
   * 取当前版本数据
   *
   * @param versionComponents 升级包
   * @param componentDescriptions 更新日志
   * @return VersionPageInfo 具体的当前版本数据
   */
  getCurrentVersionPageInfo(versionComponents: Array<update.VersionComponent>,
    componentDescriptions: Array<update.ComponentDescription>): VersionPageInfo;
}

/**
 * 提醒
 *
 * @since 2022-12-01
 */
export interface INotify {
  /**
   * 下载进度通知
   *
   * @param version 版本号
   * @param progress 进度
   * @param context 上下文
   */
  showDownloading(version: string, progress: number, context: common.Context): Promise<void>;

  /**
   * 升级失败通知
   *
   * @param versionName 版本号
   * @param context 上下文
   */
  showUpgradeFailed(versionName: string, context: common.Context): Promise<void>;

  /**
   * 升级成功通知
   *
   * @param versionName 版本号
   * @param context 上下文
   */
  showUpgradeSuccess(versionName: string, context: common.Context): Promise<void>;

  /**
   * 安装中通知
   *
   * @param version 版本号
   * @param progress 进度
   * @param context 上下文
   */
  showInstalling(version: string, progress: number, context: common.Context): Promise<void>

  /**
   * 取消所有通知
   */
  cancelAll(): Promise<void>;

  /**
   * 检查notification服务是否启动
   */
   isServiceReady(): Promise<void>;
}

