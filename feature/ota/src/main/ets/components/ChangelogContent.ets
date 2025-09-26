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

import { ChangelogInfo } from '@ohos/common/src/main/ets/manager/UpgradeInterface';
import {
  Changelog,
  ChangelogType,
  Feature,
  Features,
  Language
} from '@ohos/common/src/main/ets/const/update_const';
import { DeviceUtils } from '@ohos/common/src/main/ets/util/DeviceUtils';
import { LogUtils } from '@ohos/common/src/main/ets/util/LogUtils';
import ChangelogParseUtils from '../util/ChangelogParseUtils';

/**
 * changelog组件
 *
 * @since 2022-06-06
 */
@Component
export struct ChangelogContent {
  @State private changelogInfoList: Array<ChangelogInfo> | null = null;
  private isCurrentPage: boolean = false;
  isNeedFold: boolean = false;
  @Prop @Watch('parseChangelog') description: string;
  @State private isParseChangelogFinished: boolean = false;

  @Builder buildChangelog() {
    Column() {
      if (this.changelogInfoList && this.isParseChangelogFinished) {
        ForEach(this.changelogInfoList, (item: ChangelogInfo, index: number = 0) => {
          ChangelogCard({
            changelogInfo: item,
            index: (this.changelogInfoList && this.changelogInfoList?.length > 1) ? index + 1 : 0,
            isCurrentPage: this.isCurrentPage
          });
        })
      } else {
        ChangelogCard();
      }
      if (this.changelogInfoList?.[0]?.endFeatures && !this.isCurrentPage && this.isParseChangelogFinished) {
        Column() {
          this.setEndFeature();
        }
        .alignItems(HorizontalAlign.Start)
        .margin({
          left: $r('app.float.changelog_end_content_margin_horizontal'),
          right: $r('app.float.changelog_end_content_margin_horizontal'),
          bottom: $r('app.float.changelog_tablet_end_content_margin_bottom')
        })
      }
    }.width('100%')
  }

  @Builder setEndFeature() {
    Text(this.changelogInfoList?.[0].endFeatures?.title)
      .fontSize($r('app.float.changelog_content_end_title'))
      .fontColor($r('sys.color.ohos_fa_text_secondary'))
      .fontWeight(FontWeight.Medium)
      .width('100%')
    ForEach(this.changelogInfoList?.[0].endFeatures?.featureList, (feature: Feature) => {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start, justifyContent: FlexAlign.Start }) {
        ForEach(feature.contents, (content: string) => {
          Text(content)
            .fontColor($r('sys.color.ohos_fa_icon_secondary'))
            .fontSize($r('app.float.changelog_end_word'))
            .fontWeight(FontWeight.Regular)
            .align(Alignment.Start)
            .padding({ top: this.changelogInfoList?.[0].endFeatures?.featureList.indexOf(feature) == 0 ?
            $r('app.float.changelog_tablet_has_feature_padding_top') :
            $r('app.float.changelog_tablet_no_feature_padding_top')
            });
        });
      }
    });
  }

  aboutToAppear() {
    this.logInfo('aboutToAppear');
    this.parseChangelog();
  }

  private parseChangelog(): void {
    this.logInfo('parseChangelog');
    let list: ChangelogInfo[] | null = null;
    if (this.description) {
      list = JSON.parse(this.description);
    }
    if (list) {
      this.logInfo('aboutToAppear parseXml');
      let isParseSuccess: boolean = true;
      list?.forEach((changelogInfo: ChangelogInfo, index: number) => {
        ChangelogParseUtils.parseXml(changelogInfo.content, (data) => {
          if (!data) {
            isParseSuccess = false;
            this.logError('aboutToAppear parseXml error');
            return;
          }
          let language = DeviceUtils.getSystemLanguage();
          changelogInfo.headFeatures = this.getHeaderFeatures(data, language);
          changelogInfo.endFeatures = this.getEndFeatures(data, language);
          changelogInfo.contentFeatures = this.getContentFeatures(data, language);
          if (data.displayType) {
            changelogInfo.displayType = data.displayType;
          }
        });
      });
      this.isParseChangelogFinished = true;
      this.changelogInfoList = isParseSuccess ? list : [];
    } else {
      this.logInfo('description is null');
    }
  }

  private getHeaderFeatures(changelog: Changelog, language: string): Features | undefined {
    return this.getTargetFeatures(changelog, language, 'header');
  }

  private getEndFeatures(changelog: Changelog, language: string): Features | undefined {
    return this.getTargetFeatures(changelog, language, 'end');
  }

  private getContentFeatures(changelog: Changelog, language: string): Array<Features> {
    let featuresList: Features[] = [];
    if (changelog == null || language == null) {
      return featuresList;
    }
    let lang: Language | undefined = changelog.language.get(language);
    if (lang == null) {
      return featuresList;
    }

    for (let index = 0; index < lang.featuresArray.length; index++) {
      const features = lang.featuresArray[index];
      if (features != null && features.featureModuleType != 'header' && features.featureModuleType != 'end') {
        featuresList.push(features);
      }
    }
    return featuresList;
  }

  private getTargetFeatures(changelog: Changelog, language: string, type: string): Features | undefined {
    if (changelog == null || language == null) {
      return;
    }
    let lang: Language | undefined = changelog.language.get(language);
    if (lang == null) {
      return;
    }
    let _features: Features | undefined;
    for (let index = 0; index < lang.featuresArray.length; index++) {
      const features = lang.featuresArray[index];
      if (features != null && features.featureModuleType == type) {
        return features;
      }
    }
    return _features;
  }

  build(): void{
    this.buildChangelog();
  }

  private logInfo(message: string): void {
    LogUtils.info('ChangelogContent', message);
  }

  private logError(message: string): void {
    LogUtils.error('ChangelogContent', message);
  }
}

