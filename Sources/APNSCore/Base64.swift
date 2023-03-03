//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-extras-base64 open source project
//
// Copyright (c) 2022 the swift-extras-base64 project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

// This base64 implementation is heavily inspired by:

// https://github.com/lemire/fastbase64/blob/master/src/chromiumbase64.c
/*
 Copyright (c) 2015-2016, Wojciech Muła, Alfred Klomp,  Daniel Lemire
 (Unless otherwise stated in the source code)
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are
 met:

 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// https://github.com/client9/stringencoders/blob/master/src/modp_b64.c
/*
 The MIT License (MIT)

 Copyright (c) 2016 Nick Galbreath

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

// MARK: - Extensions -

extension String {
    @inlinable
    internal init<Buffer: Collection>(base64Encoding bytes: Buffer, options: Base64.EncodingOptions = [])
        where Buffer.Element == UInt8 {
        self = Base64.encodeString(bytes: bytes, options: options)
    }

    internal func base64decoded(options: Base64.DecodingOptions = []) throws -> [UInt8] {
        try Base64.decode(string: self, options: options)
    }
}

@usableFromInline
internal enum Base64 {}

// MARK: - Encoding -

extension Base64 {
    @usableFromInline
    internal struct EncodingOptions: OptionSet {
        @usableFromInline
        internal let rawValue: UInt

        @inlinable
        internal init(rawValue: UInt) { self.rawValue = rawValue }

        @usableFromInline
        internal static let base64UrlAlphabet = EncodingOptions(rawValue: UInt(1 << 0))

        @usableFromInline
        internal static let omitPaddingCharacter = EncodingOptions(rawValue: UInt(1 << 1))
    }

    @usableFromInline
    internal static let encodePaddingCharacter: UInt8 = 61

    @usableFromInline
    static let encoding0: [UInt8] = [
        UInt8(ascii: "A"), UInt8(ascii: "A"), UInt8(ascii: "A"), UInt8(ascii: "A"), UInt8(ascii: "B"),
        UInt8(ascii: "B"),
        UInt8(ascii: "B"), UInt8(ascii: "B"), UInt8(ascii: "C"), UInt8(ascii: "C"),
        UInt8(ascii: "C"), UInt8(ascii: "C"), UInt8(ascii: "D"), UInt8(ascii: "D"), UInt8(ascii: "D"),
        UInt8(ascii: "D"),
        UInt8(ascii: "E"), UInt8(ascii: "E"), UInt8(ascii: "E"), UInt8(ascii: "E"),
        UInt8(ascii: "F"), UInt8(ascii: "F"), UInt8(ascii: "F"), UInt8(ascii: "F"), UInt8(ascii: "G"),
        UInt8(ascii: "G"),
        UInt8(ascii: "G"), UInt8(ascii: "G"), UInt8(ascii: "H"), UInt8(ascii: "H"),
        UInt8(ascii: "H"), UInt8(ascii: "H"), UInt8(ascii: "I"), UInt8(ascii: "I"), UInt8(ascii: "I"),
        UInt8(ascii: "I"),
        UInt8(ascii: "J"), UInt8(ascii: "J"), UInt8(ascii: "J"), UInt8(ascii: "J"),
        UInt8(ascii: "K"), UInt8(ascii: "K"), UInt8(ascii: "K"), UInt8(ascii: "K"), UInt8(ascii: "L"),
        UInt8(ascii: "L"),
        UInt8(ascii: "L"), UInt8(ascii: "L"), UInt8(ascii: "M"), UInt8(ascii: "M"),
        UInt8(ascii: "M"), UInt8(ascii: "M"), UInt8(ascii: "N"), UInt8(ascii: "N"), UInt8(ascii: "N"),
        UInt8(ascii: "N"),
        UInt8(ascii: "O"), UInt8(ascii: "O"), UInt8(ascii: "O"), UInt8(ascii: "O"),
        UInt8(ascii: "P"), UInt8(ascii: "P"), UInt8(ascii: "P"), UInt8(ascii: "P"), UInt8(ascii: "Q"),
        UInt8(ascii: "Q"),
        UInt8(ascii: "Q"), UInt8(ascii: "Q"), UInt8(ascii: "R"), UInt8(ascii: "R"),
        UInt8(ascii: "R"), UInt8(ascii: "R"), UInt8(ascii: "S"), UInt8(ascii: "S"), UInt8(ascii: "S"),
        UInt8(ascii: "S"),
        UInt8(ascii: "T"), UInt8(ascii: "T"), UInt8(ascii: "T"), UInt8(ascii: "T"),
        UInt8(ascii: "U"), UInt8(ascii: "U"), UInt8(ascii: "U"), UInt8(ascii: "U"), UInt8(ascii: "V"),
        UInt8(ascii: "V"),
        UInt8(ascii: "V"), UInt8(ascii: "V"), UInt8(ascii: "W"), UInt8(ascii: "W"),
        UInt8(ascii: "W"), UInt8(ascii: "W"), UInt8(ascii: "X"), UInt8(ascii: "X"), UInt8(ascii: "X"),
        UInt8(ascii: "X"),
        UInt8(ascii: "Y"), UInt8(ascii: "Y"), UInt8(ascii: "Y"), UInt8(ascii: "Y"),
        UInt8(ascii: "Z"), UInt8(ascii: "Z"), UInt8(ascii: "Z"), UInt8(ascii: "Z"), UInt8(ascii: "a"),
        UInt8(ascii: "a"),
        UInt8(ascii: "a"), UInt8(ascii: "a"), UInt8(ascii: "b"), UInt8(ascii: "b"),
        UInt8(ascii: "b"), UInt8(ascii: "b"), UInt8(ascii: "c"), UInt8(ascii: "c"), UInt8(ascii: "c"),
        UInt8(ascii: "c"),
        UInt8(ascii: "d"), UInt8(ascii: "d"), UInt8(ascii: "d"), UInt8(ascii: "d"),
        UInt8(ascii: "e"), UInt8(ascii: "e"), UInt8(ascii: "e"), UInt8(ascii: "e"), UInt8(ascii: "f"),
        UInt8(ascii: "f"),
        UInt8(ascii: "f"), UInt8(ascii: "f"), UInt8(ascii: "g"), UInt8(ascii: "g"),
        UInt8(ascii: "g"), UInt8(ascii: "g"), UInt8(ascii: "h"), UInt8(ascii: "h"), UInt8(ascii: "h"),
        UInt8(ascii: "h"),
        UInt8(ascii: "i"), UInt8(ascii: "i"), UInt8(ascii: "i"), UInt8(ascii: "i"),
        UInt8(ascii: "j"), UInt8(ascii: "j"), UInt8(ascii: "j"), UInt8(ascii: "j"), UInt8(ascii: "k"),
        UInt8(ascii: "k"),
        UInt8(ascii: "k"), UInt8(ascii: "k"), UInt8(ascii: "l"), UInt8(ascii: "l"),
        UInt8(ascii: "l"), UInt8(ascii: "l"), UInt8(ascii: "m"), UInt8(ascii: "m"), UInt8(ascii: "m"),
        UInt8(ascii: "m"),
        UInt8(ascii: "n"), UInt8(ascii: "n"), UInt8(ascii: "n"), UInt8(ascii: "n"),
        UInt8(ascii: "o"), UInt8(ascii: "o"), UInt8(ascii: "o"), UInt8(ascii: "o"), UInt8(ascii: "p"),
        UInt8(ascii: "p"),
        UInt8(ascii: "p"), UInt8(ascii: "p"), UInt8(ascii: "q"), UInt8(ascii: "q"),
        UInt8(ascii: "q"), UInt8(ascii: "q"), UInt8(ascii: "r"), UInt8(ascii: "r"), UInt8(ascii: "r"),
        UInt8(ascii: "r"),
        UInt8(ascii: "s"), UInt8(ascii: "s"), UInt8(ascii: "s"), UInt8(ascii: "s"),
        UInt8(ascii: "t"), UInt8(ascii: "t"), UInt8(ascii: "t"), UInt8(ascii: "t"), UInt8(ascii: "u"),
        UInt8(ascii: "u"),
        UInt8(ascii: "u"), UInt8(ascii: "u"), UInt8(ascii: "v"), UInt8(ascii: "v"),
        UInt8(ascii: "v"), UInt8(ascii: "v"), UInt8(ascii: "w"), UInt8(ascii: "w"), UInt8(ascii: "w"),
        UInt8(ascii: "w"),
        UInt8(ascii: "x"), UInt8(ascii: "x"), UInt8(ascii: "x"), UInt8(ascii: "x"),
        UInt8(ascii: "y"), UInt8(ascii: "y"), UInt8(ascii: "y"), UInt8(ascii: "y"), UInt8(ascii: "z"),
        UInt8(ascii: "z"),
        UInt8(ascii: "z"), UInt8(ascii: "z"), UInt8(ascii: "0"), UInt8(ascii: "0"),
        UInt8(ascii: "0"), UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "1"), UInt8(ascii: "1"),
        UInt8(ascii: "1"),
        UInt8(ascii: "2"), UInt8(ascii: "2"), UInt8(ascii: "2"), UInt8(ascii: "2"),
        UInt8(ascii: "3"), UInt8(ascii: "3"), UInt8(ascii: "3"), UInt8(ascii: "3"), UInt8(ascii: "4"),
        UInt8(ascii: "4"),
        UInt8(ascii: "4"), UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "5"),
        UInt8(ascii: "5"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "6"), UInt8(ascii: "6"),
        UInt8(ascii: "6"),
        UInt8(ascii: "7"), UInt8(ascii: "7"), UInt8(ascii: "7"), UInt8(ascii: "7"),
        UInt8(ascii: "8"), UInt8(ascii: "8"), UInt8(ascii: "8"), UInt8(ascii: "8"), UInt8(ascii: "9"),
        UInt8(ascii: "9"),
        UInt8(ascii: "9"), UInt8(ascii: "9"), UInt8(ascii: "+"), UInt8(ascii: "+"),
        UInt8(ascii: "+"), UInt8(ascii: "+"), UInt8(ascii: "/"), UInt8(ascii: "/"), UInt8(ascii: "/"),
        UInt8(ascii: "/"),
    ]

    @usableFromInline
    static let encoding1: [UInt8] = [
        UInt8(ascii: "A"), UInt8(ascii: "B"), UInt8(ascii: "C"), UInt8(ascii: "D"), UInt8(ascii: "E"),
        UInt8(ascii: "F"),
        UInt8(ascii: "G"), UInt8(ascii: "H"), UInt8(ascii: "I"), UInt8(ascii: "J"),
        UInt8(ascii: "K"), UInt8(ascii: "L"), UInt8(ascii: "M"), UInt8(ascii: "N"), UInt8(ascii: "O"),
        UInt8(ascii: "P"),
        UInt8(ascii: "Q"), UInt8(ascii: "R"), UInt8(ascii: "S"), UInt8(ascii: "T"),
        UInt8(ascii: "U"), UInt8(ascii: "V"), UInt8(ascii: "W"), UInt8(ascii: "X"), UInt8(ascii: "Y"),
        UInt8(ascii: "Z"),
        UInt8(ascii: "a"), UInt8(ascii: "b"), UInt8(ascii: "c"), UInt8(ascii: "d"),
        UInt8(ascii: "e"), UInt8(ascii: "f"), UInt8(ascii: "g"), UInt8(ascii: "h"), UInt8(ascii: "i"),
        UInt8(ascii: "j"),
        UInt8(ascii: "k"), UInt8(ascii: "l"), UInt8(ascii: "m"), UInt8(ascii: "n"),
        UInt8(ascii: "o"), UInt8(ascii: "p"), UInt8(ascii: "q"), UInt8(ascii: "r"), UInt8(ascii: "s"),
        UInt8(ascii: "t"),
        UInt8(ascii: "u"), UInt8(ascii: "v"), UInt8(ascii: "w"), UInt8(ascii: "x"),
        UInt8(ascii: "y"), UInt8(ascii: "z"), UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"),
        UInt8(ascii: "3"),
        UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "7"),
        UInt8(ascii: "8"), UInt8(ascii: "9"), UInt8(ascii: "+"), UInt8(ascii: "/"), UInt8(ascii: "A"),
        UInt8(ascii: "B"),
        UInt8(ascii: "C"), UInt8(ascii: "D"), UInt8(ascii: "E"), UInt8(ascii: "F"),
        UInt8(ascii: "G"), UInt8(ascii: "H"), UInt8(ascii: "I"), UInt8(ascii: "J"), UInt8(ascii: "K"),
        UInt8(ascii: "L"),
        UInt8(ascii: "M"), UInt8(ascii: "N"), UInt8(ascii: "O"), UInt8(ascii: "P"),
        UInt8(ascii: "Q"), UInt8(ascii: "R"), UInt8(ascii: "S"), UInt8(ascii: "T"), UInt8(ascii: "U"),
        UInt8(ascii: "V"),
        UInt8(ascii: "W"), UInt8(ascii: "X"), UInt8(ascii: "Y"), UInt8(ascii: "Z"),
        UInt8(ascii: "a"), UInt8(ascii: "b"), UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"),
        UInt8(ascii: "f"),
        UInt8(ascii: "g"), UInt8(ascii: "h"), UInt8(ascii: "i"), UInt8(ascii: "j"),
        UInt8(ascii: "k"), UInt8(ascii: "l"), UInt8(ascii: "m"), UInt8(ascii: "n"), UInt8(ascii: "o"),
        UInt8(ascii: "p"),
        UInt8(ascii: "q"), UInt8(ascii: "r"), UInt8(ascii: "s"), UInt8(ascii: "t"),
        UInt8(ascii: "u"), UInt8(ascii: "v"), UInt8(ascii: "w"), UInt8(ascii: "x"), UInt8(ascii: "y"),
        UInt8(ascii: "z"),
        UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "3"),
        UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "7"), UInt8(ascii: "8"),
        UInt8(ascii: "9"),
        UInt8(ascii: "+"), UInt8(ascii: "/"), UInt8(ascii: "A"), UInt8(ascii: "B"),
        UInt8(ascii: "C"), UInt8(ascii: "D"), UInt8(ascii: "E"), UInt8(ascii: "F"), UInt8(ascii: "G"),
        UInt8(ascii: "H"),
        UInt8(ascii: "I"), UInt8(ascii: "J"), UInt8(ascii: "K"), UInt8(ascii: "L"),
        UInt8(ascii: "M"), UInt8(ascii: "N"), UInt8(ascii: "O"), UInt8(ascii: "P"), UInt8(ascii: "Q"),
        UInt8(ascii: "R"),
        UInt8(ascii: "S"), UInt8(ascii: "T"), UInt8(ascii: "U"), UInt8(ascii: "V"),
        UInt8(ascii: "W"), UInt8(ascii: "X"), UInt8(ascii: "Y"), UInt8(ascii: "Z"), UInt8(ascii: "a"),
        UInt8(ascii: "b"),
        UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"), UInt8(ascii: "f"),
        UInt8(ascii: "g"), UInt8(ascii: "h"), UInt8(ascii: "i"), UInt8(ascii: "j"), UInt8(ascii: "k"),
        UInt8(ascii: "l"),
        UInt8(ascii: "m"), UInt8(ascii: "n"), UInt8(ascii: "o"), UInt8(ascii: "p"),
        UInt8(ascii: "q"), UInt8(ascii: "r"), UInt8(ascii: "s"), UInt8(ascii: "t"), UInt8(ascii: "u"),
        UInt8(ascii: "v"),
        UInt8(ascii: "w"), UInt8(ascii: "x"), UInt8(ascii: "y"), UInt8(ascii: "z"),
        UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "3"), UInt8(ascii: "4"),
        UInt8(ascii: "5"),
        UInt8(ascii: "6"), UInt8(ascii: "7"), UInt8(ascii: "8"), UInt8(ascii: "9"),
        UInt8(ascii: "+"), UInt8(ascii: "/"), UInt8(ascii: "A"), UInt8(ascii: "B"), UInt8(ascii: "C"),
        UInt8(ascii: "D"),
        UInt8(ascii: "E"), UInt8(ascii: "F"), UInt8(ascii: "G"), UInt8(ascii: "H"),
        UInt8(ascii: "I"), UInt8(ascii: "J"), UInt8(ascii: "K"), UInt8(ascii: "L"), UInt8(ascii: "M"),
        UInt8(ascii: "N"),
        UInt8(ascii: "O"), UInt8(ascii: "P"), UInt8(ascii: "Q"), UInt8(ascii: "R"),
        UInt8(ascii: "S"), UInt8(ascii: "T"), UInt8(ascii: "U"), UInt8(ascii: "V"), UInt8(ascii: "W"),
        UInt8(ascii: "X"),
        UInt8(ascii: "Y"), UInt8(ascii: "Z"), UInt8(ascii: "a"), UInt8(ascii: "b"),
        UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"), UInt8(ascii: "f"), UInt8(ascii: "g"),
        UInt8(ascii: "h"),
        UInt8(ascii: "i"), UInt8(ascii: "j"), UInt8(ascii: "k"), UInt8(ascii: "l"),
        UInt8(ascii: "m"), UInt8(ascii: "n"), UInt8(ascii: "o"), UInt8(ascii: "p"), UInt8(ascii: "q"),
        UInt8(ascii: "r"),
        UInt8(ascii: "s"), UInt8(ascii: "t"), UInt8(ascii: "u"), UInt8(ascii: "v"),
        UInt8(ascii: "w"), UInt8(ascii: "x"), UInt8(ascii: "y"), UInt8(ascii: "z"), UInt8(ascii: "0"),
        UInt8(ascii: "1"),
        UInt8(ascii: "2"), UInt8(ascii: "3"), UInt8(ascii: "4"), UInt8(ascii: "5"),
        UInt8(ascii: "6"), UInt8(ascii: "7"), UInt8(ascii: "8"), UInt8(ascii: "9"), UInt8(ascii: "+"),
        UInt8(ascii: "/"),
    ]

    @usableFromInline
    static let encoding0url: [UInt8] = [
        UInt8(ascii: "A"), UInt8(ascii: "A"), UInt8(ascii: "A"), UInt8(ascii: "A"), UInt8(ascii: "B"),
        UInt8(ascii: "B"),
        UInt8(ascii: "B"), UInt8(ascii: "B"), UInt8(ascii: "C"), UInt8(ascii: "C"),
        UInt8(ascii: "C"), UInt8(ascii: "C"), UInt8(ascii: "D"), UInt8(ascii: "D"), UInt8(ascii: "D"),
        UInt8(ascii: "D"),
        UInt8(ascii: "E"), UInt8(ascii: "E"), UInt8(ascii: "E"), UInt8(ascii: "E"),
        UInt8(ascii: "F"), UInt8(ascii: "F"), UInt8(ascii: "F"), UInt8(ascii: "F"), UInt8(ascii: "G"),
        UInt8(ascii: "G"),
        UInt8(ascii: "G"), UInt8(ascii: "G"), UInt8(ascii: "H"), UInt8(ascii: "H"),
        UInt8(ascii: "H"), UInt8(ascii: "H"), UInt8(ascii: "I"), UInt8(ascii: "I"), UInt8(ascii: "I"),
        UInt8(ascii: "I"),
        UInt8(ascii: "J"), UInt8(ascii: "J"), UInt8(ascii: "J"), UInt8(ascii: "J"),
        UInt8(ascii: "K"), UInt8(ascii: "K"), UInt8(ascii: "K"), UInt8(ascii: "K"), UInt8(ascii: "L"),
        UInt8(ascii: "L"),
        UInt8(ascii: "L"), UInt8(ascii: "L"), UInt8(ascii: "M"), UInt8(ascii: "M"),
        UInt8(ascii: "M"), UInt8(ascii: "M"), UInt8(ascii: "N"), UInt8(ascii: "N"), UInt8(ascii: "N"),
        UInt8(ascii: "N"),
        UInt8(ascii: "O"), UInt8(ascii: "O"), UInt8(ascii: "O"), UInt8(ascii: "O"),
        UInt8(ascii: "P"), UInt8(ascii: "P"), UInt8(ascii: "P"), UInt8(ascii: "P"), UInt8(ascii: "Q"),
        UInt8(ascii: "Q"),
        UInt8(ascii: "Q"), UInt8(ascii: "Q"), UInt8(ascii: "R"), UInt8(ascii: "R"),
        UInt8(ascii: "R"), UInt8(ascii: "R"), UInt8(ascii: "S"), UInt8(ascii: "S"), UInt8(ascii: "S"),
        UInt8(ascii: "S"),
        UInt8(ascii: "T"), UInt8(ascii: "T"), UInt8(ascii: "T"), UInt8(ascii: "T"),
        UInt8(ascii: "U"), UInt8(ascii: "U"), UInt8(ascii: "U"), UInt8(ascii: "U"), UInt8(ascii: "V"),
        UInt8(ascii: "V"),
        UInt8(ascii: "V"), UInt8(ascii: "V"), UInt8(ascii: "W"), UInt8(ascii: "W"),
        UInt8(ascii: "W"), UInt8(ascii: "W"), UInt8(ascii: "X"), UInt8(ascii: "X"), UInt8(ascii: "X"),
        UInt8(ascii: "X"),
        UInt8(ascii: "Y"), UInt8(ascii: "Y"), UInt8(ascii: "Y"), UInt8(ascii: "Y"),
        UInt8(ascii: "Z"), UInt8(ascii: "Z"), UInt8(ascii: "Z"), UInt8(ascii: "Z"), UInt8(ascii: "a"),
        UInt8(ascii: "a"),
        UInt8(ascii: "a"), UInt8(ascii: "a"), UInt8(ascii: "b"), UInt8(ascii: "b"),
        UInt8(ascii: "b"), UInt8(ascii: "b"), UInt8(ascii: "c"), UInt8(ascii: "c"), UInt8(ascii: "c"),
        UInt8(ascii: "c"),
        UInt8(ascii: "d"), UInt8(ascii: "d"), UInt8(ascii: "d"), UInt8(ascii: "d"),
        UInt8(ascii: "e"), UInt8(ascii: "e"), UInt8(ascii: "e"), UInt8(ascii: "e"), UInt8(ascii: "f"),
        UInt8(ascii: "f"),
        UInt8(ascii: "f"), UInt8(ascii: "f"), UInt8(ascii: "g"), UInt8(ascii: "g"),
        UInt8(ascii: "g"), UInt8(ascii: "g"), UInt8(ascii: "h"), UInt8(ascii: "h"), UInt8(ascii: "h"),
        UInt8(ascii: "h"),
        UInt8(ascii: "i"), UInt8(ascii: "i"), UInt8(ascii: "i"), UInt8(ascii: "i"),
        UInt8(ascii: "j"), UInt8(ascii: "j"), UInt8(ascii: "j"), UInt8(ascii: "j"), UInt8(ascii: "k"),
        UInt8(ascii: "k"),
        UInt8(ascii: "k"), UInt8(ascii: "k"), UInt8(ascii: "l"), UInt8(ascii: "l"),
        UInt8(ascii: "l"), UInt8(ascii: "l"), UInt8(ascii: "m"), UInt8(ascii: "m"), UInt8(ascii: "m"),
        UInt8(ascii: "m"),
        UInt8(ascii: "n"), UInt8(ascii: "n"), UInt8(ascii: "n"), UInt8(ascii: "n"),
        UInt8(ascii: "o"), UInt8(ascii: "o"), UInt8(ascii: "o"), UInt8(ascii: "o"), UInt8(ascii: "p"),
        UInt8(ascii: "p"),
        UInt8(ascii: "p"), UInt8(ascii: "p"), UInt8(ascii: "q"), UInt8(ascii: "q"),
        UInt8(ascii: "q"), UInt8(ascii: "q"), UInt8(ascii: "r"), UInt8(ascii: "r"), UInt8(ascii: "r"),
        UInt8(ascii: "r"),
        UInt8(ascii: "s"), UInt8(ascii: "s"), UInt8(ascii: "s"), UInt8(ascii: "s"),
        UInt8(ascii: "t"), UInt8(ascii: "t"), UInt8(ascii: "t"), UInt8(ascii: "t"), UInt8(ascii: "u"),
        UInt8(ascii: "u"),
        UInt8(ascii: "u"), UInt8(ascii: "u"), UInt8(ascii: "v"), UInt8(ascii: "v"),
        UInt8(ascii: "v"), UInt8(ascii: "v"), UInt8(ascii: "w"), UInt8(ascii: "w"), UInt8(ascii: "w"),
        UInt8(ascii: "w"),
        UInt8(ascii: "x"), UInt8(ascii: "x"), UInt8(ascii: "x"), UInt8(ascii: "x"),
        UInt8(ascii: "y"), UInt8(ascii: "y"), UInt8(ascii: "y"), UInt8(ascii: "y"), UInt8(ascii: "z"),
        UInt8(ascii: "z"),
        UInt8(ascii: "z"), UInt8(ascii: "z"), UInt8(ascii: "0"), UInt8(ascii: "0"),
        UInt8(ascii: "0"), UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "1"), UInt8(ascii: "1"),
        UInt8(ascii: "1"),
        UInt8(ascii: "2"), UInt8(ascii: "2"), UInt8(ascii: "2"), UInt8(ascii: "2"),
        UInt8(ascii: "3"), UInt8(ascii: "3"), UInt8(ascii: "3"), UInt8(ascii: "3"), UInt8(ascii: "4"),
        UInt8(ascii: "4"),
        UInt8(ascii: "4"), UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "5"),
        UInt8(ascii: "5"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "6"), UInt8(ascii: "6"),
        UInt8(ascii: "6"),
        UInt8(ascii: "7"), UInt8(ascii: "7"), UInt8(ascii: "7"), UInt8(ascii: "7"),
        UInt8(ascii: "8"), UInt8(ascii: "8"), UInt8(ascii: "8"), UInt8(ascii: "8"), UInt8(ascii: "9"),
        UInt8(ascii: "9"),
        UInt8(ascii: "9"), UInt8(ascii: "9"), UInt8(ascii: "-"), UInt8(ascii: "-"),
        UInt8(ascii: "-"), UInt8(ascii: "-"), UInt8(ascii: "_"), UInt8(ascii: "_"), UInt8(ascii: "_"),
        UInt8(ascii: "_"),
    ]

    @usableFromInline
    static let encoding1url: [UInt8] = [
        UInt8(ascii: "A"), UInt8(ascii: "B"), UInt8(ascii: "C"), UInt8(ascii: "D"), UInt8(ascii: "E"),
        UInt8(ascii: "F"),
        UInt8(ascii: "G"), UInt8(ascii: "H"), UInt8(ascii: "I"), UInt8(ascii: "J"),
        UInt8(ascii: "K"), UInt8(ascii: "L"), UInt8(ascii: "M"), UInt8(ascii: "N"), UInt8(ascii: "O"),
        UInt8(ascii: "P"),
        UInt8(ascii: "Q"), UInt8(ascii: "R"), UInt8(ascii: "S"), UInt8(ascii: "T"),
        UInt8(ascii: "U"), UInt8(ascii: "V"), UInt8(ascii: "W"), UInt8(ascii: "X"), UInt8(ascii: "Y"),
        UInt8(ascii: "Z"),
        UInt8(ascii: "a"), UInt8(ascii: "b"), UInt8(ascii: "c"), UInt8(ascii: "d"),
        UInt8(ascii: "e"), UInt8(ascii: "f"), UInt8(ascii: "g"), UInt8(ascii: "h"), UInt8(ascii: "i"),
        UInt8(ascii: "j"),
        UInt8(ascii: "k"), UInt8(ascii: "l"), UInt8(ascii: "m"), UInt8(ascii: "n"),
        UInt8(ascii: "o"), UInt8(ascii: "p"), UInt8(ascii: "q"), UInt8(ascii: "r"), UInt8(ascii: "s"),
        UInt8(ascii: "t"),
        UInt8(ascii: "u"), UInt8(ascii: "v"), UInt8(ascii: "w"), UInt8(ascii: "x"),
        UInt8(ascii: "y"), UInt8(ascii: "z"), UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"),
        UInt8(ascii: "3"),
        UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "7"),
        UInt8(ascii: "8"), UInt8(ascii: "9"), UInt8(ascii: "-"), UInt8(ascii: "_"), UInt8(ascii: "A"),
        UInt8(ascii: "B"),
        UInt8(ascii: "C"), UInt8(ascii: "D"), UInt8(ascii: "E"), UInt8(ascii: "F"),
        UInt8(ascii: "G"), UInt8(ascii: "H"), UInt8(ascii: "I"), UInt8(ascii: "J"), UInt8(ascii: "K"),
        UInt8(ascii: "L"),
        UInt8(ascii: "M"), UInt8(ascii: "N"), UInt8(ascii: "O"), UInt8(ascii: "P"),
        UInt8(ascii: "Q"), UInt8(ascii: "R"), UInt8(ascii: "S"), UInt8(ascii: "T"), UInt8(ascii: "U"),
        UInt8(ascii: "V"),
        UInt8(ascii: "W"), UInt8(ascii: "X"), UInt8(ascii: "Y"), UInt8(ascii: "Z"),
        UInt8(ascii: "a"), UInt8(ascii: "b"), UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"),
        UInt8(ascii: "f"),
        UInt8(ascii: "g"), UInt8(ascii: "h"), UInt8(ascii: "i"), UInt8(ascii: "j"),
        UInt8(ascii: "k"), UInt8(ascii: "l"), UInt8(ascii: "m"), UInt8(ascii: "n"), UInt8(ascii: "o"),
        UInt8(ascii: "p"),
        UInt8(ascii: "q"), UInt8(ascii: "r"), UInt8(ascii: "s"), UInt8(ascii: "t"),
        UInt8(ascii: "u"), UInt8(ascii: "v"), UInt8(ascii: "w"), UInt8(ascii: "x"), UInt8(ascii: "y"),
        UInt8(ascii: "z"),
        UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "3"),
        UInt8(ascii: "4"), UInt8(ascii: "5"), UInt8(ascii: "6"), UInt8(ascii: "7"), UInt8(ascii: "8"),
        UInt8(ascii: "9"),
        UInt8(ascii: "-"), UInt8(ascii: "_"), UInt8(ascii: "A"), UInt8(ascii: "B"),
        UInt8(ascii: "C"), UInt8(ascii: "D"), UInt8(ascii: "E"), UInt8(ascii: "F"), UInt8(ascii: "G"),
        UInt8(ascii: "H"),
        UInt8(ascii: "I"), UInt8(ascii: "J"), UInt8(ascii: "K"), UInt8(ascii: "L"),
        UInt8(ascii: "M"), UInt8(ascii: "N"), UInt8(ascii: "O"), UInt8(ascii: "P"), UInt8(ascii: "Q"),
        UInt8(ascii: "R"),
        UInt8(ascii: "S"), UInt8(ascii: "T"), UInt8(ascii: "U"), UInt8(ascii: "V"),
        UInt8(ascii: "W"), UInt8(ascii: "X"), UInt8(ascii: "Y"), UInt8(ascii: "Z"), UInt8(ascii: "a"),
        UInt8(ascii: "b"),
        UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"), UInt8(ascii: "f"),
        UInt8(ascii: "g"), UInt8(ascii: "h"), UInt8(ascii: "i"), UInt8(ascii: "j"), UInt8(ascii: "k"),
        UInt8(ascii: "l"),
        UInt8(ascii: "m"), UInt8(ascii: "n"), UInt8(ascii: "o"), UInt8(ascii: "p"),
        UInt8(ascii: "q"), UInt8(ascii: "r"), UInt8(ascii: "s"), UInt8(ascii: "t"), UInt8(ascii: "u"),
        UInt8(ascii: "v"),
        UInt8(ascii: "w"), UInt8(ascii: "x"), UInt8(ascii: "y"), UInt8(ascii: "z"),
        UInt8(ascii: "0"), UInt8(ascii: "1"), UInt8(ascii: "2"), UInt8(ascii: "3"), UInt8(ascii: "4"),
        UInt8(ascii: "5"),
        UInt8(ascii: "6"), UInt8(ascii: "7"), UInt8(ascii: "8"), UInt8(ascii: "9"),
        UInt8(ascii: "-"), UInt8(ascii: "_"), UInt8(ascii: "A"), UInt8(ascii: "B"), UInt8(ascii: "C"),
        UInt8(ascii: "D"),
        UInt8(ascii: "E"), UInt8(ascii: "F"), UInt8(ascii: "G"), UInt8(ascii: "H"),
        UInt8(ascii: "I"), UInt8(ascii: "J"), UInt8(ascii: "K"), UInt8(ascii: "L"), UInt8(ascii: "M"),
        UInt8(ascii: "N"),
        UInt8(ascii: "O"), UInt8(ascii: "P"), UInt8(ascii: "Q"), UInt8(ascii: "R"),
        UInt8(ascii: "S"), UInt8(ascii: "T"), UInt8(ascii: "U"), UInt8(ascii: "V"), UInt8(ascii: "W"),
        UInt8(ascii: "X"),
        UInt8(ascii: "Y"), UInt8(ascii: "Z"), UInt8(ascii: "a"), UInt8(ascii: "b"),
        UInt8(ascii: "c"), UInt8(ascii: "d"), UInt8(ascii: "e"), UInt8(ascii: "f"), UInt8(ascii: "g"),
        UInt8(ascii: "h"),
        UInt8(ascii: "i"), UInt8(ascii: "j"), UInt8(ascii: "k"), UInt8(ascii: "l"),
        UInt8(ascii: "m"), UInt8(ascii: "n"), UInt8(ascii: "o"), UInt8(ascii: "p"), UInt8(ascii: "q"),
        UInt8(ascii: "r"),
        UInt8(ascii: "s"), UInt8(ascii: "t"), UInt8(ascii: "u"), UInt8(ascii: "v"),
        UInt8(ascii: "w"), UInt8(ascii: "x"), UInt8(ascii: "y"), UInt8(ascii: "z"), UInt8(ascii: "0"),
        UInt8(ascii: "1"),
        UInt8(ascii: "2"), UInt8(ascii: "3"), UInt8(ascii: "4"), UInt8(ascii: "5"),
        UInt8(ascii: "6"), UInt8(ascii: "7"), UInt8(ascii: "8"), UInt8(ascii: "9"), UInt8(ascii: "-"),
        UInt8(ascii: "_"),
    ]

    @inlinable
    internal static func encodeBytes<Buffer: Collection>(bytes: Buffer, options: EncodingOptions = [])
        -> [UInt8] where Buffer.Element == UInt8 {
        let newCapacity = ((bytes.count + 2) / 3) * 4

        if let result = bytes.withContiguousStorageIfAvailable({ input -> [UInt8] in
            [UInt8](unsafeUninitializedCapacity: newCapacity) { buffer, length in
                Self._encodeChromium(input: input, buffer: buffer, length: &length, options: options)
            }
        }) {
            return result
        }

        return self.encodeBytes(bytes: Array(bytes), options: options)
    }

    @inlinable
    internal static func encodeString<Buffer: Collection>(bytes: Buffer, options: EncodingOptions = [])
        -> String where Buffer.Element == UInt8 {
        let newCapacity = ((bytes.count + 2) / 3) * 4

        #if swift(>=5.3)
        if #available(OSX 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
            if let result = bytes.withContiguousStorageIfAvailable({ input -> String in
                String(unsafeUninitializedCapacity: newCapacity) { buffer -> Int in
                    var length = newCapacity
                    Self._encodeChromium(input: input, buffer: buffer, length: &length, options: options)
                    return length
                }
            }) {
                return result
            }

            return self.encodeString(bytes: Array(bytes), options: options)
        } else {
            let bytes: [UInt8] = self.encodeBytes(bytes: bytes, options: options)
            return String(decoding: bytes, as: Unicode.UTF8.self)
        }
        #else
        let bytes: [UInt8] = self.encodeBytes(bytes: bytes, options: options)
        return String(decoding: bytes, as: Unicode.UTF8.self)
        #endif
    }

    @inlinable
    static func _encodeChromium(
        input: UnsafeBufferPointer<UInt8>,
        buffer: UnsafeMutableBufferPointer<UInt8>,
        length: inout Int,
        options: EncodingOptions
    ) {
        let omitPaddingCharacter = options.contains(.omitPaddingCharacter)

        Self.withUnsafeEncodingTablesAsBufferPointers(options: options) { e0, e1 in
            let to = input.count / 3 * 3
            var outIndex = 0
            for index in stride(from: 0, to: to, by: 3) {
                let i1 = input[index]
                let i2 = input[index + 1]
                let i3 = input[index + 2]
                buffer[outIndex] = e0[Int(i1)]
                buffer[outIndex + 1] = e1[Int(((i1 & 0x03) << 4) | ((i2 >> 4) & 0x0F))]
                buffer[outIndex + 2] = e1[Int(((i2 & 0x0F) << 2) | ((i3 >> 6) & 0x03))]
                buffer[outIndex + 3] = e1[Int(i3)]
                outIndex += 4
            }

            if to < input.count {
                let index = to

                let i1 = input[index]
                let i2 = index + 1 < input.count ? input[index + 1] : nil
                let i3 = index + 2 < input.count ? input[index + 2] : nil

                buffer[outIndex] = e0[Int(i1)]

                if let i2 = i2, let i3 = i3 {
                    buffer[outIndex + 1] = e1[Int(((i1 & 0x03) << 4) | ((i2 >> 4) & 0x0F))]
                    buffer[outIndex + 2] = e1[Int(((i2 & 0x0F) << 2) | ((i3 >> 6) & 0x03))]
                    buffer[outIndex + 3] = e1[Int(i3)]
                    outIndex += 4
                } else if let i2 = i2 {
                    buffer[outIndex + 1] = e1[Int(((i1 & 0x03) << 4) | ((i2 >> 4) & 0x0F))]
                    buffer[outIndex + 2] = e1[Int((i2 & 0x0F) << 2)]
                    outIndex += 3
                    if !omitPaddingCharacter {
                        buffer[outIndex] = Self.encodePaddingCharacter
                        outIndex += 1
                    }
                } else {
                    buffer[outIndex + 1] = e1[Int((i1 & 0x03) << 4)]
                    outIndex += 2
                    if !omitPaddingCharacter {
                        buffer[outIndex] = Self.encodePaddingCharacter
                        buffer[outIndex + 1] = Self.encodePaddingCharacter
                        outIndex += 2
                    }
                }
            }

            length = outIndex
        }
    }

    @inlinable
    static func withUnsafeEncodingTablesAsBufferPointers<R>(
        options: Base64.EncodingOptions,
        _ body: (UnsafeBufferPointer<UInt8>, UnsafeBufferPointer<UInt8>) throws -> R
    ) rethrows -> R {
        let encoding0 = options.contains(.base64UrlAlphabet) ? Self.encoding0url : Self.encoding0
        let encoding1 = options.contains(.base64UrlAlphabet) ? Self.encoding1url : Self.encoding1

        assert(encoding0.count == 256)
        assert(encoding1.count == 256)

        return try encoding0.withUnsafeBufferPointer { e0 -> R in
            try encoding1.withUnsafeBufferPointer { e1 -> R in
                try body(e0, e1)
            }
        }
    }
}

// MARK: - Decoding -

extension Base64 {
    @usableFromInline
    internal struct DecodingOptions: OptionSet {
        @usableFromInline
        internal let rawValue: UInt

        @inlinable
        internal init(rawValue: UInt) { self.rawValue = rawValue }

        @usableFromInline
        internal static let base64UrlAlphabet = DecodingOptions(rawValue: UInt(1 << 0))

        @usableFromInline
        internal static let omitPaddingCharacter = DecodingOptions(rawValue: UInt(1 << 1))
    }

    @usableFromInline
    internal enum DecodingError: Error, Equatable {
        case invalidLength
        case invalidCharacter(UInt8)
        case unexpectedPaddingCharacter
        case unexpectedEnd
    }

    @inlinable
    internal static func decode(string encoded: String, options: DecodingOptions = []) throws -> [UInt8] {
        let decoded = try encoded.utf8.withContiguousStorageIfAvailable { characterPointer -> [UInt8] in
            guard characterPointer.count > 0 else {
                return []
            }

            let outputLength = ((characterPointer.count + 3) / 4) * 3

            return try characterPointer.withMemoryRebound(to: UInt8.self) { input -> [UInt8] in
                try [UInt8](unsafeUninitializedCapacity: outputLength) { output, length in
                    try Self._decodeChromium(from: input, into: output, length: &length, options: options)
                }
            }
        }

        if decoded != nil {
            return decoded!
        }

        var encoded = encoded
        encoded.makeContiguousUTF8()
        return try Self.decode(string: encoded, options: options)
    }

    @inlinable
    internal static func decode<Buffer: Collection>(bytes: Buffer, options: DecodingOptions = []) throws -> [UInt8]
        where Buffer.Element == UInt8 {
        guard bytes.count > 0 else {
            return []
        }

        let decoded = try bytes.withContiguousStorageIfAvailable { input -> [UInt8] in
            let outputLength = ((input.count + 3) / 4) * 3

            return try [UInt8](unsafeUninitializedCapacity: outputLength) { output, length in
                try Self._decodeChromium(from: input, into: output, length: &length, options: options)
            }
        }

        if decoded != nil {
            return decoded!
        }

        return try self.decode(bytes: Array(bytes), options: options)
    }

    @inlinable
    static func _decodeChromium(
        from inBuffer: UnsafeBufferPointer<UInt8>,
        into outBuffer: UnsafeMutableBufferPointer<UInt8>,
        length: inout Int,
        options: DecodingOptions = []
    ) throws {
        let remaining = inBuffer.count % 4
        switch (options.contains(.omitPaddingCharacter), remaining) {
        case (false, 1...):
            throw DecodingError.invalidLength
        case (true, 1):
            throw DecodingError.invalidLength
        default:
            // everythin alright so far
            break
        }

        let outputLength = ((inBuffer.count + 3) / 4) * 3
        let fullchunks = remaining == 0 ? inBuffer.count / 4 - 1 : inBuffer.count / 4
        guard outBuffer.count >= outputLength else {
            preconditionFailure("Expected the out buffer to be at least as long as outputLength")
        }

        try Self.withUnsafeDecodingTablesAsBufferPointers(options: options) { d0, d1, d2, d3 in
            var outIndex = 0
            if fullchunks > 0 {
                for chunk in 0..<fullchunks {
                    let inIndex = chunk * 4
                    let a0 = inBuffer[inIndex]
                    let a1 = inBuffer[inIndex + 1]
                    let a2 = inBuffer[inIndex + 2]
                    let a3 = inBuffer[inIndex + 3]
                    var x: UInt32 = d0[Int(a0)] | d1[Int(a1)] | d2[Int(a2)] | d3[Int(a3)]

                    if x >= Self.badCharacter {
                        // TODO: Inspect characters here better
                        throw DecodingError.invalidCharacter(inBuffer[inIndex])
                    }

                    withUnsafePointer(to: &x) { ptr in
                        ptr.withMemoryRebound(to: UInt8.self, capacity: 4) { newPtr in
                            outBuffer[outIndex] = newPtr[0]
                            outBuffer[outIndex + 1] = newPtr[1]
                            outBuffer[outIndex + 2] = newPtr[2]
                            outIndex += 3
                        }
                    }
                }
            }

            // inIndex is the first index in the last chunk
            let inIndex = fullchunks * 4
            let a0 = inBuffer[inIndex]
            let a1 = inBuffer[inIndex + 1]
            var a2: UInt8?
            var a3: UInt8?
            if inIndex + 2 < inBuffer.count, inBuffer[inIndex + 2] != Self.encodePaddingCharacter {
                a2 = inBuffer[inIndex + 2]
            }
            if inIndex + 3 < inBuffer.count, inBuffer[inIndex + 3] != Self.encodePaddingCharacter {
                a3 = inBuffer[inIndex + 3]
            }

            var x: UInt32 = d0[Int(a0)] | d1[Int(a1)] | d2[Int(a2 ?? 65)] | d3[Int(a3 ?? 65)]
            if x >= Self.badCharacter {
                // TODO: Inspect characters here better
                throw DecodingError.invalidCharacter(inBuffer[inIndex])
            }

            withUnsafePointer(to: &x) { ptr in
                ptr.withMemoryRebound(to: UInt8.self, capacity: 4) { newPtr in
                    outBuffer[outIndex] = newPtr[0]
                    outIndex += 1
                    if a2 != nil {
                        outBuffer[outIndex] = newPtr[1]
                        outIndex += 1
                    }
                    if a3 != nil {
                        outBuffer[outIndex] = newPtr[2]
                        outIndex += 1
                    }
                }
            }

            length = outIndex
        }
    }

    @usableFromInline
    static func withUnsafeDecodingTablesAsBufferPointers<R>(
        options: Base64.DecodingOptions,
        _ body: (
            UnsafeBufferPointer<UInt32>,
            UnsafeBufferPointer<UInt32>,
            UnsafeBufferPointer<UInt32>,
            UnsafeBufferPointer<UInt32>
        ) throws -> R
    ) rethrows -> R {
        let decoding0 = options.contains(.base64UrlAlphabet) ? Self.decoding0url : Self.decoding0
        let decoding1 = options.contains(.base64UrlAlphabet) ? Self.decoding1url : Self.decoding1
        let decoding2 = options.contains(.base64UrlAlphabet) ? Self.decoding2url : Self.decoding2
        let decoding3 = options.contains(.base64UrlAlphabet) ? Self.decoding3url : Self.decoding3

        assert(decoding0.count == 256)
        assert(decoding1.count == 256)
        assert(decoding2.count == 256)
        assert(decoding3.count == 256)

        return try decoding0.withUnsafeBufferPointer { d0 -> R in
            try decoding1.withUnsafeBufferPointer { d1 -> R in
                try decoding2.withUnsafeBufferPointer { d2 -> R in
                    try decoding3.withUnsafeBufferPointer { d3 -> R in
                        try body(d0, d1, d2, d3)
                    }
                }
            }
        }
    }

    @usableFromInline
    static let badCharacter: UInt32 = 0x01FF_FFFF

    @usableFromInline
    static let decoding0: [UInt32] = [
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x0000_00F8, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_00FC,
        0x0000_00D0, 0x0000_00D4, 0x0000_00D8, 0x0000_00DC, 0x0000_00E0, 0x0000_00E4,
        0x0000_00E8, 0x0000_00EC, 0x0000_00F0, 0x0000_00F4, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_0000,
        0x0000_0004, 0x0000_0008, 0x0000_000C, 0x0000_0010, 0x0000_0014, 0x0000_0018,
        0x0000_001C, 0x0000_0020, 0x0000_0024, 0x0000_0028, 0x0000_002C, 0x0000_0030,
        0x0000_0034, 0x0000_0038, 0x0000_003C, 0x0000_0040, 0x0000_0044, 0x0000_0048,
        0x0000_004C, 0x0000_0050, 0x0000_0054, 0x0000_0058, 0x0000_005C, 0x0000_0060,
        0x0000_0064, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x0000_0068, 0x0000_006C, 0x0000_0070, 0x0000_0074, 0x0000_0078,
        0x0000_007C, 0x0000_0080, 0x0000_0084, 0x0000_0088, 0x0000_008C, 0x0000_0090,
        0x0000_0094, 0x0000_0098, 0x0000_009C, 0x0000_00A0, 0x0000_00A4, 0x0000_00A8,
        0x0000_00AC, 0x0000_00B0, 0x0000_00B4, 0x0000_00B8, 0x0000_00BC, 0x0000_00C0,
        0x0000_00C4, 0x0000_00C8, 0x0000_00CC, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
    ]

    @usableFromInline
    static let decoding1: [UInt32] = [
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x0000_E003, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_F003,
        0x0000_4003, 0x0000_5003, 0x0000_6003, 0x0000_7003, 0x0000_8003, 0x0000_9003,
        0x0000_A003, 0x0000_B003, 0x0000_C003, 0x0000_D003, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_0000,
        0x0000_1000, 0x0000_2000, 0x0000_3000, 0x0000_4000, 0x0000_5000, 0x0000_6000,
        0x0000_7000, 0x0000_8000, 0x0000_9000, 0x0000_A000, 0x0000_B000, 0x0000_C000,
        0x0000_D000, 0x0000_E000, 0x0000_F000, 0x0000_0001, 0x0000_1001, 0x0000_2001,
        0x0000_3001, 0x0000_4001, 0x0000_5001, 0x0000_6001, 0x0000_7001, 0x0000_8001,
        0x0000_9001, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x0000_A001, 0x0000_B001, 0x0000_C001, 0x0000_D001, 0x0000_E001,
        0x0000_F001, 0x0000_0002, 0x0000_1002, 0x0000_2002, 0x0000_3002, 0x0000_4002,
        0x0000_5002, 0x0000_6002, 0x0000_7002, 0x0000_8002, 0x0000_9002, 0x0000_A002,
        0x0000_B002, 0x0000_C002, 0x0000_D002, 0x0000_E002, 0x0000_F002, 0x0000_0003,
        0x0000_1003, 0x0000_2003, 0x0000_3003, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
    ]

    @usableFromInline
    static let decoding2: [UInt32] = [
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x0080_0F00, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x00C0_0F00,
        0x0000_0D00, 0x0040_0D00, 0x0080_0D00, 0x00C0_0D00, 0x0000_0E00, 0x0040_0E00,
        0x0080_0E00, 0x00C0_0E00, 0x0000_0F00, 0x0040_0F00, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_0000,
        0x0040_0000, 0x0080_0000, 0x00C0_0000, 0x0000_0100, 0x0040_0100, 0x0080_0100,
        0x00C0_0100, 0x0000_0200, 0x0040_0200, 0x0080_0200, 0x00C0_0200, 0x0000_0300,
        0x0040_0300, 0x0080_0300, 0x00C0_0300, 0x0000_0400, 0x0040_0400, 0x0080_0400,
        0x00C0_0400, 0x0000_0500, 0x0040_0500, 0x0080_0500, 0x00C0_0500, 0x0000_0600,
        0x0040_0600, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x0080_0600, 0x00C0_0600, 0x0000_0700, 0x0040_0700, 0x0080_0700,
        0x00C0_0700, 0x0000_0800, 0x0040_0800, 0x0080_0800, 0x00C0_0800, 0x0000_0900,
        0x0040_0900, 0x0080_0900, 0x00C0_0900, 0x0000_0A00, 0x0040_0A00, 0x0080_0A00,
        0x00C0_0A00, 0x0000_0B00, 0x0040_0B00, 0x0080_0B00, 0x00C0_0B00, 0x0000_0C00,
        0x0040_0C00, 0x0080_0C00, 0x00C0_0C00, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
    ]

    @usableFromInline
    static let decoding3: [UInt32] = [
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x003E_0000, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x003F_0000,
        0x0034_0000, 0x0035_0000, 0x0036_0000, 0x0037_0000, 0x0038_0000, 0x0039_0000,
        0x003A_0000, 0x003B_0000, 0x003C_0000, 0x003D_0000, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_0000,
        0x0001_0000, 0x0002_0000, 0x0003_0000, 0x0004_0000, 0x0005_0000, 0x0006_0000,
        0x0007_0000, 0x0008_0000, 0x0009_0000, 0x000A_0000, 0x000B_0000, 0x000C_0000,
        0x000D_0000, 0x000E_0000, 0x000F_0000, 0x0010_0000, 0x0011_0000, 0x0012_0000,
        0x0013_0000, 0x0014_0000, 0x0015_0000, 0x0016_0000, 0x0017_0000, 0x0018_0000,
        0x0019_0000, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x001A_0000, 0x001B_0000, 0x001C_0000, 0x001D_0000, 0x001E_0000,
        0x001F_0000, 0x0020_0000, 0x0021_0000, 0x0022_0000, 0x0023_0000, 0x0024_0000,
        0x0025_0000, 0x0026_0000, 0x0027_0000, 0x0028_0000, 0x0029_0000, 0x002A_0000,
        0x002B_0000, 0x002C_0000, 0x002D_0000, 0x002E_0000, 0x002F_0000, 0x0030_0000,
        0x0031_0000, 0x0032_0000, 0x0033_0000, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
    ]

    @usableFromInline
    static let decoding0url: [UInt32] = [
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 0
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 6
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 12
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 18
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 24
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 30
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 36
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_00F8, 0x01FF_FFFF, 0x01FF_FFFF, // 42
        0x0000_00D0, 0x0000_00D4, 0x0000_00D8, 0x0000_00DC, 0x0000_00E0, 0x0000_00E4, // 48
        0x0000_00E8, 0x0000_00EC, 0x0000_00F0, 0x0000_00F4, 0x01FF_FFFF, 0x01FF_FFFF, // 54
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_0000, // 60
        0x0000_0004, 0x0000_0008, 0x0000_000C, 0x0000_0010, 0x0000_0014, 0x0000_0018, // 66
        0x0000_001C, 0x0000_0020, 0x0000_0024, 0x0000_0028, 0x0000_002C, 0x0000_0030, // 72
        0x0000_0034, 0x0000_0038, 0x0000_003C, 0x0000_0040, 0x0000_0044, 0x0000_0048, // 78
        0x0000_004C, 0x0000_0050, 0x0000_0054, 0x0000_0058, 0x0000_005C, 0x0000_0060, // 84
        0x0000_0064, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_00FC, // 90
        0x01FF_FFFF, 0x0000_0068, 0x0000_006C, 0x0000_0070, 0x0000_0074, 0x0000_0078,
        0x0000_007C, 0x0000_0080, 0x0000_0084, 0x0000_0088, 0x0000_008C, 0x0000_0090,
        0x0000_0094, 0x0000_0098, 0x0000_009C, 0x0000_00A0, 0x0000_00A4, 0x0000_00A8,
        0x0000_00AC, 0x0000_00B0, 0x0000_00B4, 0x0000_00B8, 0x0000_00BC, 0x0000_00C0,
        0x0000_00C4, 0x0000_00C8, 0x0000_00CC, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
    ]

    @usableFromInline
    static let decoding1url: [UInt32] = [
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 0
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 6
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 12
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 18
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 24
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 30
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 36
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_E003, 0x01FF_FFFF, 0x01FF_FFFF, // 42
        0x0000_4003, 0x0000_5003, 0x0000_6003, 0x0000_7003, 0x0000_8003, 0x0000_9003, // 48
        0x0000_A003, 0x0000_B003, 0x0000_C003, 0x0000_D003, 0x01FF_FFFF, 0x01FF_FFFF, // 54
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_0000, // 60
        0x0000_1000, 0x0000_2000, 0x0000_3000, 0x0000_4000, 0x0000_5000, 0x0000_6000, // 66
        0x0000_7000, 0x0000_8000, 0x0000_9000, 0x0000_A000, 0x0000_B000, 0x0000_C000, // 72
        0x0000_D000, 0x0000_E000, 0x0000_F000, 0x0000_0001, 0x0000_1001, 0x0000_2001, // 78
        0x0000_3001, 0x0000_4001, 0x0000_5001, 0x0000_6001, 0x0000_7001, 0x0000_8001, // 84
        0x0000_9001, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_F003, // 90
        0x01FF_FFFF, 0x0000_A001, 0x0000_B001, 0x0000_C001, 0x0000_D001, 0x0000_E001,
        0x0000_F001, 0x0000_0002, 0x0000_1002, 0x0000_2002, 0x0000_3002, 0x0000_4002,
        0x0000_5002, 0x0000_6002, 0x0000_7002, 0x0000_8002, 0x0000_9002, 0x0000_A002,
        0x0000_B002, 0x0000_C002, 0x0000_D002, 0x0000_E002, 0x0000_F002, 0x0000_0003,
        0x0000_1003, 0x0000_2003, 0x0000_3003, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
    ]

    @usableFromInline
    static let decoding2url: [UInt32] = [
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 0
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 6
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 12
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 18
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 24
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 30
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 36
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0080_0F00, 0x01FF_FFFF, 0x01FF_FFFF, // 42
        0x0000_0D00, 0x0040_0D00, 0x0080_0D00, 0x00C0_0D00, 0x0000_0E00, 0x0040_0E00, // 48
        0x0080_0E00, 0x00C0_0E00, 0x0000_0F00, 0x0040_0F00, 0x01FF_FFFF, 0x01FF_FFFF, // 54
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_0000, // 60
        0x0040_0000, 0x0080_0000, 0x00C0_0000, 0x0000_0100, 0x0040_0100, 0x0080_0100, // 66
        0x00C0_0100, 0x0000_0200, 0x0040_0200, 0x0080_0200, 0x00C0_0200, 0x0000_0300, // 72
        0x0040_0300, 0x0080_0300, 0x00C0_0300, 0x0000_0400, 0x0040_0400, 0x0080_0400, // 78
        0x00C0_0400, 0x0000_0500, 0x0040_0500, 0x0080_0500, 0x00C0_0500, 0x0000_0600, // 84
        0x0040_0600, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x00C0_0F00, // 90
        0x01FF_FFFF, 0x0080_0600, 0x00C0_0600, 0x0000_0700, 0x0040_0700, 0x0080_0700,
        0x00C0_0700, 0x0000_0800, 0x0040_0800, 0x0080_0800, 0x00C0_0800, 0x0000_0900,
        0x0040_0900, 0x0080_0900, 0x00C0_0900, 0x0000_0A00, 0x0040_0A00, 0x0080_0A00,
        0x00C0_0A00, 0x0000_0B00, 0x0040_0B00, 0x0080_0B00, 0x00C0_0B00, 0x0000_0C00,
        0x0040_0C00, 0x0080_0C00, 0x00C0_0C00, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
    ]

    @usableFromInline
    static let decoding3url: [UInt32] = [
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 0
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 6
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 12
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 18
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 24
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 30
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, // 36
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x003E_0000, 0x01FF_FFFF, 0x01FF_FFFF, // 42
        0x0034_0000, 0x0035_0000, 0x0036_0000, 0x0037_0000, 0x0038_0000, 0x0039_0000, // 48
        0x003A_0000, 0x003B_0000, 0x003C_0000, 0x003D_0000, 0x01FF_FFFF, 0x01FF_FFFF, // 54
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x0000_0000, // 60
        0x0001_0000, 0x0002_0000, 0x0003_0000, 0x0004_0000, 0x0005_0000, 0x0006_0000, // 66
        0x0007_0000, 0x0008_0000, 0x0009_0000, 0x000A_0000, 0x000B_0000, 0x000C_0000, // 72
        0x000D_0000, 0x000E_0000, 0x000F_0000, 0x0010_0000, 0x0011_0000, 0x0012_0000, // 78
        0x0013_0000, 0x0014_0000, 0x0015_0000, 0x0016_0000, 0x0017_0000, 0x0018_0000, // 84
        0x0019_0000, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x003F_0000, // 90
        0x01FF_FFFF, 0x001A_0000, 0x001B_0000, 0x001C_0000, 0x001D_0000, 0x001E_0000,
        0x001F_0000, 0x0020_0000, 0x0021_0000, 0x0022_0000, 0x0023_0000, 0x0024_0000,
        0x0025_0000, 0x0026_0000, 0x0027_0000, 0x0028_0000, 0x0029_0000, 0x002A_0000,
        0x002B_0000, 0x002C_0000, 0x002D_0000, 0x002E_0000, 0x002F_0000, 0x0030_0000,
        0x0031_0000, 0x0032_0000, 0x0033_0000, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
        0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF, 0x01FF_FFFF,
    ]
}
