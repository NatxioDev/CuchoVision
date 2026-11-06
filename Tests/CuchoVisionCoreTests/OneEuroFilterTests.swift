import XCTest
@testable import CuchoVisionCore

final class OneEuroFilterTests: XCTestCase {
    func testFirstSamplePassesThrough() {
        var filter = OneEuroFilter(minCutoff: 1, beta: 0, dCutoff: 1)
        XCTAssertEqual(filter.filter(0.25, timestamp: 0), 0.25, accuracy: 1e-12)
    }

    func testConstantSignalStaysConstant() {
        var filter = OneEuroFilter(minCutoff: 1, beta: 0.4, dCutoff: 1)
        var timestamp = 0.0
        var output = 0.0
        for _ in 0..<90 {
            output = filter.filter(2, timestamp: timestamp)
            timestamp += 1.0 / 60.0
        }
        XCTAssertEqual(output, 2, accuracy: 1e-9)
    }

    func testRepeatedTimestampDoesNotExplode() {
        var filter = OneEuroFilter()
        XCTAssertEqual(filter.filter(1, timestamp: 5), 1, accuracy: 1e-12)
        XCTAssertEqual(filter.filter(4, timestamp: 5), 1, accuracy: 1e-12)
        XCTAssertEqual(filter.filter(4, timestamp: 4), 1, accuracy: 1e-12)
    }

    func testLowCutoffAttenuatesHighFrequencyNoise() {
        var filter = OneEuroFilter(minCutoff: 0.4, beta: 0, dCutoff: 1)
        var timestamp = 0.0
        var outputs: [Double] = []
        for index in 0..<180 {
            let noise = index.isMultiple(of: 2) ? 0.2 : -0.2
            outputs.append(filter.filter(noise, timestamp: timestamp))
            timestamp += 1.0 / 60.0
        }
        let settled = outputs.suffix(60)
        XCTAssertLessThan(variance(settled), variance([0.2, -0.2]))
        XCTAssertLessThan(abs(settled.last ?? 1), 0.05)
    }

    func testHigherBetaReachesAStepFaster() {
        XCTAssertGreaterThan(
            stepResponse(beta: 8),
            stepResponse(beta: 0)
        )
    }

    func testResetForgetsPreviousSignal() {
        var filter = OneEuroFilter(minCutoff: 0.2, beta: 0, dCutoff: 1)
        _ = filter.filter(10, timestamp: 0)
        _ = filter.filter(10, timestamp: 0.5)
        filter.reset()
        XCTAssertEqual(filter.filter(-3, timestamp: 0.5), -3, accuracy: 1e-12)
    }

    private func stepResponse(beta: Double) -> Double {
        var filter = OneEuroFilter(minCutoff: 0.5, beta: beta, dCutoff: 1)
        _ = filter.filter(0, timestamp: 0)
        var output = 0.0
        var timestamp = 0.0
        for _ in 0..<6 {
            timestamp += 1.0 / 60.0
            output = filter.filter(1, timestamp: timestamp)
        }
        return output
    }

    private func variance(_ values: some Sequence<Double>) -> Double {
        let samples = Array(values)
        precondition(!samples.isEmpty)
        let mean = samples.reduce(0, +) / Double(samples.count)
        let sum = samples.reduce(0.0) { partial, sample in
            let delta = sample - mean
            return partial + delta * delta
        }
        return sum / Double(samples.count)
    }
}
