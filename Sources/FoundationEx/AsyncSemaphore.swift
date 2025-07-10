//
//  AsyncSemaphore.swift
//  FoundationEx
//
//  Created by Ilya Belenkiy on 6/12/25.
//

public actor AsyncSemaphore {
    let maxCount: Int
    private var count: Int = 0
    private var continuations: Array<CheckedContinuation<Void, Never>> = []
    
    public init(maxCount: Int) {
        self.maxCount = maxCount
    }
    
    public func aquire() async {
        if count < maxCount {
            count += 1
        }
        else {
            await withCheckedContinuation { continuation in
                self.continuations.append(continuation)
            }
            count += 1
        }
    }
    
    public func release() {
        count -= 1
        if !continuations.isEmpty {
            let continuation = continuations.removeFirst()
            continuation.resume()
        }
    }
}
