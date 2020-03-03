# ios-mobile-ffmpeg-demo
mobile-ffmpegを利用して、動画や音声を加工するサンプル

### 利用ライブラリ
[mobile-ffmepg]([https://github.com/tanersener/mobile-ffmpeg)

### 設定
XXX--Bridging-Header.h

```
#import <mobileffmpeg/MobileFFmpegConfig.h>
#import <mobileffmpeg/MobileFFmpeg.h>
```

### 実装

```
    // ffmpegのコマンドを実行する
    let command = "-i \(fromUrl) -vf scale=320:-1 -r 10 -an \(toUrl)"
    let result = MobileFFmpeg.execute(command)

    if (result == RETURN_CODE_SUCCESS) {
        print("Command execution completed successfully.\n");
    } else if (result == RETURN_CODE_CANCEL) {
        print("Command execution cancelled by user.\n");
    } else {
        print(MobileFFmpegConfig.getLastCommandOutput() ?? "");
    }

```
