//===----------------------------------------------------------------------===//
//
// This source file is part of the APNSwift open source project
//
// Copyright (c) 2019 the APNSwift project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of APNSwift project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest
@testable import APNSwift
import Logging
import NIO
import NIOSSL

class APNSwiftConfigurationTests: XCTestCase {

    func configuration(environment: APNSwiftConfiguration.Environment) throws {
        var buffer = ByteBufferAllocator().buffer(capacity: appleECP8PrivateKey.count)
        buffer.writeString(appleECP8PrivateKey)
        let signer = try APNSwiftSigner.init(buffer: buffer)

        let apnsConfiguration = APNSwiftConfiguration(keyIdentifier: "MY_KEY_ID", teamIdentifier: "MY_TEAM_ID", signer: signer, topic: "MY_TOPIC", environment: environment)

        switch environment {
        case .production:
            XCTAssertEqual(apnsConfiguration.url, URL(string: "https://api.push.apple.com"))
        case .sandbox:
            XCTAssertEqual(apnsConfiguration.url, URL(string: "https://api.development.push.apple.com"))
        }

        XCTAssertEqual(apnsConfiguration.keyIdentifier, "MY_KEY_ID")
        XCTAssertEqual(apnsConfiguration.teamIdentifier, "MY_TEAM_ID")
        XCTAssertEqual(apnsConfiguration.topic, "MY_TOPIC")

    }

    func testSandboxConfiguration() throws {
        try configuration(environment: .sandbox)
    }

    func testProductionConfiguration() throws {
        try configuration(environment: .production)
    }

    func testSignature() throws {
        var buffer = ByteBufferAllocator().buffer(capacity: appleECP8PrivateKey.count)
        buffer.writeString(appleECP8PrivateKey)
        let signer = try APNSwiftSigner.init(buffer: buffer)
        let teamID = "8RX5AF8F6Z"
        let keyID = "9N8238KQ6Z"
        let date = Date()
        let jwt = APNSwiftJWT(keyID: keyID, teamID: teamID, issueDate: date)
        let digestValues = try jwt.getDigest()
        let _ = try signer.sign(digest: digestValues.fixedDigest)

    }

    static var allTests = [
        ("testSandboxConfiguration", testSandboxConfiguration),
        ("testProductionConfiguration", testProductionConfiguration),
        ("testSignature", testSignature),
    ]

    let appleECP8PrivateKey = """
-----BEGIN PRIVATE KEY-----
MIGTAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBHkwdwIBAQQg2sD+kukkA8GZUpmm
jRa4fJ9Xa/JnIG4Hpi7tNO66+OGgCgYIKoZIzj0DAQehRANCAATZp0yt0btpR9kf
ntp4oUUzTV0+eTELXxJxFvhnqmgwGAm1iVW132XLrdRG/ntlbQ1yzUuJkHtYBNve
y+77Vzsd
-----END PRIVATE KEY-----
"""
    let appleECP8PublicKey = """
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE2adMrdG7aUfZH57aeKFFM01dPnkx
C18ScRb4Z6poMBgJtYlVtd9ly63URv57ZW0Ncs1LiZB7WATb3svu+1c7HQ==
-----END PUBLIC KEY-----
"""

