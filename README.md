# Google Calendar API Demo Swift6
forked from [ipratikk/Google-Calendar-API-Demo](https://github.com/ipratikk/Google-Calendar-API-Demo)

<img width=192 src="https://github.com/user-attachments/assets/ea61d004-cd81-4ce4-824b-1ef2a8e1aa72" />

- 2025年12月 自分のGoogle Calendarを操作できるiOSアプリを作る準備としてfork

  - 直ちには動かなかったので若干修正

  - 合わせてSwift 6でのコンパイルに変更

- ビルド確認環境

  - macOS 15.6 (24G84)
 
  - Xcode 26.2 (17C52)

- 動作確認環境

  - iOS Simulator: iPhone SE (1st), iOS 15.5

  - 実機: iPhone7, iOS 15.8.5

<br> 

- テスト準備 (主にGoogleの設定、2025年12月20日時点)

  - iOSアプリのバンドルIDを決めておく (本repoの `com.ec22s.GoogleCalendarAPIDemo` とは異なるように)

  - Google Cloudのプロジェクトを作る (既存のを流用でも可)
 
  - プロジェクトの「APIとサービス」>「有効なAPIとサービス」でGoogle Calendar APIを有効にする
 
  - プロジェクトの「Google Auth Platform / オーディエンス」を開く
 
    - 左側メニューの「クライアント」で「OAuth 2.0 クライアント ID」を作る
 
      - アプリの種類はiOS
 
      - 名前はデフォルトでOk
   
      - バンドルIDは先に決めたiOSアプリのそれ

      - 作成すると `plist` ファイルをダウンロードできるようになるので適宜保存する

    - (上の流れで自動遷移するかもしれないが) 関連して色々設定

      - 左側メニューの「ブランディング」で
  
        - アプリ名を入力 (任意のようだが念のため今回はバンドルIDに合わせて `GoogleCalendarAPIDemo`)
   
        - ユーザーサポートメール (デベロッパーの連絡先情報) を入力
       
          - 今回はGoogle Cloud管理者と同じにした

      - 左側メニューの「対象」で
  
        - 公開ステータスは「テスト中」に
   
        - ユーザーの種類は「外部」に
   
        - テストユーザーにGoogle Calendarのユーザーのメールアドレスを追加
   
          - もしかすると、そのユーザーのセキュリティ設定が甘いとテスト失敗するかもしれない
     
          - 今回はGoogle Cloud管理者自身とし「2段階認証」「再設定用Tel」「再設定用email」いずれも有りで成功した

      - 左側メニューの「データアクセス」でスコープを設定できるが、今回はテストのためスキップ

<br>

- ビルド準備 (Xcodeでプロジェクトを開いて以降の手順)

  - 先のテスト準備でダウンロードした `plist` ファイルを `GoogleInfo.plist` にリネームしソースの `Assets` ディレクトリに追加
 
  - TARGETS > Signing & Capabilities で `Team` を開発者自身に、`Bundle Identifier` を先のテスト準備で決めたものに変更
 
  - TARGETS > Info で `URL Types` を追加し `URL Schemes` に `GoogleInfo.plist` の `REVERSED_CLIENT_ID` の値を入力
 
- 以上でビルドが通りアプリが起動し左下に Sign In のテキストリンクが表示されていれば使う準備完了

<br>

- テスト手順

  - アプリ起動後、左下 Sign In をタップすると最初のモーダルが出る

    <img width=192 src="https://github.com/user-attachments/assets/ea61d004-cd81-4ce4-824b-1ef2a8e1aa72" />

  - Continueを押すとGoogleアカウントの選択モーダルが現れる
 
    - 同じ画面が、下方にある動画 (fork元からあるもの) 0:11〜0:12頃にある
 
  - もろもろ承認して進むと最終的にそのGoogleアカウントのカレンダー情報が出る
 
    - まず当該アカウントに属するカレンダーの選択メニューになる

    - その後の画面は、下方にある動画 0:13以降を参照
   
    - カレンダーに情報が少ないと情報がほとんど出ないが、API連携は出来ている
 
  - 右上のユーザーアイコンをタップすると、最下部にログアウトボタンがある
 
<br>

不具合等の連絡・問合せは[プロフィール](https://github.com/ec22s)のメールアドレスまでお願いします

以下、fork元のREADME

---

# Google Calendar API Demo
### Built on SwiftUI using GoogleSignIn and GoogleAPIClientForREST

This app is built to show all the events associated with a google account.


## Demo Video


https://user-images.githubusercontent.com/32486561/203391101-c55a6c7a-7629-416c-8b7d-1c4920833bed.mp4




## Features

- Sign in via Google
- Accept Calendar Permissions
- All the calendar data gets synced to the app.
- Users can view all the calendars they have
- Users can view all the events associated with a calendar
- Filter events by Year and Month
- Search for calendars and events from spotlight
- Supports `iOS`, `iPadOS`, `macOS` (Supports Mac Catalyst)

## Tech

This demo uses a number of open source projects to work properly:

- [GoogleSignIn-iOS](https://github.com/google/GoogleSignIn-iOS) - Enables iOS and macOS apps to sign in with Google.
- [GoogleAPIClientForRest](https://github.com/google/google-api-objectivec-client-for-rest) - Google API Client in ObjC to fetch API data for google services
- [Lottie](https://github.com/airbnb/lottie-ios) - An iOS library to natively render After Effects vector animations.
- [Core Spotlight](https://developer.apple.com/documentation/corespotlight) - Indexing app so users can search the content from Spotlight and Safari.
- [Core Services](https://developer.apple.com/documentation/coreservices/) - Access and manage key operating system services, such as launch and identity services.

And of course this demo app itself is open source with a [public repository](https://github.com/ipratikk-work/Google-Calendar-API-Demo/) on GitHub.

## Installation

- Minimum Xcode version - `13.2`
- Minimum Deployment Version
    - iOS - `15.2`
    - macOS - `12.1`
- Fetch Google Auth 2.0 token from [Google cloud console](https://console.cloud.google.com/apis/credentials).
- Enable Calendar API
- Modify OAuth 2.0 token and add calendar scopes, as required.
- Add testers to the OAuth token
- Create API key with the app bundle identifier
- Download the OAuth 2.0 plist file and add to project
- Rename the Plist file to `GoogleInfo.plist`
- Install the packages via `SPM (Swift Package Manager)` or Wait for the packages to be resolved automatically

Install the dependencies and devDependencies and build the application.

## Development

Want to contribute? Great!

This app uses `SwiftUI + Combine` for binding data and creating the UI.


### Work In Progress
- Deeplink for events in spotlight
- Optimising indexing of events in spotlight
- Using a Watch for Google calendar instead of timed API calls (Unable to get proper documentation on this in [GoogleAPIClientForRest](https://github.com/google/google-api-objectivec-client-for-rest))

> **Open to contributions and enhancements on the project**

## License

MIT

**Free Software, Hell Yeah!**
