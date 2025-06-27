// MARK: - Constants
let π: Float = .pi  // Use built-in Float.pi

// Normalize angle to [-π, π] to improve convergence
public func normalize(_ x: Float) -> Float {
    var x = x.truncatingRemainder(dividingBy: 2 * π)
    if x > π {
        x -= 2 * π
    } else if x < -π {
        x += 2 * π
    }
    return x
}

// MARK: - sin(x) using Taylor expansion
public func sin(_ x: Float) -> Float {
    let x = normalize(x)
    let x2 = x * x
    return x * (1 - x2 / 6 + x2 * x2 / 120 - x2 * x2 * x2 / 5040)
}

// MARK: - cos(x) using Taylor expansion
public func cos(_ x: Float) -> Float {
    let x = normalize(x)
    let x2 = x * x
    return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720
}

// MARK: - tan(x) = sin(x) / cos(x)
public func tan(_ x: Float) -> Float {
    sin(x) / cos(x)
}

// MARK: - pow(x, n) for integer exponents
public func pow(_ base: Float, _ exponent: Double) -> Float {
    var result: Float = 1
    var b = base
    var e = exponent

    if e < 0 {
        b = 1 / b
        e = -e
    }

    while e > 0 {
        if e.truncatingRemainder(dividingBy: 2) == 1 {
            result *= b
        }
        b *= b
        e /= 2
    }

    return result
}

// MARK: - sqrt(x) using Newton-Raphson
public func sqrt(_ x: Float, epsilon: Float = 1e-6) -> Float {
    if x == 0 { return 0 }
    var guess = x / 2
    while abs(guess * guess - x) > epsilon {
        guess = 0.5 * (guess + x / guess)
    }
    return guess
}

public let M_E: Float = 2.718281828459045

/// Natural logarithm (ln) using Newton-Raphson method
/// Approximates log(x) such that `exp(y) = x`
public func log(_ x: Float, epsilon: Float = 1e-6) -> Float {
    // Domain check: ln(x) undefined for x <= 0
    guard x > 0 else { return .nan }

    // Initial guess using transformation
    var y = x - 1
    var prev: Float

    repeat {
        prev = y
        // Newton-Raphson step: y = y - (e^y - x) / e^y
        y -= (exp(y) - x) / exp(y)
    } while abs(y - prev) > epsilon

    return y
}

/// exp(x) using Taylor series (12 terms)
public func exp(_ x: Float) -> Float {
    var result: Float = 1
    var term: Float = 1
    for i in 1...12 {
        term *= x / Float(i)
        result += term
    }
    return result
}

// MARK: - Double Utilities
public func normalize(_ x: Double) -> Double {
    var x = x.truncatingRemainder(dividingBy: 2 * Double(π))
    if x > Double(π) {
        x -= 2 * Double(π)
    } else if x < -Double(π) {
        x += 2 * Double(π)
    }
    return x
}

// MARK: - Trigonometric Functions

/// sin(x) using Taylor series approximation
public func sin(_ x: Double) -> Double {
    let x = normalize(x)
    let x2 = x * x
    return x * (1 - x2 / 6 + x2 * x2 / 120 - x2 * x2 * x2 / 5040)
}

/// cos(x) using Taylor series approximation
public func cos(_ x: Double) -> Double {
    let x = normalize(x)
    let x2 = x * x
    return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720
}

/// tan(x) = sin(x) / cos(x)
public func tan(_ x: Double) -> Double {
    sin(x) / cos(x)
}

// MARK: - Power and Root

/// pow(base, exponent) for integer exponent
public func pow(_ base: Double, _ exponent: Int) -> Double {
    var result: Double = 1
    var b = base
    var e = exponent

    if e < 0 {
        b = 1 / b
        e = -e
    }

    while e > 0 {
        if e % 2 == 1 {
            result *= b
        }
        b *= b
        e /= 2
    }

    return result
}

/// sqrt(x) using Newton-Raphson method
public func sqrt(_ x: Double, epsilon: Double = 1e-12) -> Double {
    if x == 0 { return 0 }
    var guess = x / 2
    while abs(guess * guess - x) > epsilon {
        guess = 0.5 * (guess + x / guess)
    }
    return guess
}

// MARK: - Exponential and Logarithmic

/// exp(x) using Taylor series expansion (12 terms)
public func exp(_ x: Double) -> Double {
    var result: Double = 1
    var term: Double = 1
    for i in 1...20 {
        term *= x / Double(i)
        result += term
    }
    return result
}

/// log(x) using Newton-Raphson method: solves exp(y) = x
public func log(_ x: Double, epsilon: Double = 1e-12) -> Double {
    guard x > 0 else { return .nan }

    var y = x - 1
    var prev: Double

    repeat {
        prev = y
        y -= (exp(y) - x) / exp(y)
    } while abs(y - prev) > epsilon

    return y
}
