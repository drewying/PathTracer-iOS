//
//  MBETextureUtility.swift
//  MetalTracer
//
//  Created by Drew Ingebretsen on 1/19/15.
//  Copyright (c) 2015 Drew Ingebretsen. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    class func imageFromTexture(texture:MTLTexture) -> UIImage{
        let imageSize = CGSize(width: texture.width, height: texture.height)
        let imageByteCount = Int(imageSize.width * imageSize.height * 4)
        
        let bytesPerPixel = UInt(4)
        let bitsPerComponent = UInt(8)
        let bitsPerPixel:UInt = 32
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
            
        let bytesPerRow = bytesPerPixel * UInt(imageSize.width)
        var imageBytes = [UInt8](count: imageByteCount, repeatedValue: 0)
        let region = MTLRegionMake2D(0, 0, Int(imageSize.width), Int(imageSize.height))
        
        texture.getBytes(&imageBytes, bytesPerRow: Int(bytesPerRow), fromRegion: region, mipmapLevel: 0)
        
        
        let providerRef = CGDataProviderCreateWithCFData(
            NSData(bytes: &imageBytes, length: imageBytes.count * sizeof(UInt8))
        )
        
        let bitmapInfo = CGBitmapInfo(CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
        let renderingIntent = kCGRenderingIntentDefault
        
        let imageRef = CGImageCreate(UInt(imageSize.width), UInt(imageSize.height), bitsPerComponent, bitsPerPixel, bytesPerRow, rgbColorSpace, bitmapInfo, providerRef, nil, false, renderingIntent)
        
        return UIImage(CGImage: imageRef)!
    }
    
    class func textureFromImage(image:UIImage, context:MetalContext) -> MTLTexture{
        let bytesPerPixel = UInt(4)
        let bitsPerComponent = UInt(8)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let image = UIImage(named: "texture.jpg")
        let imageRef = image?.CGImage
        let imageWidth = CGImageGetWidth(imageRef)
        let imageHeight = CGImageGetHeight(imageRef)
        let bytesPerRow = bytesPerPixel * imageWidth
        
        var rawData = [UInt8](count: Int(imageWidth * imageHeight * 4), repeatedValue: 0)
        
        let bitmapInfo = CGBitmapInfo(CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
        
        let graphicsContext = CGBitmapContextCreate(&rawData, imageWidth, imageHeight, bitsPerComponent, bytesPerRow, rgbColorSpace, bitmapInfo)
        
        CGContextDrawImage(graphicsContext, CGRectMake(0, 0, CGFloat(imageWidth), CGFloat(imageHeight)), imageRef)
        
        let imageTextureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: Int(imageWidth), height: Int(imageHeight), mipmapped: true)
        
        var imageTexture = context.device.newTextureWithDescriptor(imageTextureDescriptor)
        let region = MTLRegionMake2D(0, 0, Int(imageWidth), Int(imageHeight))
        imageTexture.replaceRegion(region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: Int(bytesPerRow))
        
        return imageTexture;
    }
}