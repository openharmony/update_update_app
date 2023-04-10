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

import connection from '@ohos.net.connection';
import { LogUtils } from '../util/LogUtils';

/**
 * 网络判断工具类
 *
 * @since 2022-08-25
 */
export namespace NetUtils {
  /**
   * 网络是否可用
   *
   * @return 网络是否可用
   */
  export async function isNetAvailable(): Promise<boolean> {
    return new Promise((resolve, reject) => {
      connection.getDefaultNet().then((netHandle) => {
        LogUtils.log('NetUtils', 'getDefaultNet data ' + JSON.stringify(netHandle));
        connection.getNetCapabilities(netHandle).then((info) => {
          LogUtils.log('NetUtils', 'getNetCapabilities data ' + JSON.stringify(info));
          resolve(info?.bearerTypes?.length !== 0);
        }).catch((err) => {
          LogUtils.log('NetUtils', 'getNetCapabilities err ' + JSON.stringify(err));
          resolve(false);
        });
      }).catch((err) => {
        LogUtils.log('NetUtils', 'getDefaultNet err ' + JSON.stringify(err));
        resolve(false);
      });
    });
  }

  /**
   * 是否是蜂窝网络
   *
   * @return 是否是蜂窝网络
   */
  export async function isCellularNetwork(): Promise<boolean> {
    return new Promise((resolve, reject) => {
      connection.getDefaultNet().then((netHandle) => {
        LogUtils.log('NetUtils', 'getDefaultNet data ' + JSON.stringify(netHandle));
        connection.getNetCapabilities(netHandle).then((info) => {
          LogUtils.log('NetUtils', 'getNetCapabilities data ' + JSON.stringify(info));
          resolve(info?.bearerTypes?.length === 1 && info?.bearerTypes?.[0] === connection.NetBearType.BEARER_CELLULAR);
        }).catch((err) => {
          LogUtils.log('NetUtils', 'getNetCapabilities err ' + JSON.stringify(err));
          resolve(false);
        });
      }).catch((err) => {
        LogUtils.log('NetUtils', 'getDefaultNet err ' + JSON.stringify(err));
        resolve(false);
      });
    });
  }
}