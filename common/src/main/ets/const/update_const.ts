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

import update from '@ohos.update';

/**
 * 升级状态
 *
 * @since 2022-06-05
 */
export enum UpdateState {
  /**
   * 初始状态
   */
  INIT = 0,

  /**
   * 状态--搜包成功
   */
  CHECK_SUCCESS = 12,

  /**
   * 状态--下载中
   */
  DOWNLOADING = 20,

  /**
   * 状态--下载暂停
   */
  DOWNLOAD_PAUSE = 21,

  /**
   * 状态--取消下载
   */
  DOWNLOAD_CANCEL = 22,

  /**
   * 状态--下载失败
   */
  DOWNLOAD_FAILED = 23,

  /**
   * 状态--下载成功
   */
  DOWNLOAD_SUCCESS = 24,

  /**
   * 状态--安装中
   */
  INSTALLING = 80,

  /**
   * 状态--安装失败
   */
  INSTALL_FAILED = 81,

  /**
   * 状态--安装成功
   */
  INSTALL_SUCCESS = 82,

  /**
   * 状态--升级中
   */
  UPGRADING = 90,

  /**
   * 状态--升级失败
   */
  UPGRADE_FAILED = 91,

  /**
   * 状态--升级成功
   */
  UPGRADE_SUCCESS = 92,
}

/**
 * 升级接口--状态结构体
 *
 * @since 2022-06-05
 */
export interface OtaStatus {
  /**
   * 状态
   */
  status: number;

  /**
   * 进度
   */
  percent: number;

  /**
   * 终止原因
   */
  endReason?: string;
}

/**
 * 升级错误码
 *
 * @since 2022-06-05
 */
export enum ErrorCode {
  /**
   * 错误码--默认失败
   */
  DEFAULT_ERROR = -1,

  /**
   * 搜包结果--网络错误
   */
  CHECK_NETWORK_ERR = -2,

  /**
   * 搜包结果--搜包中
   */
  CHECK_SYSTEM_BUSY = -207,

  /**
   * 错误码--鉴权失败
   */
  AUTH_FAIL = '-208',

  /**
   * 错误码--鉴权失败服务错误
   */
  AUTH_SERVER_ERROR = '-209',

  /**
   * 错误码--鉴权失败系统错误
   */
  AUTH_SYSTEM_ERROR = '-210',

  /**
   * 错误码--网络错误
   */
  NETWORK_ERROR = '-301',

  /**
   * 错误码--空间不足
   */
  NO_ENOUGH_MEMORY = '-304',

  /**
   * 错误码--检验失败
   */
  VERIFY_PACKAGE_FAIL = '-305',

  /**
   * 错误码--部分升級失敗
   */
  UPDATE_PART_FAIL = '-409',

  /**
   * 错误码--电量不足
   */
  NO_ENOUGH_BATTERY = '-830',

  /**
   * 错误码--网络不允许
   */
  NETWORK_NOT_ALLOW = '3148800'
}

/**
 * 通用常量
 *
 * @since 2022-06-05
 */
export enum UpdateConstant {
  /**
   * 搜包重试时间
   */
  CHECKING_RETRY_TIME = 5,

  /**
   * 搜包等待间隔
   */
  CHECKING_WAITING_TIME_IN_SECONDS = 3,

  /**
   * 安装电量阈值
   */
  UPGRADE_BATTERY_THRESHOLD = 30
}

/**
 * 更新日志结构体
 *
 * @since 2022-06-05
 */
export interface Changelog {
  /**
   * 默认语言
   */
  defLanguage?: string;

  /**
   * 显示类型
   */
  displayType?: number;

  /**
   * 所有语言更新日志
   */
  language: Map<string, Language>;
}

/**
 * 更新日志结构体--语言
 *
 * @since 2022-06-05
 */
export interface Language {
  /**
   * 日志对应语言
   */
  language?: string;

  /**
   * 日志特性数组
   */
  featuresArray: Array<Features>;
}

/**
 * 更新日志结构体--特性集合
 *
 * @since 2022-06-05
 */
export interface Features {
  /**
   * 标题
   */
  title: string;

  /**
   * 标识
   */
  id: string;

  /**
   * 特性类型
   */
  featureModuleType: string;

  /**
   * 特性数组
   */
  featureList: Array<Feature>;

  /**
   * 图标
   */
  icon: Icon;
}

/**
 * 更新日志结构体--特性
 *
 * @since 2022-06-05
 */
export interface Feature {
  /**
   * 子标题
   */
  subTitle: string;

  /**
   * 内容数组
   */
  contents: Array<string>;
}

/**
 * 更新日志结构体--图标
 *
 * @since 2022-06-05
 */
export interface Icon {
  /**
   * 标识
   */
  id: string;

  /**
   * 包名
   */
  pkg: string;

  /**
   * 数据流字串
   */
  res: string;
}

/**
 * changelog类型
 *
 * @since 2022-08-26
 */
export enum ChangelogType {
  /**
   * 文本类型
   */
  TEXT = -1,

  /**
   * 图文类型
   */
  PICTURE_AND_TEXT = 0,

  /**
   * web类型
   */
  WEB_TYPE = 1,
}

/**
 * 动作常量枚举
 *
 * @since 2022-06-05
 */
export enum Action {
  /**
   * 动作--跳转主页面搜包
   */
  NOTIFICATION_LATER = 'com.ohos.updateapp.later', 

  /**
   * 动作--跳转主页面搜包
   */
  NOTIFICATION_CHECK = 'com.ohos.updateapp.check',

  /**
   * 动作--下载
   */
  NOTIFICATION_DOWNLOAD = 'com.ohos.updateapp.download',

  /**
   * 动作--跳转新版本页面安装
   */
  NOTIFICATION_INSTALL = 'com.ohos.updateapp.install',

  /**
   * 动作--跳转新版本页面
   */
  NOTIFICATION_DETAIL = 'com.ohos.updateapp.detail',

  /**
   * 动作--升级失败跳转主页面搜包
   */
  NOTIFICATION_HOT_UPGRADE_FAILED = 'com.ohos.updateapp.hot_upgrade_failed'
}

/**
 * 接口执行结果
 *
 * @since 2022-07-11
 */
export interface UpgradeData<T> {
  /**
   * 接口执行结果
   */
  callResult: UpgradeCallResult;

  /**
   * 回调数据
   */
  data?: T;

  /**
   * 错误结果
   */
  error?: BusinessError
}

/**
 * 接口执行错误码
 *
 * @since 2022-07-11
 */
export enum UpgradeCallResult {
  /**
   * 接口执行成功
   */
  OK = 1,

  /**
   * 接口执行失败
   */
  ERROR = -1,

  /**
   * 接口执行超时
   */
  TIME_OUT = -2
}

/**
 * 倒计时弹窗类型
 *
 * @since 2023-02-08
 */
export enum CountDownDialogType {
  /**
   * ota20S倒计时
   */
  OTA = 0,

  /**
   * ab升级20S倒计时
   */
  OTA_AB = 1,
}


/**
 * BusinessError
 *
 * @since 2023-03-10
 */
export interface BusinessError {
  /**
   * 数据
   */
  data?: ErrCode[];
}

/**
 * ErrCode
 *
 * @since 2023-03-10
 */
export interface ErrCode {
  /**
   * 错误码
   */
  errorCode: ErrorCode;
}

/**
 * 包名
 */
export const PACKAGE_NAME = 'com.ohos.updateapp';

/**
 * 主ability名
 */
export const MAIN_ABILITY_NAME = 'com.ohos.updateapp.MainAbility'; 