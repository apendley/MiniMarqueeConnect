//
//  RequestLocalNetworkAuthorization.swift
//  Nonstrict
//
//  Created by Nonstrict on 10/01/2024.
//  See article: https://nonstrict.eu/blog/2024/request-and-check-for-local-network-permission/
//  original source: https://gist.github.com/mac-cain13/fa684f54a7ae1bba8669e78d28611784
//
//  Modified by Aaron Pendley on 2/05/25:
//      * Put function on main actor and change 'resume' closure to do its work on a MainActor task to compile for Swift 6.
//      * Throw LocalNetworkAuthorizationDenied error when request is denied instead of returning a boolean value.
//      * On the simulator, just return immediately, since it doesn't seem to care about the authorization.

import Foundation
import Network
import OSLog

// APENDLEY: This is the error we want to catch when Local Network access is denied.
struct LocalNetworkAuthorizationDenied: Error { }

#if targetEnvironment(simulator)

@MainActor
func requestLocalNetworkAuthorization() async throws {
    // APENDLEY: The simulator doesn't seem to care about this permission, so let's skip it.
}

#else

private let logger: Logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.nonstrict.localNetworkAuthCheck", category: #fileID)
private let bonjourType = "_preflight_check._tcp"

@MainActor
func requestLocalNetworkAuthorization() async throws {
    let queue = DispatchQueue(label: "com.nonstrict.localNetworkAuthCheck")

    logger.info("Setup listener.")
    let listener = try NWListener(using: NWParameters(tls: .none, tcp: NWProtocolTCP.Options()))
    listener.service = NWListener.Service(name: UUID().uuidString, type: bonjourType)
    // Must be set or else the listener will error with POSIX error 22
    listener.newConnectionHandler = { _ in }

    logger.info("Setup browser.")
    let parameters = NWParameters()
    parameters.includePeerToPeer = true
    let browser = NWBrowser(for: .bonjour(type: bonjourType, domain: nil), using: parameters)
    
    var hasResumed = false

    return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let resume: @Sendable (Result<Void, Error>) -> Void = { result in
                // APENDLEY: I wrapped this in a MainActor task because I haven't figured out another way to modify 'hasResumed'
                // so we can use it as a flag to only trigger the continuation once. There's probably a better way.
                Task { @MainActor in
                    if hasResumed {
                        logger.warning("Already resumed, ignoring subsequent result.")
                        return
                    }
                    
                    hasResumed = true
                    
                    // Teardown listener and browser
                    listener.stateUpdateHandler = { _ in }
                    browser.stateUpdateHandler = { _ in }
                    browser.browseResultsChangedHandler = { _, _ in }
                    listener.cancel()
                    browser.cancel()
                    
                    continuation.resume(with: result)
                }
            }

            // Do not setup listener/browser is we're already cancelled, it does work but logs a lot of very ugly errors
            if Task.isCancelled {
                logger.notice("Task cancelled before listener & browser started.")
                resume(.failure(CancellationError()))
                return
            }

            listener.stateUpdateHandler = { newState in
                switch newState {
                case .setup:
                    logger.debug("Listener performing setup.")
                case .ready:
                    logger.notice("Listener ready to be discovered.")
                case .cancelled:
                    logger.notice("Listener cancelled.")
                    resume(.failure(CancellationError()))
                case .failed(let error):
                    logger.error("Listener failed, stopping. \(error, privacy: .public)")
                    resume(.failure(error))
                case .waiting(let error):
                    logger.warning("Listener waiting, stopping. \(error, privacy: .public)")
                    resume(.failure(error))
                @unknown default:
                    logger.warning("Ignoring unknown listener state: \(String(describing: newState), privacy: .public)")
                }
            }
            listener.start(queue: queue)

            browser.stateUpdateHandler = { newState in
                switch newState {
                case .setup:
                    logger.debug("Browser performing setup.")
                    return
                case .ready:
                    logger.notice("Browser ready to discover listeners.")
                    return
                case .cancelled:
                    logger.notice("Browser cancelled.")
                    resume(.failure(CancellationError()))
                case .failed(let error):
                    logger.error("Browser failed, stopping. \(error, privacy: .public)")
                    resume(.failure(error))
                case let .waiting(error):
                    switch error {
                    case .dns(DNSServiceErrorType(kDNSServiceErr_PolicyDenied)):
                        logger.notice("Browser permission denied, reporting failure.")
                        resume(.failure(LocalNetworkAuthorizationDenied()))
                    default:
                        logger.error("Browser waiting, stopping. \(error, privacy: .public)")
                        resume(.failure(error))
                    }
                @unknown default:
                    logger.warning("Ignoring unknown browser state: \(String(describing: newState), privacy: .public)")
                    return
                }
            }

            browser.browseResultsChangedHandler = { results, changes in
                if results.isEmpty {
                    logger.warning("Got empty result set from browser, ignoring.")
                    return
                }

                logger.notice("Discovered \(results.count) listeners, reporting success.")
                resume(.success(()))
            }
            browser.start(queue: queue)

            // Task cancelled while setting up listener & browser, tear down immediatly
            if Task.isCancelled {
                logger.notice("Task cancelled during listener & browser start. (Some warnings might be logged by the listener or browser.)")
                resume(.failure(CancellationError()))
                return
            }
        }
    } onCancel: {
        listener.cancel()
        browser.cancel()
    }
}

#endif