    let pemCertificate = """
    Bag Attributes
        friendlyName: APNSwift
        localKeyID: 5B 52 49 57 5A 43 F4 DB EE 7B C2 28 ED 3B 89 6E 0C 21 50 4D
    subject=/CN=APNSwift/C=US/emailAddress=apple.id.scott@gmail.com
    issuer=/CN=APNSwift/C=US/emailAddress=apple.id.scott@gmail.com
    -----BEGIN CERTIFICATE-----
    MIIDXDCCAkSgAwIBAgIBATANBgkqhkiG9w0BAQsFADBJMREwDwYDVQQDDAhBUE5T
    d2lmdDELMAkGA1UEBhMCVVMxJzAlBgkqhkiG9w0BCQEWGGFwcGxlLmlkLnNjb3R0
    QGdtYWlsLmNvbTAeFw0xOTEyMjAxODM1MzdaFw0yMDEyMTkxODM1MzdaMEkxETAP
    BgNVBAMMCEFQTlN3aWZ0MQswCQYDVQQGEwJVUzEnMCUGCSqGSIb3DQEJARYYYXBw
    bGUuaWQuc2NvdHRAZ21haWwuY29tMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
    CgKCAQEApIsywludcqp2pyE+JqTqY0Xgl9XEZ4Konux4OdrsFAFoeeBKIL14Wzca
    vzD+dTpO+GMJrWldGl22toK3X+SEl6Dz7auSadt7YKRZp9Oxn8fBJsWB5lNpaD0q
    P+ysiapsDg+WBj3OXRaAelgzRIBf27vFOMztzofRMKHS80Wb/3Q/YMyS4/QzzfS1
    e/F+9pOY0psVLT1p3F6YOaVaXcLp3JDr4enPfNaRiMw/xSdMruazwv0tUgJRHoIV
    IPFMeQeyX2O4TYbQQzICCYxHK+owFwqhHNC5i41z+J0/yGd7VY1A0VcIVA/tPdAa
    NIjd/p3IMkGadIuzJBzGaMUZ9Xnl/wIDAQABo08wTTAOBgNVHQ8BAf8EBAMCBaAw
    FgYDVR0lAQH/BAwwCgYIKwYBBQUHAwQwIwYDVR0RBBwwGoEYYXBwbGUuaWQuc2Nv
    dHRAZ21haWwuY29tMA0GCSqGSIb3DQEBCwUAA4IBAQBV9f3+BpGbEf2L39ZXBQyk
    JEn8xpaYIImvfEnGmiikLGzJTZXK78wv8r/DNjM0j3wb9vRGhQOMwzh6dnsNZX+n
    Wc7cTBrao7VFuPoJYG5B/eQ0dJ2R4iPHm4V972+7c4MFys7JUzYs92OZH4OQWQMk
    aB6j5lYxnug6e7+7gClvak+g8Ov53j/4wH7IJa91lCtZ3JLjiHRlHNfN+WF8s7y8
    7qZ0dojplbsTkCrLK2kQi8ty1hcILGidbmxwKktamggv/X6sDCY5MlnHc8zh+tz3
    U5RlNiUkGz0rTVV7GBnDz0fYKMtdSTxra0P58Cu7KJjX5iH60RIBLGb8K8cDjPIU
    -----END CERTIFICATE-----
    """

