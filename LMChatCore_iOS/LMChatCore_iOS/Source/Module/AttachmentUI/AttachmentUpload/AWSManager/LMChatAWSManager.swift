//
//  LMChatAWSManager.swift
//  lm-chatCore-iOS
//
//  Created by Devansh Mohata on 23/01/24.
//

import AWSS3
import LikeMindsChatData

/// Custom error type for upload-related errors
struct UploadError: Error {
    /// Descriptive message explaining the error
    let message: String
}

public protocol LMCDNProtocol: AnyObject {
    associatedtype progressBlock
    associatedtype completionBlock

    func uploadfile(
        fileUrl: URL, fileName: String, contenType: String,
        progress: progressBlock?, completion: completionBlock?)
    func uploadfile(
        fileData: Data, fileName: String, contenType: String,
        progress: progressBlock?, completion: completionBlock?)
}

final class LMChatAWSManager {
    private init() {}

    public static let shared = LMChatAWSManager()
    var storedUploadTasks: [String: [AWSS3TransferUtilityUploadTask]] = [:]

    public static func awsFilePathForConversation(
        chatroomId: String,
        attachmentType: String,
        fileExtension: String,
        filename: String,
        isThumbnail: Bool = false,
        uuid: String
    ) -> String {
        let name = filename.replacingOccurrences(of: " ", with: "_")
        let miliseconds = Int(Date().millisecondsSince1970)
        if isThumbnail {
            return
                "files/collabcard/\(chatroomId)/conversation/\(uuid)/thumb_\(name)_\(attachmentType)_\(miliseconds).jpeg"
        } else {
            return
                "files/collabcard/\(chatroomId)/conversation/\(uuid)/\(attachmentType)_\(name)_\(miliseconds).\(fileExtension)"
        }
    }

    typealias progressBlock = (_ progress: Double) -> Void
    typealias completionBlock = (_ response: String?, _ error: Error?) -> Void

