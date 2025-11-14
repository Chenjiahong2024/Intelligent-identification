//
//  ImageSegmentationService.swift
//  Intelligent identification
//
//  Created by Assistant on 10/24/25.
//

import UIKit
import Vision

final class ImageSegmentationService {
    static let shared = ImageSegmentationService()
    private init() {}
    
    func cutoutPrimaryObject(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        guard let cgImage = image.cgImage else {
            print("❌ [扣像] 无法获取CGImage")
            completion(nil)
            return
        }
        
        let request = VNGenerateObjectnessBasedSaliencyImageRequest()
        let orientation = exifOrientation(for: image.imageOrientation)
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
                guard let saliency = request.results?.first as? VNSaliencyImageObservation else {
                    print("❌ [扣像] 未获取到显著性结果")
                    completion(nil)
                    return
                }
                
                let salientObjects = saliency.salientObjects ?? []
                guard let best = salientObjects.max(by: { $0.confidence < $1.confidence }) else {
                    print("⚠️ [扣像] 未检测到显著目标，放弃扣像")
                    completion(nil)
                    return
                }
                
                let cropRect = self.convertFromNormalized(best.boundingBox, imageWidth: cgImage.width, imageHeight: cgImage.height)
                let paddedRect = self.padAndClamp(rect: cropRect, imageWidth: cgImage.width, imageHeight: cgImage.height, padFraction: 0.08)
                
                if let cropped = cgImage.cropping(to: paddedRect) {
                    let result = UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
                    print("✅ [扣像] 完成，区域: \(Int(paddedRect.width))x\(Int(paddedRect.height))")
                    completion(result)
                } else {
                    print("❌ [扣像] 裁剪失败")
                    completion(nil)
                }
            } catch {
                print("❌ [扣像] 显著性请求失败: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    private func convertFromNormalized(_ normalized: CGRect, imageWidth: Int, imageHeight: Int) -> CGRect {
        let width = CGFloat(imageWidth)
        let height = CGFloat(imageHeight)
        let x = normalized.origin.x * width
        let y = (1.0 - normalized.origin.y - normalized.size.height) * height
        let w = normalized.size.width * width
        let h = normalized.size.height * height
        return CGRect(x: x, y: y, width: w, height: h)
    }
    
    private func padAndClamp(rect: CGRect, imageWidth: Int, imageHeight: Int, padFraction: CGFloat) -> CGRect {
        let padX = rect.width * padFraction
        let padY = rect.height * padFraction
        var padded = rect.insetBy(dx: -padX, dy: -padY)
        let imgRect = CGRect(x: 0, y: 0, width: CGFloat(imageWidth), height: CGFloat(imageHeight))
        padded = padded.intersection(imgRect)
        return padded
    }
    
    private func exifOrientation(for orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}


