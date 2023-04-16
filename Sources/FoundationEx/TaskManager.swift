//
//  TaskManager.swift
//
//  Created by Ilya Belenkiy on 4/16/23.
//

import Foundation

public actor TaskManager {
    private typealias ActionTask = Task<Void, Never>

    private enum TaskBox {
        case willStart
        case inProgress(ActionTask)
        
        func cancelTask() {
            switch self {
            case .inProgress(let task):
                task.cancel()
            default:
                return
            }
        }
    }

    private var tasks: [UUID: TaskBox] = [:]
    
    public init() {}
    
    deinit {
        for (_, box) in tasks {
            box.cancelTask()
        }
        tasks.removeAll()
    }
    
    private func removeTask(id: UUID) {
        tasks.removeValue(forKey: id)
    }
    
    public func addTask(_ f: @escaping () async -> Void) {
        let id = UUID()
        tasks[id] = .willStart
        let task = Task { [weak self] in
            await f()
            await self?.removeTask(id: id)
        }
        
        if (self.tasks[id] != nil) && !task.isCancelled {
            self.tasks[id] = .inProgress(task)
        }
    }
}
