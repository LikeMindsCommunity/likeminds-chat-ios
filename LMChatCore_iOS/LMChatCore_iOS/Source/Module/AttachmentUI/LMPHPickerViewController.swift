//
//  LMPHPickerViewController.swift
//  LikeMindsChatCore
//
//  Created by Pushpendra Singh on 13/04/24.
//

import Foundation
import PhotosUI
import MobileCoreServices
import GiphyUISDK

public enum MediaType: String {
    case image
    case gif
    case video
    case livePhoto
    case pdf
    case audio
    case voice_note
}

public class MediaPickerModel: Hashable {
    
    static public func ==(lhs: MediaPickerModel, rhs: MediaPickerModel) -> Bool {
        return lhs.localPath == rhs.localPath
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(localPath)
    }
    
    public var id: String
    var photo: UIImage? {
        didSet {
            do {
                guard let localPath else { return }
                let image = photo
                try image?.jpegData(compressionQuality: 1.0)?.write(to: localPath, options: .atomic)
            } catch {
                print(error)
            }
        }
    }
    var originalPhoto: UIImage?
    var url: URL?
    var livePhoto: PHLivePhoto?
    var mediaType: MediaType = .image
    var localPath: URL?
    var thumnbailLocalPath: URL?
    var fileSize: Int?
    var duration: Int?
    var numberOfPages: Int?
    var name: String? {
        return localPath?.lastPathComponent
    }
    
    init(with photo: UIImage) {
        id = UUID().uuidString
        self.photo = photo
        self.originalPhoto = photo
        mediaType = .image
    }
    
    init(with localPath: URL, type: MediaType, thumbnailPath: URL? = nil) {
        self.id = UUID().uuidString
        self.localPath = localPath
        self.url = localPath
        self.thumnbailLocalPath = thumbnailPath
        self.mediaType = type
        if [MediaType.image, .gif].contains(type) {
            guard let data = try? Data(contentsOf: localPath) else { return }
            self.photo = UIImage(data: data)
            self.originalPhoto = self.photo
        }
    }
    
    init(with livePhoto: PHLivePhoto) {
        id = UUID().uuidString
        self.livePhoto = livePhoto
        mediaType = .livePhoto
    }
}

protocol MediaPickerDelegate: AnyObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func mediaPicker(_ picker: UIViewController, didFinishPicking results: [MediaPickerModel])
    func filePicker(_ picker: UIViewController, didFinishPicking results: [MediaPickerModel], fileType: MediaType)
}

extension MediaPickerDelegate {
    func mediaPicker(_ picker: UIViewController, didFinishPicking results: [MediaPickerModel]) {}
    func filePicker(_ picker: UIViewController, didFinishPicking results: [MediaPickerModel], fileType: MediaType) {}
}

class MediaPickerManager: NSObject {
    
    weak var delegate: MediaPickerDelegate?
    
    static let shared = MediaPickerManager()
    
    var mediaPickerItems: [MediaPickerModel] = []
    
    let group = DispatchGroup()
    
    var fileTypeForDocument: MediaType = .pdf
    
    private override init() {}
    
