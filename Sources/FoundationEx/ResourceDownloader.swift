//
//  ResourceDownloader.swift
//  FoundationEx
//
//  Created by Ilya Belenkiy on 6/12/25.
//

import Foundation

public actor ResourceDownloader<T> {
    enum DownloadError: Error {
        case download(Error)
    }
    
    class TaskBox: NSObject {
        let task: Task<T, Error>
        
        init(task: Task<T, Error>) {
            self.task = task
        }
    }
    
    private let semaphore: AsyncSemaphore
    private let cache = NSCache<NSURL, TaskBox>()
    
    public init(maxConcurrentCount: Int) {
        semaphore = .init(maxCount: maxConcurrentCount)
    }
    
    private func download(url: URL) async throws -> Data {
        do {
            let (data, _) = try await URLSession.shared.data(for: .init(url: url))
            return data
        }
        catch {
            throw DownloadError.download(error)
        }
    }
    
    public func download(url: URL, process: @escaping (Data) async throws -> T) async throws -> T {
        if let box = cache.object(forKey: url as NSURL) {
            return try await box.task.value
        }
        
        await semaphore.aquire()
        let task = Task {
            defer {Task { await semaphore.release() } }
            
            let data = try await download(url: url)
            return try await process(data)
        }
        cache.setObject(TaskBox(task: task), forKey: url as NSURL)
        return try await task.value
    }
}
