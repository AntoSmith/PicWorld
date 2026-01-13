--- HarmonyOS ArkTS 核心逻辑与UI页面 ---

```typescript
// File: entry/src/main/ets/entryability/EntryAbility.ets

import { AbilityConstant, ConfigurationConstant, UIAbility, Want, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

const DOMAIN = 0x0000;

// 定义需要申请的权限列表
const permissions: Array<Permissions> = [
  'ohos.permission.READ_MEDIA',
  'ohos.permission.WRITE_MEDIA',
  'ohos.permission.MEDIA_LOCATION',
  'ohos.permission.WRITE_IMAGEVIDEO'
];

// 向用户申请权限
function reqPermissionsFromUser(permissions: Array<Permissions>, context: UIAbility): void {
  let atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
  // requestPermissionsFromUser会判断权限的授权状态来决定是否唤起弹窗
  atManager.requestPermissionsFromUser(context.context, permissions).then((data) => {
    let grantStatus: Array<number> = data.authResults;
    let length: number = grantStatus.length;
    for (let i = 0; i < length; i++) {
      if (grantStatus[i] === 0) {
        // 用户授权，可以继续访问目标操作
        hilog.info(DOMAIN, 'testTag', '用户授予权限：%{public}s', permissions[i]);
      } else {
        // 用户拒绝授权
        hilog.info(DOMAIN, 'testTag', '用户拒绝权限：%{public}s', permissions[i]);
      }
    }
  }).catch((err: BusinessError) => {
    hilog.error(DOMAIN, 'testTag', '申请权限失败。错误码：%{public}d，错误信息：%{public}s', err.code, err.message);
  });
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      
      // 在Content加载完成后申请权限
      reqPermissionsFromUser(permissions, this);
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
```

```typescript
// File: entry/src/main/ets/pages/Index.ets

import { promptAction } from '@kit.ArkUI';
import { imageService, ImageItem } from '../common/ImageService';
import { ImageCard } from '../components/ImageCard';

interface CategoryItem {
  title: string;
  key: string;
}

const CATEGORIES: CategoryItem[] = [
  { title: '风景', key: 'fengjing' },
  { title: '动漫', key: 'dongman' },
  { title: '真人', key: 'meizi' },
  { title: 'Cosplay', key: 'cos' },
];

@Entry
@Component
struct Index {
  @State imageList: ImageItem[] = [];
  @State isLoading: boolean = false;
  @State currentTabIndex: number = 0;

  async aboutToAppear() {
    this.loadData(true);
  }

  async loadData(isRefresh: boolean) {
    if (this.isLoading) return;
    this.isLoading = true;
    if (!isRefresh) {
      promptAction.showToast({ message: '正在加载更多...' });
    }

    const category = CATEGORIES[this.currentTabIndex];
    let newImages: ImageItem[] = [];

    try {
      if (category.key === 'cos') {
        newImages = await imageService.fetchCosImages();
      } else {
        newImages = await imageService.fetchImages(category.key as 'fengjing' | 'dongman' | 'meizi');
      }

      if (isRefresh) {
        this.imageList = newImages;
      } else {
        this.imageList = this.imageList.concat(newImages);
      }
    } catch (error) {
      let msg: string = '加载失败，请稍后重试';
      if (error instanceof Error) {
        msg = `加载失败: ${error.message}`;
      }
      promptAction.showToast({ message: msg });
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column({ space: 0 }) {
      Tabs({
        barPosition: BarPosition.Start,
        index: this.currentTabIndex
      }) {
        ForEach(CATEGORIES, (item: CategoryItem, idx: number) => {
          TabContent() {
            Column({ space: 0 }) {
              // 用List代替WaterFlow
              List({ space: 10 }) {
                ForEach(this.imageList, (img: ImageItem) => {
                  ListItem() {
                    ImageCard({ imageItem: img })
                  }
                }, (img: ImageItem) => img.id)
              }
              .width('100%')
              .layoutWeight(1)
              .padding({ left: 5, right: 5, top: 10 })

              if (this.isLoading) {
                Row({ space: 10 }) {
                  Progress({ value: 0, type: ProgressType.Ring })
                    .width(24).height(24).color(0x007DFF)
                  Text('加载中...')
                }
                .height(40).margin({ top: 10, bottom: 10 })
                .justifyContent(FlexAlign.Center)
              } else {
                Button('加载更多', { type: ButtonType.Capsule, stateEffect: true })
                  .width('80%').height(40).margin({ top: 10, bottom: 10 })
                  .backgroundColor(0x007DFF)
                  .onClick(() => this.loadData(false))
              }
            }
            .width('100%').height('100%')
          }
        })
      }
      .onChange((index: number) => {
        this.currentTabIndex = index;
        this.loadData(true);
      })
    }
    .width('100%').height('100%').backgroundColor(0xF1F3F5)
  }
}
```

```typescript
// File: entry/src/main/ets/entrybackupability/EntryBackupAbility.ets

import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';

const DOMAIN = 0x0000;

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup() {
    hilog.info(DOMAIN, 'testTag', 'onBackup ok');
    await Promise.resolve();
  }

  async onRestore(bundleVersion: BundleVersion) {
    hilog.info(DOMAIN, 'testTag', 'onRestore ok %{public}s', JSON.stringify(bundleVersion));
    await Promise.resolve();
  }
}
```

