//
//  ImageCache.swift
//  ExCache
//
//  Created by 강동영 on 7/31/24.
//

import UIKit.UIImage

protocol CacheProtocol {
    func store(_ image: UIImage, forKey key: String)
    func retrieve(forKey key: String) -> UIImage?
    func remove(forKey key: String)
    func removeAll()
}

final class ImageCache: CacheProtocol {
    static let shared: ImageCache = ImageCache()
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCache = DiskCache()
    
    func store(_ image: UIImage, forKey key: String) {
        memoryCache.setObject(image, forKey: key as NSString)
        diskCache.store(image, forKey: key)
    }
    
    func retrieve(forKey key: String) -> UIImage? {
        // 6. 다음 번 요청시에는 메모리 캐시에서 이미지를 불러옴
        if let imageFromMemory = memoryCache.object(forKey: key as NSString) {
            // 2. 메모리 캐시에서 해당 이미지를 검색
            print("cache hit")
            return imageFromMemory
        } else if let imageFromDisk = diskCache.retrieve(forKey: key) {
            // 3. 없는 경우, 디스크 캐시에서 해당 이미지를 검색
            // 7. 프로세스(앱) 재시작 이후의 요청에는 디스크 캐시에서 불러온 후 메모리 캐시에 추가
            memoryCache.setObject(imageFromDisk, forKey: key as NSString)
            print("cache hit")
            return imageFromDisk
        } else {
            // 4. 없는 경우, URLString으로 이미지를 네트워크 다운로드
            print("cache miss")
            return nil
        }
    }
    
    func remove(forKey key: String) {
        memoryCache.removeObject(forKey: key as NSString)
    }
    
    func removeAll() {
        memoryCache.removeAllObjects()
    }
}