/**
 * 更新日志卡片
 *
 * @since 2022-12-01
 */
@Component
struct ChangelogCard {
  changelogInfo: ChangelogInfo | null = null;
  index: number = 0;
  isCurrentPage: boolean = false;

  aboutToAppear() {
  }

  build () {
    Column() {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
        Text($r('app.string.title_change_log'))
          .fontSize($r('sys.float.ohos_id_text_size_sub_title2'))
          .fontWeight(FontWeight.Medium)
          .width('100%')
      }

      if (!this.changelogInfo) {
        this.setDetailFeature($r('app.string.no_info_now'));
      }

      if (this.changelogInfo?.headFeatures) {
        this.setStartFeature(this.changelogInfo);
      }
      if (this.changelogInfo?.contentFeatures) {
        this.setContentFeatures(this.changelogInfo);
      }
    }
    .padding({
      left: $r('app.float.changelog_tablet_start_content_padding_horizontal'),
      right: $r('app.float.changelog_tablet_start_content_padding_horizontal'),
      top: $r('app.float.changelog_tablet_start_content_padding_top'),
      bottom: $r('app.float.changelog_tablet_start_content_padding_bottom')
    })
    .margin({
      left: $r('app.float.changelog_detail_content_margin_horizontal'),
      right: $r('app.float.changelog_detail_content_margin_horizontal'),
      bottom: $r('app.float.changelog_tablet_start_content_margin_bottom')
    })
    .backgroundColor(Color.White)
    .alignItems(HorizontalAlign.Start)
    .borderRadius($r('app.float.card_border_radius'))
  }

  @Builder setDetailFeature(content: string | Resource) {
    Text(content)
      .opacity(0.6)
      .fontSize($r('sys.float.ohos_id_text_size_sub_title3'))
      .fontWeight(FontWeight.Regular)
      .align(Alignment.Start)
      .padding({ top: $r('app.float.changelog_tablet_start_detail_padding_top') });
  }

  @Builder setStartFeature(changelogInfo: ChangelogInfo) {
    if (changelogInfo.headFeatures && changelogInfo.headFeatures.featureList) {
      this.setFeatureContent(changelogInfo.headFeatures.featureList)
    }
  }

  @Builder setFeatureContent(featureList: Array<Feature>) {
    ForEach(featureList, (item: Feature) => {
      Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Start, justifyContent: FlexAlign.Start }) {
        ForEach(item.contents, (content: string) => {
          Text(content)
            .opacity(0.6)
            .fontSize($r('sys.float.ohos_id_text_size_sub_title3'))
            .fontWeight(FontWeight.Regular)
            .align(Alignment.Start)
            .padding({ top: featureList.indexOf(item) == 0 ?
            $r('app.float.changelog_tablet_has_feature_padding_top') :
            $r('app.float.changelog_tablet_no_feature_padding_top')
            });
        });
      }
    });
  }

  @Builder setContentFeatures(changelogInfo: ChangelogInfo) {
    if (this.changelogInfo?.displayType == ChangelogType.TEXT) {
      ForEach(changelogInfo.contentFeatures, (features: Features) => {
        Text(features.title)
          .opacity(0.6)
          .fontSize($r('sys.float.ohos_id_text_size_sub_title3'))
          .fontWeight(FontWeight.Regular)
          .align(Alignment.Start)
          .padding({ top: $r('app.float.changelog_tablet_start_content_padding_top')})
        Flex({ direction: FlexDirection.Column, alignItems: ItemAlign.Center, justifyContent: FlexAlign.Start }) {
          if (features.featureList) {
            this.setFeatureContent(features.featureList)
          }
        }
      })
    }
  }
}