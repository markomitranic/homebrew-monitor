import Foundation

struct BrewServiceInfo: Codable {
    let name: String
    let running: Bool
    let pid: Int?
    let user: String?
    let status: String?
    let file: String?
}

enum BrewError: LocalizedError {
    case brewNotFound
    case commandFailed(String)
    case decodingFailed(String)

    var errorDescription: String? {
        switch self {
        case .brewNotFound:
            return "Homebrew not found. Install it from https://brew.sh"
        case .commandFailed(let msg):
            return msg
        case .decodingFailed(let msg):
            return "Failed to parse brew output: \(msg)"
        }
    }
}

class BrewServiceManager {
    private let brewPath: String? = {
        let paths = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        return paths.first { FileManager.default.fileExists(atPath: $0) }
    }()

    private let queue = DispatchQueue(label: "com.markomitranic.homebrew-monitor.brew", qos: .userInitiated)

    func fetchServices(completion: @escaping (Result<[BrewServiceInfo], Error>) -> Void) {
        guard let brewPath else {
            DispatchQueue.main.async { completion(.failure(BrewError.brewNotFound)) }
            return
        }

        queue.async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = ["services", "info", "--all", "--json"]

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(BrewError.commandFailed(error.localizedDescription)))
                }
                return
            }

            let data = stdout.fileHandleForReading.readDataToEndOfFile()

            if process.terminationStatus != 0 {
                let errText = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
                DispatchQueue.main.async {
                    completion(.failure(BrewError.commandFailed(errText.trimmingCharacters(in: .whitespacesAndNewlines))))
                }
                return
            }

            do {
                let services = try JSONDecoder().decode([BrewServiceInfo].self, from: data)
                let sorted = services.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                DispatchQueue.main.async { completion(.success(sorted)) }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(BrewError.decodingFailed(error.localizedDescription)))
                }
            }
        }
    }

    func startService(_ name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        runBrewCommand(["services", "start", name], completion: completion)
    }

    func stopService(_ name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        runBrewCommand(["services", "stop", name], completion: completion)
    }

    private func runBrewCommand(_ arguments: [String], completion: @escaping (Result<Void, Error>) -> Void) {
        guard let brewPath else {
            DispatchQueue.main.async { completion(.failure(BrewError.brewNotFound)) }
            return
        }

        queue.async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = arguments

            let stderr = Pipe()
            process.standardError = stderr
            process.standardOutput = Pipe()

            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(BrewError.commandFailed(error.localizedDescription)))
                }
                return
            }

            if process.terminationStatus != 0 {
                let errText = String(data: stderr.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? "Unknown error"
                DispatchQueue.main.async {
                    completion(.failure(BrewError.commandFailed(errText.trimmingCharacters(in: .whitespacesAndNewlines))))
                }
            } else {
                DispatchQueue.main.async { completion(.success(())) }
            }
        }
    }
}
