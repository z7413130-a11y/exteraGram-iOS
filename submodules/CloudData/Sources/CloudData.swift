import Foundation
import CloudKit
import MtProtoKit
import SwiftSignalKit
import EncryptionProvider

private enum FetchError {
    case generic
    case temporary(retryAfter: Double)
}

@available(iOS 10.0, *)
private func fetchRawData(prefix: String, database: CKDatabase) -> Signal<Data, FetchError> {
    return Signal { subscriber in
        let recordId = CKRecord.ID(recordName: "emergency-datacenter-\(prefix)")
        database.fetch(withRecordID: recordId, completionHandler: { record, error in
            if let error = error as? CKError {
                switch error.code {
                case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
                    subscriber.putError(.temporary(retryAfter: max(60.0, error.retryAfterSeconds ?? 0.0)))
                default:
                    subscriber.putError(.generic)
                }
            } else if error != nil {
                subscriber.putError(.generic)
            } else if let record = record {
                guard let dataString = record.object(forKey: "data") as? String else {
                    subscriber.putError(.generic)
                    return
                }
                guard let data = Data(base64Encoded: dataString, options: [.ignoreUnknownCharacters]) else {
                    subscriber.putError(.generic)
                    return
                }
                var resultData = data
                resultData.count = 256
                subscriber.putNext(resultData)
                subscriber.putCompletion()
            } else {
                subscriber.putError(.generic)
            }
        })
        
        return ActionDisposable {
        }
    }
}

@available(iOS 10.0, *)
private final class CloudDataPrefixContext {
    private let prefix: String
    private let database: CKDatabase
    private let queue: Queue
    private let value = Promise<Data?>()
    private var nextRequestTimestamp: Double = 0.0

    init(prefix: String, database: CKDatabase, queue: Queue) {
        self.prefix = prefix
        self.database = database
        self.queue = queue
    }

    func get() -> Signal<Data?, NoError> {
        let timestamp = CFAbsoluteTimeGetCurrent()
        if timestamp >= self.nextRequestTimestamp {
            self.nextRequestTimestamp = timestamp + 60.0
            self.value.set(fetchRawData(prefix: self.prefix, database: self.database)
            |> map(Optional.init)
            |> deliverOn(self.queue)
            |> `catch` { [weak self] error -> Signal<Data?, NoError> in
                if case let .temporary(retryAfter) = error {
                    self?.nextRequestTimestamp = CFAbsoluteTimeGetCurrent() + retryAfter
                }
                return .single(nil)
            }
            |> timeout(8.0, queue: self.queue, alternate: .single(nil))
            |> take(1))
        }
        return self.value.get()
    }
}

@available(iOS 10.0, *)
private final class CloudDataContextObject {
    private let queue: Queue
    private lazy var database: CKDatabase? = CloudDataContextImpl.configuredContainerIdentifier().map {
        CKContainer(identifier: $0).publicCloudDatabase
    }

    private var prefixContexts: [String: CloudDataPrefixContext] = [:]
    
    init(queue: Queue) {
        self.queue = queue
    }
    
    func get(prefix: String) -> Signal<Data?, NoError> {
        guard let database = self.database else {
            return .single(nil)
        }
        if let context = self.prefixContexts[prefix] {
            return context.get()
        }
        let context = CloudDataPrefixContext(prefix: prefix, database: database, queue: self.queue)
        self.prefixContexts[prefix] = context
        return context.get()
    }
}

public protocol CloudDataContext {
    func get(phoneNumber: Signal<String?, NoError>) -> Signal<MTBackupDatacenterData, NoError>
}

@available(iOS 10.0, *)
public final class CloudDataContextImpl: CloudDataContext {
    /// The iOS packaging configuration declares this only for builds that are intended
    /// to be signed with the corresponding iCloud container entitlement.
    public static func configuredContainerIdentifier(bundle: Bundle = .main) -> String? {
        guard let bundleIdentifier = bundle.bundleIdentifier,
              let container = bundle.object(forInfoDictionaryKey: "TelegramCloudKitContainer") as? String,
              container == "iCloud.\(bundleIdentifier)" else {
            return nil
        }
        return container
    }

    private let queue = Queue()
    private let encryptionProvider: EncryptionProvider
    private let impl: QueueLocalObject<CloudDataContextObject>
    
    public init(encryptionProvider: EncryptionProvider) {
        self.encryptionProvider = encryptionProvider
        
        let queue = self.queue
        self.impl = QueueLocalObject(queue: queue, generate: {
            return CloudDataContextObject(queue: queue)
        })
    }
    
    public func get(phoneNumber: Signal<String?, NoError>) -> Signal<MTBackupDatacenterData, NoError> {
        let encryptionProvider = self.encryptionProvider
        return phoneNumber
        |> take(1)
        |> mapToSignal { phoneNumber -> Signal<MTBackupDatacenterData, NoError> in
            var prefix = ""
            if let phoneNumber = phoneNumber, phoneNumber.count >= 1 {
                prefix = String(phoneNumber[phoneNumber.startIndex ..< phoneNumber.index(after: phoneNumber.startIndex)])
            }
            return Signal { subscriber in
                let disposable = MetaDisposable()
                self.impl.with { impl in
                    disposable.set(impl.get(prefix: prefix).start(next: { data in
                        if let data = data, let datacenterData = MTIPDataDecode(encryptionProvider, data, phoneNumber ?? "") {
                            subscriber.putNext(datacenterData)
                            subscriber.putCompletion()
                        } else {
                            subscriber.putCompletion()
                        }
                    }))
                }
                return disposable
            }
        }
    }
}
