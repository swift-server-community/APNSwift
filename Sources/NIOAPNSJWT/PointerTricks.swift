//===----------------------------------------------------------------------===//
//
// This source file is taken from SwiftNIO open source project
//
// Copyright (c) 2017-2018 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
//===----------------------------------------------------------------------===//

// MARK:- Awful code begins here
// Hello dear reader. Let me explain what we're doing here.
//
// From OpenSSL 1.0 to OpenSSL 1.1 one of the major breaking changes was the so-called
// "great opaquifiying". Essentially, OpenSSL took all of its public structures and made
// them opaque, such that they cannot be introspected from client code. This is a great
// forward step, and brings them more in line with modern C library practices.
//
// However, it's an *enormous* inconvenience from Swift code. This is because the Swift
// translation of the C type `SSL_CTX *` changed from `UnsafeMutablePointer<SSL_CTX>` to
// `OpaquePointer`.
//
// This change exists for reasonable enough reasons in Swift land (see
// https://forums.swift.org/t/opaque-pointers-in-swift/6875 for a discussion), but
// nonetheless causes enormous problems in our codebase.
//
// Our cheap way out is to make everything an OpaquePointer, and then provide initializers
// between OpaquePointer and the typed pointers. This allows us to tolerate either pointer
// type in our Swift code by bridging them over to OpaquePointer and back, and lets the
// compiler worry about how exactly to make that work.
//
// Now, in fact, Swift already has initializers between the pointer types. What it does
// not have is self-initializers: the ability to create an `OpaquePointer` from an `OpaquePointer`,
// or an `UnsafePointer<T>` from an `UnsafePointer<T>`. We add those two initializers here.
// We also add a special "make" function that exists to handle the special case of optional pointer
// values, which we mostly encounter in the ALPN callbacks.
//
// The *downside* of this approach is that we totally break the pointer type system. It becomes
// trivially possible to alias a pointer of type T to type U through two calls to init. This
// is not a thing we want to widely promote. For this reason, these extensions are hidden in
// this file, where we can laugh and jeer at them and generally make them feel bad about
// themselves.
//
// Hopefully, in time, these extensions can be removed.

extension UnsafePointer {
    init(_ ptr: UnsafePointer<Pointee>) {
        self = ptr
    }

    static func make(optional ptr: UnsafePointer<Pointee>?) -> UnsafePointer<Pointee>? {
        return ptr.map(UnsafePointer<Pointee>.init)
    }

    static func make(optional ptr: OpaquePointer?) -> UnsafePointer<Pointee>? {
        return ptr.map(UnsafePointer<Pointee>.init)
    }
}

extension UnsafeMutablePointer {
    init(_ ptr: UnsafeMutableRawPointer) {
        let x = UnsafeMutablePointer<Pointee>(bitPattern: UInt(bitPattern: ptr))!
        self = x
    }

    static func make(optional ptr: UnsafeMutablePointer<Pointee>?) -> UnsafeMutablePointer<Pointee>? {
        return ptr.map(UnsafeMutablePointer<Pointee>.init)
    }

    static func make(optional ptr: UnsafeMutableRawPointer?) -> UnsafeMutablePointer<Pointee>? {
        return ptr.map(UnsafeMutablePointer<Pointee>.init)
    }

    static func make(optional ptr: OpaquePointer?) -> UnsafeMutablePointer<Pointee>? {
        return ptr.map(UnsafeMutablePointer<Pointee>.init)
    }
}

extension UnsafeMutableRawPointer {
    static func make(optional ptr: OpaquePointer?) -> UnsafeMutableRawPointer? {
        return ptr.map(UnsafeMutableRawPointer.init)
    }
}

extension OpaquePointer {
    init(_ ptr: OpaquePointer) {
        self = ptr
    }

    static func make(optional ptr: OpaquePointer?) -> OpaquePointer? {
        return ptr.map(OpaquePointer.init)
    }

    static func make(optional ptr: UnsafeMutableRawPointer?) -> OpaquePointer? {
        return ptr.map(OpaquePointer.init)
    }

    static func make<Pointee>(optional ptr: UnsafeMutablePointer<Pointee>?) -> OpaquePointer? {
        return ptr.map(OpaquePointer.init)
    }
}


extension OpaquePointer {
    func convert<T>() -> UnsafePointer<T> {
        return .init(self)
    }

    func convert<T>() -> UnsafeMutablePointer<T> {
        return .init(self)
    }

    func convert() -> OpaquePointer {
        return self
    }
}

extension UnsafePointer {
    func convert() -> OpaquePointer {
        return .init(self)
    }
}

extension UnsafeMutablePointer {
    func convert() -> OpaquePointer {
        return .init(self)
    }
}