    let pemKey = """
    Bag Attributes
        friendlyName: APNSwift
        localKeyID: 5B 52 49 57 5A 43 F4 DB EE 7B C2 28 ED 3B 89 6E 0C 21 50 4D
    Key Attributes: <No Attributes>
    -----BEGIN ENCRYPTED PRIVATE KEY-----
    MIIFDjBABgkqhkiG9w0BBQ0wMzAbBgkqhkiG9w0BBQwwDgQIkIW4ZvtSh3ECAggA
    MBQGCCqGSIb3DQMHBAgBzFkz8kk2/gSCBMg2t4C1X+wOBHTHVrt3/VSzyCSnYJUS
    pvsgcqTnK8y+ALBJET60gRbgv0OLCYLrJwa38kscYlORoMtrkKTH7+C2j4cB/CxN
    BcajCbK6ZwV7hMZyMAJFFe8j1FlcD23Oh6vPaatIfvBpqBJzs2pLHoejjTITEW60
    FKD66IC1aYwA4wENDWqrHp1nA5RsPnIzet1M9kYc7cSg4jB66y7zAs3tnyz1DFOo
    YygX+hCkuFrWr47ayfsqB82FAHbE++uE7sm4NOYfsD4rbN8Lej5NFhHGt362GP1J
    Moj7wmkUd9E2CBnlHoT6w58fSOqln8C4ngXtMGe3b1kjkE+oLKO4u+9iQVePBi7X
    yEJgErVEpkOHJmAQ9DC9pcn/naD1hW8J035CrO7eLhtehgZB17Q12ZtDqdph1xab
    gV/kyBjsGo3X7+Nn1f2rzpdA1sd1wu5/oFipJlC6rci0jQLBPPehDfAwOfyvLzgh
    uLyq+OtFAMui1wnQWw/4wsp6D4ZwH6szk6gAwWJGsF+hboxEeKJHsKyl5z5KsSkJ
    vrWezpANIfqR4A+7IE6V1BYX+4QOR2WqLorqKVunTEhmo1d5CApMe/yhXJfvwcyR
    wzrtgNLx+StOeIMiQcjxEYWlnIpHSyHnATcqhgMggTQYIUwEyghPbt4a3VLjMZ95
    uVQffQmsogKfhllKUaN1IPUBy/M0/2G8J3D5GQ03pC7bcw5bE904secRbZ1vZ9RK
    g6jUSg/Bq7kt7UFd9mO4xsjp7PuN/eFNZGnT+qt2wS42kYZwtSiD7QkDdviYo6/C
    ubHSF5o2a7t0ZP7TIEUSNRb7Sh1qP2aOL/Shj+AkqcIvasTwnLxazWaO1uLZ/E+G
    fXB+j/3l2KGid7qW1b4snRo2l1YRTd/dPxqSHFSYHzjIb0+rHOg/safWKbz/0cle
    EFnZFK01gOGw3dcqoyYN/SsXPpOPkDLgwImZ/D+Eg0MWSaapA8t69I8fTpmhNgZi
    /GqIKM4DgqCcUjsOfhoZatgX5jpyW/rrsU+KdZO0VhCaypFCeD1Q1pmjkVCTWqF7
    tBuabQd3T1y5OvjqbIjJKnuNcybnNEAIfieIXZzDTdRMSrWZmOYGI+WEJ+OTZmds
    2DW8bIrqmB5lHlnNCxPHSiAJNgcK/qH3GZkxfmpD5YJIfl3B+ZNjcETd7fIV7op7
    A7FZZyThhHEOEuQoZuIPlI/d//RP7sZBN294mJPhRfkl6AvI63n/3nydFUOhoFCE
    3L2vi8fc87dkEFbpO8ANCPK01yLCprU55hRX0PQhJlN2XpoukOskiNX0yyFE5MHm
    wiRgt/ajGXJYuGCl6HjwJDH2HOvmkNoMIMvlmcq8LT8awcw/gmH+fgCMrmzZxCGC
    rxgPYKE+ZpybYBPewH4kB95vo6rOc3KjLWPUrkbNRubXV3Ii/Uvp+x/2lXZ+uuHO
    ojTyxCJqinNYmpHYzJhovpndrJCJHSGy/eEWeJvnLwjZqpV6w+AmvR1rbNmK609w
    nShaTZcKWHyWseKU45UBytTbx6dWzuIUqaxDo6IOcpzLhCMCfFhabP6YV+go+Clh
    Zhp4ewu27dOF4otHmpNCO5k8xetfEZxugYcacZXEblm/Xsk7SLkC36rESkGlqV0K
    HRk=
    -----END ENCRYPTED PRIVATE KEY-----
    """

    func testPasswordProtectedPemWithCallback() throws {
        let properPassword: NIOSSLPassphraseCallback = { $0("12345".utf8) }

        let key = [UInt8](pemKey.data(using: .utf8)!)
        let cert = [UInt8](pemCertificate.data(using: .utf8)!)

        XCTAssertNoThrow(try APNSwiftConfiguration(keyBytes: key, certificateBytes: cert,
                                                   topic: "", environment: .sandbox, passphraseCallback: properPassword))

        let wrongPassword: NIOSSLPassphraseCallback = { $0("foobar".utf8) }
        XCTAssertThrowsError(try APNSwiftConfiguration(keyBytes: key, certificateBytes: cert,
                                                       topic: "", environment: .sandbox, passphraseCallback: wrongPassword))
    }

    func testPasswordProtectedPemWithPassword() throws {
        let key = [UInt8](pemKey.data(using: .utf8)!)
        let cert = [UInt8](pemCertificate.data(using: .utf8)!)

        let properPassword = "12345".data(using: .utf8)
        XCTAssertNoThrow(try APNSwiftConfiguration(keyBytes: key, certificateBytes: cert,
                                                   topic: "", environment: .sandbox, pemPassword: properPassword))

        let wrongPassword = "foobar".data(using: .utf8)
        XCTAssertThrowsError(try APNSwiftConfiguration(keyBytes: key, certificateBytes: cert,
                                                       topic: "", environment: .sandbox, pemPassword: wrongPassword))
    }
}
