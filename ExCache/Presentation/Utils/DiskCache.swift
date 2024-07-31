//
//  DiskCache.swift
//  ExCache
//
//  Created by 강동영 on 7/31/24.
//

import UIKit.UIImage

protocol DiskCacheProtocol: CacheProtocol {
    var maximumDiskCapacity: Int { get }
    func cleanUpDiskCache()
}

final class DiskCache: DiskCacheProtocol {
    private let fileManager: FileManager
    private let cacheDirectoryURL: URL
    var maximumDiskCapacity: Int // 1024 * 1024 * 100 -> 100MB
    
    init(fileManager: FileManager = .default, maximumDiskCapacity: Int = 1024 * 1024 * 100) {
        self.fileManager = fileManager
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectoryURL = cacheDirectory.appendingPathComponent("DiskImageCache")
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            try? fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)
        }
        self.maximumDiskCapacity = maximumDiskCapacity
        
        // 캐시 정리
        cleanUpDiskCache()
    }
    
    func store(_ image: UIImage, forKey key: String) {
        let fileURL = cacheDirectoryURL.appendingPathComponent(key)
        guard let data = image.pngData() else { return }
        try? data.write(to: fileURL)
        // 캐시 정리
        cleanUpDiskCache()
    }
    
    func retrieve(forKey key: String) -> UIImage? {
        let fileURL = cacheDirectoryURL.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        updateLastAccessDate(with: fileURL)
        return image
    }
    
    private func updateLastAccessDate(with fileURL: URL) {
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
    }
    
    func remove(forKey key: String) {
        let fileURL = cacheDirectoryURL.appendingPathComponent(key)
        try? fileManager.removeItem(at: fileURL)
    }
    
    func removeAll() {
        try? fileManager.contentsOfDirectory(at: cacheDirectoryURL, includingPropertiesForKeys: nil).forEach {
            try fileManager.removeItem(at: $0)
        }
    }
    
    func cleanUpDiskCache() {
        let contents = try? fileManager.contentsOfDirectory(at: cacheDirectoryURL, includingPropertiesForKeys: [.contentAccessDateKey, .fileSizeKey])
        let filesAttributes = contents?.compactMap { url -> (url: URL, attributes: [FileAttributeKey: Any]?) in
            (url, try? fileManager.attributesOfItem(atPath: url.path))
        }
        
        // 총 파일 사이즈 계산
        let totalSize = filesAttributes?.reduce(0, { $0 + (($1.attributes?[.size] as? Int) ?? 0) }) ?? 0
        // 최대 용량을 초과한 경우, 가장 오래된 파일부터 삭제
        if totalSize > maximumDiskCapacity {
            let sortedFiles = filesAttributes?.sorted { lhs, rhs in
                let lhsDate = (lhs.attributes?[.modificationDate] as? Date) ?? Date.distantPast
                let rhsDate = (rhs.attributes?[.modificationDate] as? Date) ?? Date.distantPast
                return lhsDate < rhsDate
            }
            
            var currentSize = totalSize
            for file in sortedFiles ?? [] {
                if currentSize <= maximumDiskCapacity {
                    break
                }
                if let size = file.attributes?[.size] as? Int {
                    try? fileManager.removeItem(at: file.url)
                    currentSize -= size
                }
            }
        }
    }
}
