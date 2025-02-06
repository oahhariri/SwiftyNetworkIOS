//
//  Logger.swift
//  SwiftyNetworkIOS
//
//  Created by Abdulrahman Hariri on 18/02/1444 AH.
//

import Foundation

public enum LoggerLevel: Int {
    case none = 0
    case error
    case info
    case debug
}

internal class Logger {
    static let shared = Logger()
    internal var logLevel: LoggerLevel = .none

    func debug(_ log: String) {
        guard logLevel.rawValue >= LoggerLevel.debug.rawValue else { return }
        print("[SwiftyNetworkIOS] = \(utcToLocal()) \(Thread.isMainThread ? "⬜️" : "⬜️🔹") Debug: \(log)")
    }

    func info(_ log: String) {
        guard logLevel.rawValue >= LoggerLevel.info.rawValue else { return }
        print("[SwiftyNetworkIOS] = \(utcToLocal()) \(Thread.isMainThread ? "⚠️" : "⚠️🔹") Info: \(log)")
    }

    func error(_ log: String) {
        guard logLevel.rawValue >= LoggerLevel.error.rawValue else { return }
        print("[SwiftyNetworkIOS] = \(utcToLocal()) \(Thread.isMainThread ? "🟥" : "🟥🔹") Error: \(log)")
    }

    private func utcToLocal() -> String {
        let dateFormatter = DateFormatter()

        dateFormatter.locale = Locale(identifier: "en_us")
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-mm-dd hh:mm:ss a"

        return dateFormatter.string(from: Date())
    }
}
