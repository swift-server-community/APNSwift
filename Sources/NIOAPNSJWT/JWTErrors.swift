import Foundation


public enum JWTError: Error {
    case invalidAuthKey    
    case certificateFileDoesNotExist
    case encodingFailed
}