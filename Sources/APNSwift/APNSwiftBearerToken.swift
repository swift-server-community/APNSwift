//
//  APNSwiftBearerToken.swift
//  APNSwift
//
//  Created by Benjamin Ingmire on 7/23/19.
//

import Foundation

public class APNSwiftBearerToken
{
    let configuration: APNSwiftConfiguration
    let timeout: TimeInterval
    var cachedToken : (TimeInterval, String) = (Date().timeIntervalSince1970, "") //JWT found in position 1
    
    public init(configuration: APNSwiftConfiguration, timeout: TimeInterval)
    {
        self.configuration = configuration
        self.timeout = timeout
    }
    
    func token() -> String
    {
        let getToken = getFreshestToken()
        return getToken.1
    }
    
    func getFreshestToken()-> (TimeInterval, String)
    {
        if self.cachedToken.1 == ""
        {
            self.cachedToken = (Date().timeIntervalSince1970, self.createToken())
        }
        else
        {
            let now = Date().timeIntervalSince1970
            let diff = now - self.cachedToken.0
            if diff >= timeout
            {
                //refresh the token
                self.cachedToken = (Date().timeIntervalSince1970, self.createToken())
            }
        }
        return self.cachedToken
    }
    
    func createToken() -> String
    {
        let jwt = APNSwiftJWT(keyID: configuration.keyIdentifier, teamID: configuration.teamIdentifier, issueDate: Date(), expireDuration: timeout)
        var token: String
        do {
            let digestValues = try jwt.getDigest()
            let signature = try configuration.signer.sign(digest: digestValues.fixedDigest)
            guard let data = signature.getData(at: 0, length: signature.readableBytes) else {
                throw APNSwiftError.SigningError.invalidSignatureData
            }
            token = digestValues.digest + "." + data.base64EncodedURLString()
        } catch {
            var ErrorStack = String()
            Thread.callStackSymbols.forEach {
                ErrorStack = "\(ErrorStack)\n" + $0
            }
            print(ErrorStack)
            token = ""
        }
        return token
    }
}