    func presentPicker(viewController: UIViewController, delegate: MediaPickerDelegate?, selectionLimit: Int = 10) {
        self.delegate = delegate
        self.mediaPickerItems.removeAll()
        if #available(iOS 14.0, *) {
            var configuration = PHPickerConfiguration()
            configuration.filter = .any(of: [.videos, .images])
            configuration.selectionLimit = selectionLimit
            configuration.preferredAssetRepresentationMode = .current
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            picker.isModalInPresentation = true
            viewController.present(picker, animated: true)
        } else {
            if LMChatCheckMediaAccess.checkForPhotoLibraryAccess(from: viewController) {
                let imagePicker = UIImagePickerController()
                imagePicker.sourceType = .photoLibrary
                imagePicker.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String] // Only videos
                imagePicker.allowsEditing = false
                viewController.present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    func presentCamera(viewController: UIViewController, delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)?) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            DispatchQueue.main.async {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = delegate
                imagePicker.sourceType = .camera
                imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeVideo as String] // Only Photos
                imagePicker.allowsEditing = false
                viewController.present(imagePicker, animated: true, completion: nil)
            }
        }
    }
    
    func presentAudioAndDocumentPicker(viewController: UIViewController, delegate: UIDocumentPickerDelegate?, fileType: MediaType, multipleAllowed: Bool = true) {
        guard [MediaType.pdf, .audio].contains(fileType) else { return }
        self.fileTypeForDocument = fileType
        let docTypes = fileType == .pdf ? ["com.adobe.pdf"] : ["public.audiovisual-​content", "public.audio"]
        let docVc = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
        docVc.delegate = delegate
        docVc.allowsMultipleSelection = true
        docVc.isModalInPresentation = true
        docVc.allowsMultipleSelection = multipleAllowed
        viewController.present(docVc, animated: true)
    }

    // get video dimensions
    func initAspectRatioOfVideo(with fileURL: URL) -> (width: CGFloat, height: CGFloat)? {
        let resolution = resolutionForLocalVideo(url: fileURL)
        guard let width = resolution?.width, let height = resolution?.height else {
            return nil
        }
        return (width , height)
    }
    
    // get video dimensions
    func initAspectRatioOfImage(with fileURL: URL) -> (width: Int, height: Int)? {
        if let imageSource = CGImageSourceCreateWithURL(fileURL as CFURL, nil) {
            if let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as Dictionary? {
                let pixelWidth = imageProperties[kCGImagePropertyPixelWidth] as? Int
                let pixelHeight = imageProperties[kCGImagePropertyPixelHeight] as? Int
                return (pixelWidth ?? 0, pixelHeight ?? 0)
            }
        }
        return nil
    }
    
    private func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    // get video size in byte
    func fileSizeInByte(url: URL?) -> Double {
        guard let filePath = url?.path else {
            return 0.0
        }
        do {
            let attribute = try FileManager.default.attributesOfItem(atPath: filePath)
            if let size = attribute[FileAttributeKey.size] as? NSNumber {
                return Double(truncating: size)
            }
        } catch {
            print("Error: \(error)")
        }
        return 0.0
    }
    
    // copying the file from Pickers symbolic local directory to app's sandbox memory.
    // though the url is coming to be the same without copying unable to read the file
    func createLocalURLfromPickedAssetsUrl(url: URL) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let targetURL = documentsDirectory?.appendingPathComponent(url.lastPathComponent) else { return nil }
        
        do {
            if FileManager.default.fileExists(atPath: targetURL.path) {
                try FileManager.default.removeItem(at: targetURL)
            }
            try FileManager.default.copyItem(at: url, to: targetURL)
        } catch {
            print(error.localizedDescription)
        }
        return targetURL
    }
    
    func saveImageIntoDirecotry(image: UIImage) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let targetURL = documentsDirectory?.appendingPathComponent("IMG_\(Date().timeIntervalSince1970).jpeg") else { return nil }
        
        do {
            // Convert to Data
            if let data = image.jpegData(compressionQuality: 1) {
                try data.write(to: targetURL)
            }
        } catch {
            print(error.localizedDescription)
        }
        return targetURL
    }
}

