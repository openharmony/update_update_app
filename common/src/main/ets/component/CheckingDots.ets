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

/**
 * ...等待轮播
 *
 * @since 2022-07-07
 */
@Component
export struct CheckingDots {
  @Prop @Watch('onDotTextPlayChange')
  private dotTextPlay: boolean;
  private newVersionDotText: string= '.';
  private checkingTid: number | null = null;
  @State private dotNumber: number = 0;

  aboutToDisappear() {
    this.clearCheckingTid();
  }

  aboutToAppear() {
    this.onDotTextPlayChange();
  }

  /**
   * bind dotTextPlay
   * change running play
   */
  private onDotTextPlayChange() {
    if (this.dotTextPlay) {
      this.cycleDisplay();
    } else {
      this.clearCheckingTid();
    }
  }

  private clearCheckingTid(): void {
    if (this.checkingTid != null) {
      clearInterval(this.checkingTid);
      this.checkingTid = null;
    }
  }

  /**
   * loop newVersionDotText with CHECKING_DOTS array.
   */
  private cycleDisplay(): void {
    if (this.checkingTid == null) {
      let index = 0;
      this.dotNumber = index;
      this.checkingTid = setInterval(() => {
        this.dotNumber = index++%3;
      }, 500);
    }
  }

  @Builder dotText(visibility: Visibility) {
    Text(this.newVersionDotText)
      .fontSize($r('app.float.text_size_body'))
      .fontColor(Color.Black)
      .opacity(0.6)
      .fontWeight(FontWeight.Regular)
      .align(Alignment.Start)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.None })
      .visibility(visibility)
  }

  build() {
    Row() {
      if (this.dotTextPlay) {
        this.dotText(Visibility.Visible)
        if (this.dotNumber >= 1) {
          this.dotText(Visibility.Visible)
        } else {
          this.dotText(Visibility.Hidden)
        }
        if (this.dotNumber == 2) {
          this.dotText(Visibility.Visible)
        } else {
          this.dotText(Visibility.Hidden)
        }
      }
    }
  }
}