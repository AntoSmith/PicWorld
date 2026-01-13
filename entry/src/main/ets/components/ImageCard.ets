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
            Text('Loading...').fontSize(12).fontColor(Color.Gray)
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
                  promptAction.showToast({ message: 'Authorization failed, unable to save.' });
                }
              })
              // .backgroundColor('#5F000000') /*色差阈值测试*/
              // .fontColor('#9900203F')
              // .iconColor('#9900203F')
              // .fontColor('#004000')
              // .iconColor('#004000')

              // .backgroundColor('#16165C') /*透明度测试*/
              // .fontColor('#1818a2')
              // .iconColor('#1818a2')

              // .backgroundColor('#000000') /*蓝色陷阱*/
              // .fontColor('#000032')
              // .iconColor('#000032')
              // .fontColor('#004000')
              // .iconColor('#004000')

              .backgroundColor('#eceef0')
              .fontColor('#FF93BFEC') /*nomal*/
              .iconColor('#FF93BFEC')
              // .fontColor('#007DFF')  /*focused*/
              // .iconColor('#007DFF')

              // .backgroundColor('#2e2e5c') /*bypass*/
              // .fontColor('#991818a2')
              // .iconColor('#991818a2')
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
    promptAction.showToast({ message: 'Start downloading and saving...' });
    // 为确保资源释放，预先声明变量
    let imageSource: image.ImageSource | undefined = undefined;
    let pixelMap: image.PixelMap | undefined = undefined;
    let imagePacker: image.ImagePacker | undefined = undefined;
    let fileDescriptor: number | undefined = undefined;

    try {
      // 1. 下载网络图片
      let request = http.createHttp();
      let response = await request.request(imageUrl, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      });

      if (response.responseCode === 200 && response.result) {
        const imageBuffer = response.result as ArrayBuffer;


        // 2. 从图片数据中获取真实的MIME类型和文件扩展名，而不是从URL解析
        imageSource = image.createImageSource(imageBuffer);
        const imageInfo = await imageSource.getImageInfo();
        const mimeType = imageInfo.mimeType; // 例如: 'image/jpeg'
        let fileExtension = mimeType.split('/')[1]; // 例如: 'jpeg'
        if (fileExtension === 'jpeg') {
          fileExtension = 'jpg'; // 规范化为 'jpg'，因为 'jpg' 更常用作文件后缀
        }

        // 3. 使用从图片数据中获取到的、可靠的扩展名创建媒体库资产
        const helper = photoAccessHelper.getPhotoAccessHelper(context);
        const uri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, fileExtension);
        const file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
        fileDescriptor = file.fd;

        // 4. 将图片数据打包并使用正确的MIME类型写入文件
        pixelMap = await imageSource.createPixelMap();
        imagePacker = image.createImagePacker();
        const packOpts: image.PackingOption = { format: mimeType, quality: 100 };
        await imagePacker.packToFile(pixelMap, fileDescriptor, packOpts);

        promptAction.showToast({ message: 'Saved to gallery!' });
      } else {
        throw new Error(`Download failed: ${response.responseCode}`);
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`Save failed. Code: ${err.code}, message: ${err.message}`);
      promptAction.showToast({ message: `Save failed: ${err.message}` });
    } finally {
      // 5. 增加 finally 块，确保所有创建的资源在操作结束后（无论成功或失败）都被释放
      if (fileDescriptor !== undefined) {
        await fileIo.close(fileDescriptor);
      }
      imagePacker?.release();
      pixelMap?.release();
      imageSource?.release();
    }
  }
}