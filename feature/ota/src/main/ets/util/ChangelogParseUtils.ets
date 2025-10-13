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

import convertXml from '@ohos.convertxml';
import type { Features, Language, Feature, Changelog, Icon } from '@ohos/common/src/main/ets/const/update_const';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import { CommonUtils } from '@ohos/common/src/main/ets/util/CommonUtils';

/**
 * xml 元素
 *
 * @since 2025-06-09
 */
interface XmlElement {
  _elements?: XmlElement[];
  _name?: string;
  _type?: string;
  _text?: string;
  _attributes?: XmlAttributes
}

/**
 * xml 元素属性
 *
 * @since 2025-06-09
 */
interface XmlAttributes {
  name?: string;
  id?:string;
  pkg?: string;
  res?: string;
  module?: string;
  type?: string;
  title?: string;
}

let conv = new convertXml.ConvertXML();

let options: convertXml.ConvertOptions = {
  trim: false,
  declarationKey: '_declaration',
  instructionKey: '_instruction',
  attributesKey: '_attributes',
  textKey: '_text',
  cdataKey: '_cdata',
  doctypeKey: '_doctype',
  commentKey: '_comment',
  parentKey: '_parent',
  typeKey: '_type',
  nameKey: '_name',
  elementsKey: '_elements',
};

let changelog: Changelog;

/**
 * Changelog解析工具
 *
 * @since 2022-06-06
 */
namespace ChangelogParseUtils {
  /**
   * Changelog解析
   *
   * @param res 待解析的string
   * @param callback 解析结果回调
   */
  export function parseXml(res: string, callback: (data?: Changelog) => void): void {
    logInfo('read file parse start');
    changelog = { language: new Map() };
    if (!res) {
      logError('res is null!');
      callback();
      return;
    }
    let xmlResult: XmlElement = conv.convert(res, options) as XmlElement;
    if (!xmlResult || !xmlResult._elements || xmlResult._elements.length <= 0) {
      logError('xmlResult is null! ' + JSON.stringify(xmlResult));
      callback();
      return;
    }
    let root: XmlElement | undefined = xmlResult._elements[0];
    if (!root || !root._elements || root._elements.length <= 0) {
      logError('root is null! ' + JSON.stringify(root));
      callback();
      return;
    }
    parseRoot(root);
    logInfo('read file parse end');
    callback(changelog);
  }

  function parseRoot(root: XmlElement): void {
    // 倒序解析，先解析Icon
    let icons: Map<string, Icon> = new Map();
    if (root?._elements === undefined) {
      return;
    }
    logInfo('root length ' + root?._elements?.length);
    for (let index = root?._elements?.length; index > 0; index--) {
      let element = root?._elements[index - 1];
      if (!element) {
        logError('element is null! ' + JSON.stringify(element));
        continue;
      }
      if (element._type === 'element' && element._name === 'default-language') {
        let attribute = element._attributes?.name;
        logInfo('default-language :' + attribute);
        changelog.defLanguage = attribute;
      }
      if (element._type === 'element' && element._name === 'displayType') {
        let attribute = Number(element._elements?.[0]?._text);
        logInfo('displayType :' + attribute);
        changelog.displayType = attribute;
      }
      if (element._type === 'element' && element._name === 'icons') {
        let iconsElement = element._elements ?? [];
        parseIcons(iconsElement, icons);
      }
      parseLanguage(element, icons);
    }
  }

  function parseLanguage(element: XmlElement, icons: Map<string, Icon>): void {
    let language: Language = { featuresArray: [] };
    if (element._type === 'element' && element._name === 'language') {
      let attribute: string;
      if (!element._attributes) {
        logError('language is null :' + JSON.stringify(element._attributes));
        return;
      }
      attribute = element._attributes.name ?? '';
      let languageElement = element._elements;
      language.language = attribute;
      changelog.language.set(language.language, language);

      if (!languageElement || languageElement.length <= 0) {
        logError('features is null' + JSON.stringify(languageElement));
        return;
      }
      parseFeatures(languageElement, language, icons);
    }
  }

  function parseIcons(iconsElement: XmlElement[], icons: Map<string, Icon>): void {
    if (CommonUtils.isEmpty(iconsElement)) {
      logError(`iconsElement is null${JSON.stringify(iconsElement)}`);
      return;
    }
    let icon: Icon;
    for (let index = 0; index < iconsElement.length; index++) {
      let iconElement = iconsElement[index];
      if (!iconElement) {
        logError('iconElement is null :' + JSON.stringify(iconElement));
        continue;
      }
      if (iconElement._type === 'element' && iconElement._name === 'icon') {
        icon = {
          id: iconElement?._attributes?.id,
          pkg: iconElement?._attributes?.pkg,
          res: iconElement?._attributes?.res,
        };
        if (icon?.id !== null && icon.id !== undefined) {
          icons.set(icon?.id, icon);
        }
      }
    }
  }

  function parseFeatures(languageElement: XmlElement[], language: Language, icons: Map<string, Icon>): void {
    let features: Features;
    for (let index = 0; index < languageElement.length; index++) {
      let featuresElement = languageElement[index];
      if (!featuresElement) {
        logInfo('featuresElement is null' + JSON.stringify(featuresElement));
        continue;
      }

      if (featuresElement._type === 'element' && featuresElement._name === 'features') {
        let moduleString = featuresElement._attributes?.module;
        let typeString = featuresElement._attributes?.type;
        let id = featuresElement?._attributes?.id;
        let featureElement = featuresElement._elements;
        let featureList: Feature[] = [];
        features = {
          title: moduleString,
          id: id,
          featureModuleType: typeString,
          featureList: featureList,
        };
        if (id !== null && id !== undefined) {
          features.icon = icons.get(id)
        }
        language.featuresArray.push(features);

        if (!featureElement || featureElement.length <= 0) {
          logError('featureElement is null: ' + JSON.stringify(featureElement));
          continue;
        }
        parseFeature(featureElement, featureList);
      }
    }
  }

  function parseFeature(featureElement: XmlElement[], featureList: Array<Feature>): void {
    let feature: Feature | null = null;
    for (let index = 0; index < featureElement.length; index++) {
      let featureItem = featureElement[index];
      if (featureItem._type !== 'element' || featureItem._name !== 'feature') {
        continue;
      }
      if (!featureItem) {
        logError('featureItem is null: ' + JSON.stringify(featureItem));
        continue;
      }

      let title: string | undefined;
      if (featureItem._attributes) {
        title = featureItem._attributes.title;
      }
      let content: string | undefined;
      if (featureItem._elements) {
        content = featureItem._elements[0]._text as string;
      }
      if (title) {
        feature = { subTitle: title, contents: [] };
        featureList.push(feature);
      } else {
        if (!feature) {
          feature = { subTitle: title, contents: [] };
          featureList.push(feature);
        }
        if (content) {
          feature.contents.push(content);
        }
      }
    }
  }

  function logInfo(message: string): void {
    LogUtils.info('ChangelogParseUtils', message);
  }

  function logError(message: string): void {
    LogUtils.error('ChangelogParseUtils', message);
  }
}

export default ChangelogParseUtils;