```typescript
// File: entry/src/main/ets/common/ImageService.ets

// File: entry/src/main/ets/common/ImageService.ets

import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface ImageItem {
  id: string;
  imgurl: string;
  width: number;
  height: number;
}

interface ApiImageResponse {
  imgurl: string;
  width: string;
  height: string;
}

// FIX: 移除了不再需要的 HttpHeader 接口

const BASE_URL = 'https://i18.net/';

class ImageService {
  async fetchImages(category: 'meizi' | 'dongman' | 'fengjing'): Promise<ImageItem[]> {
    const requests: Promise<ApiImageResponse | null>[] = [];
    for (let i = 0; i < 10; i++) {
      const url = `${BASE_URL}api.php?fl=${category}&gs=json`;
      requests.push(this.makeRequest(url));
    }
    const results = await Promise.all(requests);
    const validResults: ImageItem[] = [];
    results.forEach((item, index) => {
      if (item) {
        validResults.push({
          id: `${category}-${Date.now()}-${index}`,
          imgurl: item.imgurl,
          width: Number(item.width),
          height: Number(item.height)
        });
      }
    });
    return validResults;
  }

  async fetchCosImages(): Promise<ImageItem[]> {
    const url = `${BASE_URL}cos.php?return=jsonpro`;
    try {
      let request = http.createHttp();
      let response = await request.request(url, { method: http.RequestMethod.GET });
      if (response.responseCode === 200 && typeof response.result === 'string') {
        const data = JSON.parse(response.result) as ApiImageResponse[];
        const cosImages: ImageItem[] = data.map((item, index) => {
          return {
            id: `cos-${Date.now()}-${index}`,
            imgurl: item.imgurl,
            width: Number(item.width),
            height: Number(item.height)
          } as ImageItem;
        });
        return cosImages;
      }
      return [];
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Failed to fetch cos images. Code is ${error.code}, message is ${error.message}`);
      return [];
    }
  }

  private async makeRequest(url: string): Promise<ApiImageResponse | null> {
    try {
      let request = http.createHttp();
      // FIX: 明确指定 header 的类型为 Record<string, string> 以解决严格模式下的类型错误
      const header: Record<string, string> = { 'Referer': 'https://i18.net/' };
      let response = await request.request(url, {
        method: http.RequestMethod.GET,
        header: header
      });

      if (response.responseCode === 200 && typeof response.result === 'string') {
        // 在解析JSON前增加一个非空和非重定向判断
        const resultStr = response.result.trim();
        if (resultStr && !resultStr.startsWith('<')) {
          return JSON.parse(resultStr) as ApiImageResponse;
        }
      }
      return null;
    } catch (err) {
      const error = err as BusinessError;
      console.error(`Request failed for ${url}. Code is ${error.code}, message is ${error.message}`);
      return null;
    }
  }
}

export const imageService = new ImageService();
```

```typescript
// File: entry/src/main/ets/components/ImageCard.ets

// File: entry/src/main/ets/components/ImageCard.ets

import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { fileIo } from '@kit.CoreFileKit';
import { http } from '@kit.NetworkKit';
import { image } from '@kit.ImageKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ImageItem } from '../common/ImageService';

@Component
export struct ImageCard {
  @Prop imageItem: ImageItem;
  @State imageLoadSuccess: boolean = false;

  build() {
    Column() {
      Stack({ alignContent: Alignment.BottomEnd }) {
        // 网络图片
        Image(this.imageItem.imgurl)
          .objectFit(ImageFit.Cover)
          .borderRadius(10)
          .aspectRatio(this.imageItem.width / this.imageItem.height)
          .onComplete(() => {
            this.imageLoadSuccess = true;
          })
          .onError(() => {
            this.imageLoadSuccess = false;
          })

        // 加载中或失败时的占位符
        if (!this.imageLoadSuccess) {
          Column() {
            Image($r('app.media.startIcon'))
              .width(60).height(60).objectFit(ImageFit.Contain).margin({ bottom: 10 })
            Text('加载中...').fontSize(12).fontColor(Color.Gray)
          }
          .width('100%').height(150).backgroundColor(0xEFEFEF)
          .justifyContent(FlexAlign.Center).borderRadius(10)
        }

        // SaveButton必须在图片加载成功后才显示
        if (this.imageLoadSuccess) {
          // 使用Stack的padding来控制SaveButton的位置，因为它本身不支持margin
          Stack() {
            SaveButton()
              .onClick((event: ClickEvent, result: SaveButtonOnClickResult) => {
                if (result === SaveButtonOnClickResult.SUCCESS) {
                  const context = getContext(this) as common.UIAbilityContext;
                  this.saveNetworkImage(context, this.imageItem.imgurl);
                } else {
                  promptAction.showToast({ message: '授权失败，无法保存' });
                }
              })
          }
          .width('100%')
          .height('100%')
          .align(Alignment.BottomEnd)
          .padding({ right: 10, bottom: 10 })
        }
      }
    }
    .padding(5)
  }

