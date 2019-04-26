import UIKit
import AVKit

extension UIImage {
	
	func image(scaledToFitIn targetSize: CGSize) -> UIImage {
		
		let normalizedSelf = self.normalizedImage()
		let imageWidth = normalizedSelf.size.width * normalizedSelf.scale
		let imageHeight = normalizedSelf.size.height * normalizedSelf.scale
		
		if imageWidth <= targetSize.width && imageHeight <= targetSize.height {
			return normalizedSelf
		}
		
		let widthRatio = imageWidth / targetSize.width
		let heightRatio = imageHeight / targetSize.height
		let scaleFactor = max(widthRatio, heightRatio)
		let scaledSize = CGSize(width: imageWidth / scaleFactor, height: imageHeight / scaleFactor)
		
		return normalizedSelf.image(scaledToSizeInPixels: scaledSize)
	}
	
	func image(scaledToSizeInPixels targetSize: CGSize) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(targetSize, true, 1)
		draw(in: CGRect(origin: .zero, size: targetSize))
		let image = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		return image
	}
	
	func normalizedImage() -> UIImage {
		if (self.imageOrientation == .up) {
			return self
		}
		UIGraphicsBeginImageContextWithOptions(self.size, true, self.scale)
		draw(in: CGRect(origin: .zero, size: self.size))
		let image = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		return image
	}
    
    
    
    func rotate(byDegrees degree: Double) -> UIImage {
        let radians = CGFloat(degree*Double.pi)/180.0 as CGFloat
        let rotatedSize = self.size
        let scale = UIScreen.main.scale
        UIGraphicsBeginImageContextWithOptions(rotatedSize, false, scale)
        let bitmap = UIGraphicsGetCurrentContext()
        bitmap?.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        bitmap?.rotate(by: radians)
        bitmap?.scaleBy(x: 1.0, y: -1.0)
        bitmap?.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2 , width: self.size.width, height: self.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        return newImage!
    }
    
    func overlayWith(image: UIImage, posX: CGFloat, posY: CGFloat) -> UIImage {
        let newWidth = size.width < posX + image.size.width ? posX + image.size.width : size.width
        let newHeight = size.height < posY + image.size.height ? posY + image.size.height : size.height
        let newSize = CGSize(width: newWidth, height: newHeight)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        draw(in: CGRect(origin: CGPoint.zero, size: size))
        image.draw(in: CGRect(origin: CGPoint(x: posX, y: posY), size: image.size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
