//
//  ViewController.swift
//  ExCache
//
//  Created by 강동영 on 7/22/24.
//

import UIKit

class ViewController: UIViewController {
    private let searchTextfield: UITextField = {
        let textfield: UITextField = .init(frame: .zero)
        textfield.translatesAutoresizingMaskIntoConstraints = false
        textfield.placeholder = "게임, 앱, 스토리 등"
        return textfield
    }()
    
    private lazy var tableView: UITableView = {
        let tableView: UITableView = .init(frame: .zero)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(searchTextfield)
        NSLayoutConstraint.activate([
            searchTextfield.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchTextfield.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            searchTextfield.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
        ])
        let imageCache = ImageCache()
        let image = UIImage(named: "example")
        // 이미지 캐시에 저장
        imageCache["exampleKey"] = image
        // 이미지 캐시에서 가져오기
        if let cachedImage = imageCache["exampleKey"] {
            print("Cached Image: \(cachedImage)")
        }
        // 이미지 캐시에서 제거
        imageCache["exampleKey"] = nil
        //캐시 비우기
        imageCache.removeAll()
    }
    
    
}

extension ViewController {}

protocol DiskCacheProtocol {
    func value(forKey key: String) -> UIImage?
    func set(value: UIImage?, forKey key: String)
    func remove(forKey key: String)
    func clear()
    var maximumDiskCapacity: Int { get set }
}

final class DiskCache: DiskCacheProtocol {
    private let fileManager = FileManager.default
    private let cacheDirectoryURL: URL
    var maximumDiskCapacity: Int = 1024 * 1024 * 100 // 100MB
    
    init() {
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectoryURL = cacheDirectory.appendingPathComponent("DiskImageCache")
        
        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            try? fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)
        }
        
        // 캐시 정리
        cleanUpDiskCache()
    }
    
    func value(forKey key: String) -> UIImage? {
        let fileURL = cacheDirectoryURL.appendingPathComponent(key)
        if let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            // 파일 엑세스 날짜 업데이트
            updateLastAccessDate(fileURL: fileURL)
            return image
        }
        return nil
    }
    
    func set(value: UIImage?, forKey key: String) {
        let fileURL = cacheDirectoryURL.appendingPathComponent(key)
        if let image = value, let data = image.pngData() {
            try? data.write(to: fileURL)
            // 캐시 정리
            cleanUpDiskCache()
        }
    }
    
    func remove(forKey key: String) {
        let fileURL = cacheDirectoryURL.appendingPathComponent(key)
        try? fileManager.removeItem(at: fileURL)
    }
    
    func clear() {
        try? fileManager.contentsOfDirectory(at: cacheDirectoryURL, includingPropertiesForKeys: nil).forEach {
            try fileManager.removeItem(at: $0)
        }
    }
    
    private func updateLastAccessDate(fileURL: URL) {
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: fileURL.path)
    }
    
    private func cleanUpDiskCache() {
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