  // 保存网络图片的逻辑
  async saveNetworkImage(context: common.UIAbilityContext, imageUrl: string) {
    promptAction.showToast({ message: '开始下载并保存...' });
    try {
      // 1. 下载网络图片 - 使用兼容性更好的 expectDataType
      let request = http.createHttp();
      let response = await request.request(imageUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER // 关键修正点
      });

      if (response.responseCode === 200 && response.result) {
        const imageBuffer = response.result as ArrayBuffer;
        const imageSource = image.createImageSource(imageBuffer);
        const pixelMap = await imageSource.createPixelMap();

        // 2. 使用SaveButton的临时授权创建文件
        const helper = photoAccessHelper.getPhotoAccessHelper(context);
        const fileExtension = imageUrl.split('.').pop() || 'jpg';
        const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, fileExtension);
        const file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);

        // 3. 将图片数据打包写入文件
        const imagePacker = image.createImagePacker();
        const packOpts: image.PackingOption = { format: `image/${fileExtension}`, quality: 100 };
        await imagePacker.packToFile(pixelMap, file.fd, packOpts);
        await fileIo.close(file.fd);
        imagePacker.release();

        promptAction.showToast({ message: '已保存至相册！' });
      } else {
        throw new Error(`下载失败: ${response.responseCode}`);
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`保存失败. Code: ${err.code}, message: ${err.message}`);
      promptAction.showToast({ message: `保存失败: ${err.message}` });
    }
  }
}
```

--- HarmonyOS 配置文件 ---

```json
// File: entry/src/main/resources/base/profile/main_pages.json

{
  "src": [
    "pages/Index"
  ]
}

```

```json5
// File: entry/src/main/module.json5

{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet",
      "2in1"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "requestPermissions": [
       {
        "name": "ohos.permission.INTERNET" 
      },
      {
        "name": "ohos.permission.WRITE_IMAGEVIDEO",
        "reason": "$string:app_name",
        "usedScene": {
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.MEDIA_LOCATION",
        "reason": "$string:app_name",
        "usedScene": {
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.READ_MEDIA",
        "reason": "$string:app_name",
        "usedScene": {
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.WRITE_MEDIA",
        "reason": "$string:app_name",
        "usedScene": {
          "when": "inuse"
        }
      }
    ],
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:layered_image",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    "extensionAbilities": [
      {
        "name": "EntryBackupAbility",
        "srcEntry": "./ets/entrybackupability/EntryBackupAbility.ets",
        "type": "backup",
        "exported": false,
        "metadata": [
          {
            "name": "ohos.extension.backup",
            "resource": "$profile:backup_config"
          }
        ]
      }
    ]
  }
}
```

```json5
// File: build-profile.json5

{
  "app": {
    "signingConfigs": [
      {
        "name": "default",
        "type": "HarmonyOS",
        "material": {
          "certpath": "C:\\Users\\Xiaohu Wang\\.ohos\\config\\default_MyApplication3_b7YVuJKPN6EvAf0j5uOAxrEgsDiyWL9xLfa9tLXE7dA=.cer",
          "keyAlias": "debugKey",
          "keyPassword": "0000001A1876C87C4975BC149AE02D882A475D5F09F91C4CBA21506DCDC4859C999780F57A8BE5B5C074",
          "profile": "C:\\Users\\Xiaohu Wang\\.ohos\\config\\default_MyApplication3_b7YVuJKPN6EvAf0j5uOAxrEgsDiyWL9xLfa9tLXE7dA=.p7b",
          "signAlg": "SHA256withECDSA",
          "storeFile": "C:\\Users\\Xiaohu Wang\\.ohos\\config\\default_MyApplication3_b7YVuJKPN6EvAf0j5uOAxrEgsDiyWL9xLfa9tLXE7dA=.p12",
          "storePassword": "0000001AE6C249244B847B4C8F0F5555F16ED3BF578FCFF8A07CCB138B5FB96CEEE30AF948380989932D"
        }
      }
    ],
    "products": [
      {
        "name": "default",
        "signingConfig": "default",
        "targetSdkVersion": "5.0.5(17)",
        "compatibleSdkVersion": "5.0.5(17)",
        "runtimeOS": "HarmonyOS",
        "buildOption": {
          "strictMode": {
            "caseSensitiveCheck": true,
            "useNormalizedOHMUrl": true
          }
        }
      }
    ],
    "buildModeSet": [
      {
        "name": "debug",
      },
      {
        "name": "release"
      }
    ]
  },
  "modules": [
    {
      "name": "entry",
      "srcPath": "./entry",
      "targets": [
        {
          "name": "default",
          "applyToProducts": [
            "default"
          ]
        }
      ]
    }
  ]
}
```


不论你进行如何修改，一定保证不会破坏已有的功能。
对于 ArkTS (.ets) 代码，如果只改动一个函数或组件，请给出完整的函数或@Component组件的代码，并清晰地指出我应该在哪个文件中进行替换。
对于 JSON 配置文件，请给出修改后的完整文件内容。
千万不要省略代码，要确保我可以直接复制粘贴来使用。
