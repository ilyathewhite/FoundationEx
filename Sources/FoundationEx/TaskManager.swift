//
//  TaskManager.swift
//
//  Created by Ilya Belenkiy on 4/16/23.
//

import Foundation

@MainActor
public class TaskManager {
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
    private var inFlightTaskIDs: [String: UUID] = [:]

    public init() {}
    
    deinit {
        for (_, box) in tasks {
            box.cancelTask()
        }
    }
    
    public func cancelAllTasks() {
        for (_, box) in tasks {
            box.cancelTask()
        }
    }
    
    public func addTask(cancellingPreviousWithKey key: String? = nil, _ f: @escaping () async -> Void) {
        if let key, let id = inFlightTaskIDs[key], case let .inProgress(task) = tasks[id] {
            task.cancel()
        }

        let id = UUID()
        tasks[id] = .willStart
        if let key {
            inFlightTaskIDs[key] = id
        }

        // The annotation below ensures that the task runs on the main actor across
        // Swift versions. Prior to Swift 6, Task initializers didn't inherit the
        // surrounding actor isolation.
        let task = Task { @MainActor [weak self] in
            // Exit early if this task is no longer current for the key.
            if let key, self?.inFlightTaskIDs[key] != id { return }

            await f()
            guard let self else { return }
            tasks.removeValue(forKey: id)
            if let key, inFlightTaskIDs[key] == id {
                inFlightTaskIDs.removeValue(forKey: key)
            }
        }
        
        if (tasks[id] != nil) && !task.isCancelled {
            tasks[id] = .inProgress(task)
        }
    }
}

