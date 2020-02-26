//
//  ViewController.swift
//  ios-mobile-ffmpeg-demo
//
//  Created by eiji kushida on 2020/02/26.
//  Copyright © 2020 eiji kushida. All rights reserved.
//

import UIKit
import Photos

final class ViewController: UIViewController {
    
    private let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    private var assets: PHFetchResult<PHAsset>?
    private let imageManager = PHImageManager()
    private var status = PHPhotoLibrary.authorizationStatus()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupIndicatorViews()
        allowAccessCameraRoll()
    }
    
    @IBAction func didTapCompressButton(_ sender: UIButton) {
        getVideoFile()
    }
    
    private func setupIndicatorViews() {
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        activityIndicator.layer.cornerRadius = 10
        activityIndicator.center = self.view.center
        activityIndicator.backgroundColor = UIColor.black
        activityIndicator.hidesWhenStopped = true
        self.view.addSubview(activityIndicator)
    }
    
    // MARK:- Private
    private func allowAccessCameraRoll() {
        switch self.status {
        case .authorized:
            break
        default:
            PHPhotoLibrary.requestAuthorization { status in
                if status == .denied {
                    self.showAlertOrInfo(title: "Warning", message: "動画にアクセスする許可をしてください。")
                }
            }
        }
    }
    
   //カメラロールから動画を取り出す
   private func getVideoFile() {
       
       DispatchQueue.main.async {
           self.activityIndicator.startAnimating()
       }
       assets = PHAsset.fetchAssets(with: PHAssetMediaType.video, options: nil)
       
       guard let asset = assets?.lastObject else {
           showAlertOrInfo(title: "Warning", message: "撮影済みの動画がありません。")
           DispatchQueue.main.async {
               self.activityIndicator.stopAnimating()
           }
           return
       }
       imageManager.requestPlayerItem(forVideo: asset,
                                           options: nil,
                                           resultHandler: {(playerItem, info) -> Void in
           guard let playerItem = playerItem else {
               self.showAlertOrInfo(title: "Warning", message: "撮影済みの動画がありません。")
               DispatchQueue.main.async {
                   self.activityIndicator.stopAnimating()
               }
               return
           }
           self.downFPS(asset: playerItem.asset)
       })
   }
           
   //データレートを落とす
   private func downFPS(asset: AVAsset) {

       let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
       let date = Date()
       let dateString = dateFormatter.string(from: date)
       let toUrl: String = NSHomeDirectory() + "/Documents/\(dateString).mp4"
       
       let fromUrl = (asset as? AVURLAsset)?.url.description ?? "!!!!"
       let command = "-i \(fromUrl) -vf scale=640:-1 -r 10 \(toUrl)"
       let result = MobileFFmpeg.execute(command)
               
       if (result == RETURN_CODE_SUCCESS) {
           print("Command execution completed successfully.\n");
           mp4ToWav(asset: asset)
       } else if (result == RETURN_CODE_CANCEL) {
           print("Command execution cancelled by user.\n");
       } else {
           print(MobileFFmpegConfig.getLastCommandOutput() ?? "");
       }
   }
       
   //MP4toWav
   private func mp4ToWav(asset: AVAsset) {

       let dateFormatter = DateFormatter()
       dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
       let date = Date()
       let dateString = dateFormatter.string(from: date)
       let toUrl: String = NSHomeDirectory() + "/Documents/\(dateString).wav"
       
       let fromUrl = (asset as? AVURLAsset)?.url.description ?? "!!!!"
       let command = "-i \(fromUrl) -vb 10k \(toUrl)"
       let result = MobileFFmpeg.execute(command)
               
       if (result == RETURN_CODE_SUCCESS) {
           print("Command execution completed successfully.\n");
           
       } else if (result == RETURN_CODE_CANCEL) {
           print("Command execution cancelled by user.\n");
       } else {
           print(MobileFFmpegConfig.getLastCommandOutput() ?? "");
       }
       DispatchQueue.main.async {
           self.activityIndicator.stopAnimating()
                       
           PHPhotoLibrary.shared().performChanges( {
               
               guard let asset = self.assets?.lastObject else {
                   self.showAlertOrInfo(title: "Warning", message: "撮影済みの動画がありません。")
                   return
               }

               PHAssetChangeRequest.deleteAssets(NSArray(array: [asset]))
           },
               completionHandler: { success, error in
                   DispatchQueue.main.async {
                       self.showAlertOrInfo(title: "Info", message: "動画の圧縮/ファイル移動が完了しました。")
                   }
           })
       }
   }
}

//MARK : - instance Helper
extension ViewController {
    static func instance() -> ViewController {
        
        guard let viewController = UIStoryboard.viewController(
            storyboardName: "Main",
            identifier: "Main" ) as? ViewController else {
                fatalError("ViewController not Found.")
        }
        return viewController
    }
}

//MARK : - AlertHelper
extension ViewController {
    
    private func showAlertOrInfo(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okButton = UIAlertAction(title: "OK", style: .default)

        alertController.addAction(okButton)
        self.present(alertController, animated: true, completion: nil)
    }
}

extension ViewController {

    class func viewController<T: UIViewController>(storyboardName: String,
                                                   identifier: String) -> T? {
        
        return UIStoryboard(name: storyboardName, bundle: nil).instantiateViewController(
            withIdentifier: identifier) as? T
    }
}