@available(iOS 14.0, *)
extension MediaPickerManager: PHPickerViewControllerDelegate  {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        guard !results.isEmpty else {
            delegate?.mediaPicker(picker, didFinishPicking: mediaPickerItems)
            return
        }
        for result in results {
            let itemProvider = result.itemProvider
            
            guard let typeIdentifier = itemProvider.registeredTypeIdentifiers.first,
                  let utType = UTType(typeIdentifier)
            else { continue }
            
            if utType.conforms(to: .image) {
                group.enter()
                self.getPhoto(from: itemProvider, typeIdentifier: typeIdentifier)
            } else if utType.conforms(to: .movie) {
                group.enter()
                self.getVideo(from: itemProvider, typeIdentifier: typeIdentifier)
            } 
            group.notify(queue: DispatchQueue.main) { [weak self] in
                guard let self else { return }
                delegate?.mediaPicker(picker, didFinishPicking: mediaPickerItems)
                picker.dismiss(animated: true)
            }
        }
    }
    
    private func getPhoto(from itemProvider: NSItemProvider, typeIdentifier: String) {
        itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) {[weak self] url, error in
            if let error = error {
                print(error.localizedDescription)
            }
            guard let url = url, let targetURL = self?.createLocalURLfromPickedAssetsUrl(url: url) else {
                self?.group.leave()
                return
            }
            DispatchQueue.main.async {[weak self] in
                guard let self else { return }
                mediaPickerItems.append(.init(with: targetURL, type: .image))
                group.leave()
            }
        }
    }
    
    private func getVideo(from itemProvider: NSItemProvider, typeIdentifier: String) {
        itemProvider.loadFileRepresentation(forTypeIdentifier: typeIdentifier) {[weak self] url, error in
            if let error = error {
                print(error.localizedDescription)
            }
            guard let url = url, let targetURL = self?.createLocalURLfromPickedAssetsUrl(url: url) else {
                self?.group.leave()
                return
            }
            DispatchQueue.main.async {[weak self] in
                guard let self else { return }
                let videoDetails = FileUtils.getDetail(forVideoUrl: targetURL)
                mediaPickerItems.append(.init(with: targetURL, type: .video, thumbnailPath: videoDetails?.thumbnailUrl))
                group.leave()
            }
        }
    }
    
    private func getLivePhoto(from itemProvider: NSItemProvider, isLivePhoto: Bool) {
        let objectType: NSItemProviderReading.Type = !isLivePhoto ? UIImage.self : PHLivePhoto.self
        
        if itemProvider.canLoadObject(ofClass: objectType) {
            itemProvider.loadObject(ofClass: objectType) { object, error in
                if let error = error {
                    print(error.localizedDescription)
                }
                if let livePhoto = object as? PHLivePhoto {
                    DispatchQueue.main.async {[weak self] in
                        guard let self else { return }
                        mediaPickerItems.append(.init(with: livePhoto))
                        group.leave()
                    }
                }
            }
        }
    }
}

extension MediaPickerManager: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for item in urls {
            guard let localPath = createLocalURLfromPickedAssetsUrl(url: item) else { continue }
            mediaPickerItems.append(.init(with: localPath, type: fileTypeForDocument))
        }
        delegate?.mediaPicker(controller, didFinishPicking: mediaPickerItems)
    }
}



public class LMChatCheckMediaAccess {
    class func checkCameraAccess(viewController: UIViewController, delegate: (UIImagePickerControllerDelegate & UINavigationControllerDelegate)?) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied:
            presentMediaSettings(from: viewController, message: "Camera access is denied")
        case .authorized:
            MediaPickerManager.shared.presentCamera(viewController: viewController, delegate: delegate)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                if success {
                    MediaPickerManager.shared.presentCamera(viewController: viewController, delegate: delegate)
                }
            }
        default:
            break
        }
    }
    
    class func presentMediaSettings(from vc: UIViewController, message: String) {
        let alertController = UIAlertController(title: "Error",
                                                message: message,
                                                preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:]) { _ in }
            }
        })
        
        vc.present(alertController, animated: true)
    }
    
    class func askForMicrophoneAccess(from vc: UIViewController) {
        if #available(iOS 17, *) {
            if AVAudioApplication.shared.recordPermission == .denied {
                presentMediaSettings(from: vc, message: "Microphone access is denied")
            } else if AVAudioApplication.shared.recordPermission == .undetermined {
                AVAudioApplication.requestRecordPermission { _ in }
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .denied:
                presentMediaSettings(from: vc, message: "Microphone access is denied")
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { _ in}
            default:
                break
            }
        }
    }
    
    class func checkForPhotoLibraryAccess(from vc: UIViewController) -> Bool {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in }
            return false
        case .denied:
            presentMediaSettings(from: vc, message: "Photo Library access is denied")
            return false
        default:
            break
        }
        
        return true
    }
}
