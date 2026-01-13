// File: entry/src/main/ets/pages/Index.ets

import { promptAction } from '@kit.ArkUI';
import { imageService, ImageItem } from '../common/ImageService';
import { ImageCard } from '../components/ImageCard';

interface CategoryItem {
  title: string;
  key: string;
}


const CATEGORIES: CategoryItem[] = [
  { title: 'Scenery', key: 'fengjing' },
  { title: 'Anime', key: 'dongman' },
  { title: 'Portrait', key: 'meizi' },
  // { title: 'Cosplay', key: 'cos' },
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
      
      promptAction.showToast({ message: 'Loading more...' });
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
      
      let msg: string = 'Failed to load, please try again later';
      if (error instanceof Error) {
        msg = `Failed to load: ${error.message}`;
      }
      promptAction.showToast({ message: msg });
    } finally {
      this.isLoading = false;
    }
  }

  @Builder CustomTabs(categories: CategoryItem[]) {
    Row() {
      ForEach(categories, (item: CategoryItem, idx: number) => {
        Column() {
          Text(item.title)
            .fontSize(16)
            .padding({ top: 12, bottom: 12, left: 16, right: 16 })
            .fontWeight(this.currentTabIndex === idx ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.currentTabIndex === idx ? '#007DFF' : Color.Black)
            .onClick(() => {
              if (this.currentTabIndex !== idx) {
                this.currentTabIndex = idx;
                this.imageList = [];
                this.loadData(true);
              }
            })

          if (this.currentTabIndex === idx) {
            Divider().strokeWidth(2).color('#007DFF').width('50%')
          }
        }
      })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.SpaceAround)
  }

  build() {
    Column({ space: 0 }) {
      this.CustomTabs(CATEGORIES)

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

      if (this.isLoading && this.imageList.length === 0) {
        Column() {
          Progress({ value: 0, type: ProgressType.Ring }).width(40).height(40).color(0x007DFF)
          
          Text('Loading...').margin({ top: 10 }).fontColor(Color.Gray)
        }.width('100%').justifyContent(FlexAlign.Center).layoutWeight(1)

      } else {
        if (this.isLoading) {
          Row({ space: 10 }) {
            Progress({ value: 0, type: ProgressType.Ring })
              .width(24).height(24).color(0x007DFF)
            
            Text('Loading...')
          }
          .height(50).margin({ top: 10, bottom: 10 })
          .justifyContent(FlexAlign.Center)
        } else {
          
          Button('Load More', { type: ButtonType.Capsule, stateEffect: true })
            .width('80%').height(40).margin({ top: 10, bottom: 10 })
            .backgroundColor(0x007DFF)
            .onClick(() => this.loadData(false))
        }
      }
    }
    .width('100%').height('100%').backgroundColor(0xF1F3F5)
  }
}