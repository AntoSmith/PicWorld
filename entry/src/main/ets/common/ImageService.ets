// File: entry/src/main/ets/common/ImageService.ets

import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

export interface ImageItem {
  id: string;
  imgurl: string;
  width: number;
  height: number;
}

// 此接口匹配COSPLAY API返回的JSON对象数组中的单个元素结构
interface ApiImageResponse {
  imgurl: string;
  width: string;
  height: string;
}

// 此接口专门用于匹配风景、动漫、真人分类API返回的JSON结构
interface ApiPhpJsonResponse {
  code: string;
  imgurl: string;
  width: string;
  height: string;
}


const BASE_URL = 'https://imgapi.cn/';

class ImageService {
  async fetchImages(category: 'meizi' | 'dongman' | 'fengjing'): Promise<ImageItem[]> {
    const requests: Promise<ApiImageResponse | null>[] = [];
    for (let i = 0; i < 10; i++) {
      //添加 zd=mobile 参数以获取移动端壁纸
      const url = `${BASE_URL}api.php?zd=mobile&fl=${category}&gs=json`;
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
      let response = await request.request(url, {
        method: http.RequestMethod.GET
      });

      if (response.responseCode === 200 && typeof response.result === 'string') {
        const resultStr = response.result.trim();
        if (resultStr && !resultStr.startsWith('<')) {
          const parsedResult: ApiPhpJsonResponse = JSON.parse(resultStr) as ApiPhpJsonResponse;
          if (parsedResult.code === "200") {
            return parsedResult;
          }
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