//
//  MBETextureUtility.swift
//  MetalTracer
//
//  Created by Drew Ingebretsen on 1/19/15.
//  Copyright (c) 2015 Drew Ingebretsen. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

extension UIImage {
    class func imageFromTexture(_ texture:MTLTexture) -> UIImage{
        
        let imageSize = CGSize(width: texture.width, height: texture.height)
        let imageByteCount = Int(imageSize.width * imageSize.height * 4)
        
        let bytesPerPixel:Int = Int(4)
        let bitsPerComponent:Int = Int(8)
        let bitsPerPixel:Int = 32
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let bytesPerRow = bytesPerPixel * Int(imageSize.width)
        var imageBytes = [UInt8](repeating: 0, count: imageByteCount)
        let region = MTLRegionMake2D(0, 0, Int(imageSize.width), Int(imageSize.height))
        
        texture.getBytes(&imageBytes, bytesPerRow: Int(bytesPerRow), from: region, mipmapLevel: 0)
        
        let providerRef = CGDataProvider(
            data: Data(buffer: UnsafeBufferPointer(start: &imageBytes, count: imageBytes.count)) as CFData
        )
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        //let renderingIntent = kCGRenderingIntentDefault
        
        let imageRef = CGImage(width: Int(imageSize.width), height: Int(imageSize.height), bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: bitmapInfo, provider: providerRef!, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
        
        return UIImage(cgImage: imageRef!)
    }
    
    class func textureFromImage(_ image:UIImage, context:MetalContext) -> MTLTexture{
        let bytesPerPixel = Int(4)
        let bitsPerComponent = Int(8)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let image = UIImage(named: "texture.jpg")
        let imageRef = image?.cgImage
        let imageWidth:Int = Int(imageRef!.width)
        let imageHeight:Int = Int(imageRef!.height)
        let bytesPerRow:Int = bytesPerPixel * imageWidth
        
        var rawData = [UInt8](repeating: UInt8(0), count: Int(imageWidth * imageHeight * 4))
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let graphicsContext = CGContext(data: &rawData, width: imageWidth, height: imageHeight, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: rgbColorSpace, bitmapInfo: bitmapInfo.rawValue)
        
        graphicsContext?.draw(imageRef!, in: CGRect(x: 0, y: 0, width: CGFloat(imageWidth), height: CGFloat(imageHeight)))
        
        let imageTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: MTLPixelFormat.rgba8Unorm, width: Int(imageWidth), height: Int(imageHeight), mipmapped: true)
        
        let imageTexture = context.device.makeTexture(descriptor: imageTextureDescriptor)
        let region = MTLRegionMake2D(0, 0, Int(imageWidth), Int(imageHeight))
        imageTexture?.replace(region: region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: Int(bytesPerRow))
        
        return imageTexture!;
    }
}
