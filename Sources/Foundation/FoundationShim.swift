// import Swift

//#endif
// #elseif os(WASI)
//     @_exported import FoundationEssentials
// #elseif os(Linux)
//@_exported import FoundationEssentials
//#endif
// #if canImport(Foundation)
//     @_exported import Foundation
// #else
@_exported import FoundationEssentials

public typealias CGFloat = Float

public struct Bundle: Sendable {
    public static let main = Bundle(path: FileManager.default.currentDirectoryPath)!

    public init?(path: String) {
        self.bundlePath = path
    }

    public func path(forResource name: String, ofType ext: String? = nil) -> String? {
        // This is a stub implementation for the sake of compatibility.
        return nil
    }

    public var bundlePath: String

}

nonisolated public struct CGPoint: Equatable, Sendable {
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    public var x: CGFloat
    public var y: CGFloat

    public static let zero = CGPoint(x: 0, y: 0)
}

nonisolated public struct CGSize: Equatable, Sendable {
    public static let zero = CGSize(width: Float.zero, height: Float.zero)

    public init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }

    public static func fromDouble(width: Double, height: Double) -> CGSize {
        return CGSize.init(width: CGFloat(width), height: CGFloat(height))
    }

    public var width: CGFloat
    public var height: CGFloat
}

nonisolated public struct CGRect: Equatable, Sendable {
    public init(origin: CGPoint, size: CGSize) {
        self.origin = origin
        self.size = size
    }

    public var origin: CGPoint
    public var size: CGSize

    public static let zero = CGRect(x: 0, y: 0, width: 0, height: 0)

    public var height: CGFloat {
        get { size.height }
        set { size.height = newValue }
    }
    public var width: CGFloat {
        get { size.width }
        set { size.width = newValue }
    }

    public var minX: CGFloat {
        get { origin.x }
        set { origin.x = newValue }
    }

    public var minY: CGFloat {
        get { origin.y }
        set { origin.y = newValue }
    }

    public var midX: CGFloat {
        return origin.x + size.width / 2
    }

    public var midY: CGFloat {
        return origin.y + size.height / 2
    }

    public var maxX: CGFloat {
        return origin.x + size.width
    }
    public var maxY: CGFloat {
        return origin.y + size.height
    }
}

extension CGRect {

    public init(x: CGFloat = 0, y: CGFloat = 0, width: CGFloat, height: CGFloat) {
        self.origin = CGPoint(x: x, y: y)
        self.size = CGSize(width: width, height: height)
    }
}