    public func initialize() {
        let credentialsProvider = AWSStaticCredentialsProvider(
            accessKey: ServiceAPI.accessKey,
            secretKey: ServiceAPI.secretAccessKey)
        let configuration = AWSServiceConfiguration(
            region: .APSouth1, credentialsProvider: credentialsProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        // Start monitoring network connectivity
        NetworkReachability.startMonitoring()
    }

    func cancelAllTaskFor(groupId: String) {
        print("passed groupId: \(groupId)")
        print("All groupIds: \(storedUploadTasks.keys)")
        if let tasks = storedUploadTasks[groupId] {
            tasks.forEach { uploadTask in
                print("Cancelling task......")
                uploadTask.suspend()
            }
        }
    }

    func resumeAllTaskFor(groupId: String) {
        if let tasks = storedUploadTasks[groupId] {
            tasks.forEach { uploadTask in
                print("Resuming task......")
                uploadTask.resume()
            }
        }
    }

    private func addUploadTask(
        groupId: String, task: AWSS3TransferUtilityUploadTask
    ) {
        print("Adding task......")
        if var tasks = storedUploadTasks[groupId] {
            tasks.append(task)
            storedUploadTasks[groupId] = tasks
        } else {
            storedUploadTasks[groupId] = [task]
        }
    }

    func uploadFileAsync(
        fileUrl: URL, awsPath: String, fileName: String, contentType: String,
        withTaskGroupId groupId: String?
    ) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                _ = fileUrl.startAccessingSecurityScopedResource()
                let data = try Data(contentsOf: fileUrl)
                fileUrl.stopAccessingSecurityScopedResource()

                let expression = AWSS3TransferUtilityUploadExpression()
                expression.setValue(
                    "public-read", forRequestHeader: "x-amz-acl")

                // Progress block
                expression.progressBlock = { (task, awsProgress) in
                    DispatchQueue.main.async {
                        print(
                            "progress.fractionCompleted: \(awsProgress.fractionCompleted)"
                        )
                        if awsProgress.isFinished {
                            print("Upload Finished...")
                        }
                    }
                }

                // Completion handler block
                let completionHandler:
                    AWSS3TransferUtilityUploadCompletionHandlerBlock = {
                        (task, error) in
                        if let error = error {
                            // Check if error is network related
                            let isNetworkError = (error as NSError).domain == NSURLErrorDomain &&
                                ((error as NSError).code == NSURLErrorNotConnectedToInternet ||
                                 (error as NSError).code == NSURLErrorNetworkConnectionLost)
                            
                            if isNetworkError {
                                continuation.resume(throwing: UploadError(message: "No internet connection"))
                            } else {
                                continuation.resume(throwing: error)
                            }
                            print(
                                "File Uploading FAILED with error: \(error.localizedDescription)"
                            )
                        } else {
                            let url = AWSS3.default().configuration.endpoint.url
                            let publicURL = url?.appendingPathComponent(
                                ServiceAPI.bucketURL
                            ).appendingPathComponent(awsPath)
                            if let publicURLString = publicURL?.absoluteString {
                                print(
                                    "File Uploaded SUCCESSFULLY to: \(publicURLString)"
                                )
                                continuation.resume(returning: publicURLString)
                            } else {
                                continuation.resume(
                                    throwing: NSError(
                                        domain: "UploadError", code: 500,
                                        userInfo: [
                                            NSLocalizedDescriptionKey:
                                                "Failed to generate public URL"
                                        ]))
                            }
                        }
                    }

                // Start uploading using AWSS3TransferUtility
                let awsTransferUtility = AWSS3TransferUtility.default()
                awsTransferUtility.uploadData(
                    data, bucket: ServiceAPI.bucketURL, key: awsPath,
                    contentType: contentType, expression: expression,
                    completionHandler: completionHandler
                ).continueWith { task in
                    if let error = task.error {
                        print(
                            "Error uploading file: \(error.localizedDescription)\n error: \(error)"
                        )
                        continuation.resume(throwing: error)
                    }
                    if let groupId = groupId, let uploadTask = task.result {
                        print("Starting upload...")
                    }
                    return nil
                }

            } catch let error {
                continuation.resume(throwing: error)
            }
        }
    }

    /// This Function uploads Any File type to AWS S3 Bucket
    /// - Parameters:
    ///   - fileUrl: File Path of the file, it is local file url
    ///   - fileName: File Name that we want to keep for our object
    ///   - contenType: Type of Content, can be anything
    ///   - progress: Tells us about the progress rate of uploading
    ///   - completion: What to do after file is done uploading
    func uploadfile(
        fileUrl: URL, awsPath: String, fileName: String, contenType: String,
        withTaskGroupId groupid: String?, progress: progressBlock?,
        completion: completionBlock?
    ) {
        do {
            _ = fileUrl.startAccessingSecurityScopedResource()
            let data = try Data(contentsOf: fileUrl)
            fileUrl.stopAccessingSecurityScopedResource()

            let expression = AWSS3TransferUtilityUploadExpression()
            expression.setValue("public-read", forRequestHeader: "x-amz-acl")
            expression.progressBlock = { (task, awsProgress) in
                guard let uploadProgress = progress else { return }
                DispatchQueue.main.async {
                    uploadProgress(awsProgress.fractionCompleted)
                    print(
                        "progress.fractionCompleted: \(awsProgress.fractionCompleted)"
                    )
                    if awsProgress.isFinished {
                        print("Upload Finished...")
                    }
                }
            }

            // Completion block
            var completionHandler:
                AWSS3TransferUtilityUploadCompletionHandlerBlock?
            completionHandler = { (task, error) -> Void in
                DispatchQueue.main.async(execute: {
                    if error == nil {
                        let url = AWSS3.default().configuration.endpoint.url
                        let publicURL = url?.appendingPathComponent(
                            ServiceAPI.bucketURL
                        ).appendingPathComponent(awsPath)
                        print(
                            "File Uploaded SUCCESSFULLY to:\(String(describing: publicURL))"
                        )
                        if let completionBlock = completion {
                            completionBlock(publicURL?.absoluteString, nil)
                        }
                    } else {
                        if let completionBlock = completion {
                            completionBlock(nil, error)
                        }
                        print(
                            "File Uploading FAILED with error: \(String(describing: error?.localizedDescription))"
                        )
                    }
                })
            }

            // Start uploading using AWSS3TransferUtility
            let awsTransferUtility = AWSS3TransferUtility.default()
            awsTransferUtility.uploadData(
                data, bucket: ServiceAPI.bucketURL, key: awsPath,
                contentType: contenType, expression: expression,
                completionHandler: completionHandler
            ).continueWith { [weak self] (task) -> Any? in
                if let error = task.error {
                    print(
                        "Error uploading file: \(error.localizedDescription)\n error: \(error)"
                    )
                }
                if let groupid, let uploadTask = task.result {
                    print("Starting upload...")
                    self?.addUploadTask(groupId: groupid, task: uploadTask)
                }
                return nil
            }
        } catch let error {
            completion?(nil, error)
        }
    }

    func uploadfile(
        fileData: Data, awsPath: String, fileName: String, contenType: String,
        withTaskGroupId groupid: String?, progress: progressBlock?,
        completion: completionBlock?
    ) {
        let expression = AWSS3TransferUtilityUploadExpression()
        expression.progressBlock = { (task, awsProgress) in
            guard let uploadProgress = progress else { return }
            DispatchQueue.main.async {
                uploadProgress(awsProgress.fractionCompleted)
                print(
                    "progress.fractionCompleted: \(awsProgress.fractionCompleted)"
                )
                if awsProgress.isFinished {
                    print("Upload Finished...")
                }
            }
        }

        // Completion block
        var completionHandler: AWSS3TransferUtilityUploadCompletionHandlerBlock?
        completionHandler = { (task, error) -> Void in
            DispatchQueue.main.async(execute: {
                if error == nil {
                    let url = AWSS3.default().configuration.endpoint.url
                    let publicURL = url?.appendingPathComponent(
                        ServiceAPI.bucketURL
                    ).appendingPathComponent(awsPath)
                    print(
                        "File Uploaded SUCCESSFULLY to:\(String(describing: publicURL))"
                    )
                    if let completionBlock = completion {
                        completionBlock(publicURL?.absoluteString, nil)
                    }
                } else {
                    if let completionBlock = completion {
                        completionBlock(nil, error)
                    }
                    print(
                        "File Uploading FAILED with error: \(String(describing: error?.localizedDescription))"
                    )
                }
            })
        }

        // Start uploading using AWSS3TransferUtility
        let awsTransferUtility = AWSS3TransferUtility.default()
        awsTransferUtility.uploadData(
            fileData, bucket: ServiceAPI.bucketURL, key: awsPath,
            contentType: contenType, expression: expression,
            completionHandler: completionHandler
        ).continueWith { [weak self] (task) -> Any? in
            if let error = task.error {
                print(
                    "Error uploading file: \(error.localizedDescription)\n error: \(error)"
                )
            }
            if let groupid, let uploadTask = task.result {
                print("Starting upload...")
                self?.addUploadTask(groupId: groupid, task: uploadTask)
            }
            return nil
        }
    }
}
