//
//  AsyncTaskValue.swift
//  SunoScreenApp
//
//  Created by Ilya Belenkiy on 5/12/25.
//

public enum AsyncTaskValue<T, E: Error> {
    case notStarted
    case inProgress
    case success(T)
    case failure(E)

    public var value: T? {
        switch self {
        case .success(let value):
            return value
        default :
            return nil
        }
    }

    public var error: E? {
        switch self {
        case .failure(let error):
            return error
        default:
            return nil
        }
    }

    public var isInProgress: Bool {
        switch self {
        case .inProgress:
            return true
        default:
            return false
        }
    }

    public mutating func resetIfError() {
        if error != nil {
            self = .notStarted
        }
    }
}
