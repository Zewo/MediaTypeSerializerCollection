// MediaTypeParserCollection.swift
//
// The MIT License (MIT)
//
// Copyright (c) 2015 Zewo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

@_exported import MediaType
@_exported import InterchangeData

public enum MediaTypeSerializerCollectionError: ErrorProtocol {
    case NoSuitableSerializer
    case MediaTypeNotFound
}

public final class MediaTypeSerializerCollection {
    public var serializers: [(MediaType, InterchangeDataSerializer)] = []

    public var mediaTypes: [MediaType] {
        return serializers.map({$0.0})
    }

    public init() {}

    public func setPriority(mediaTypes: MediaType...) throws {
        for mediaType in mediaTypes.reversed() {
            try setTopPriority(mediaType)
        }
    }

    public func setTopPriority(mediaType: MediaType) throws {
        for index in 0 ..< serializers.count {
            let tuple = serializers[index]
            if tuple.0 == mediaType {
                serializers.remove(at: index)
                serializers.insert(tuple, at: 0)
                return
            }
        }

        throw MediaTypeSerializerCollectionError.MediaTypeNotFound
    }

    public func add(mediaType: MediaType, serializer: InterchangeDataSerializer) {
        serializers.append(mediaType, serializer)
    }

    public func serializersFor(mediaType: MediaType) -> [(MediaType, InterchangeDataSerializer)] {
        return serializers.reduce([]) {
            if $1.0.matches(mediaType) {
                return $0 + [($1.0, $1.1)]
            } else {
                return $0
            }
        }
    }

    public func serialize(data: InterchangeData, mediaTypes: [MediaType]) throws -> (MediaType, Data) {
        var lastError: ErrorProtocol?

        for acceptedType in mediaTypes {
            for (mediaType, serializer) in serializersFor(acceptedType) {
                do {
                    return try (mediaType, serializer.serialize(data))
                } catch {
                    lastError = error
                    continue
                }
            }
        }

        if let lastError = lastError {
            throw lastError
        } else {
            throw MediaTypeSerializerCollectionError.NoSuitableSerializer
        }
    }
}
