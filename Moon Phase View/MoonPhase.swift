//
//  MoonPhase.swift
//  Moon Phase View
//
//  Calculations following Chapronts moon theory ELP-2000/82
//  plus Bretagnons and Francous theory VSOP87 for the sun
//  algorithms given by Jean Meeus
//
//  Created by Erich Küster on August 23, 2016
//  Copyright © 2016 Erich Küster. All rights reserved.
//

import Cocoa

class MoonPhase: NSObject {
    var lunation: Int = 0
    var phase: Int = 0
    var eventBegin = NSDate()
    var localizedEventBegin = ""
    var eventName: String = ""

    private var moonAngles: [Double] = []

    let eventNames: [String] = [
        NSLocalizedString("new moon", comment: "first moon phase"),
        NSLocalizedString("crescent moon", comment: "second moon phase"),
        NSLocalizedString("full moon", comment: "third moon phase"),
        NSLocalizedString("waning moon", comment: "last moon phase")
    ]

    let moonPhaseData =  [
        [2451550.09766, 29.530588861, 0.00015437, -0.00000015,  0.00000000073],
        [      2.5534,  29.10535669, -0.0000014,  -0.00000011,  0],
        [    201.5643, 385.81693528,  0.0107582,   0.00001238, -0.000000058],
        [    160.7108, 390.67050284, -0.0016118,  -0.00000227,  0.000000011],
        [    124.7746,  -1.56375588,  0.0020672,   0.00000215,  0]
    ]
    // coefficients for new moon, full moon, first/last quarter
    let moonPhaseCoeffs = [
//        [-0.00017, -0.00017, -0.00017], // coefficients of sin(Omega)
        [-0.40720, -0.40614, -0.62801],
        [ 0.17241,  0.17302,  0.17172],
        [ 0.01608,  0.01614,  0.00862],
        [ 0.01039,  0.01043,  0.00804],
        [ 0.00739,  0.00734,  0.00454],
        [-0.00514, -0.00515, -0.01183],
        [ 0.00208,  0.00209,  0.00204],
        [-0.00111, -0.00111, -0.00180],
        [-0.00057, -0.00057, -0.00070],
        [ 0.00056,  0.00056,  0.00027],
        [-0.00042, -0.00042, -0.00040],
        [ 0.00042,  0.00042,  0.00032],
        [ 0.00038,  0.00038,  0.00032],
        [-0.00024, -0.00024, -0.00034],
        [-0.00007, -0.00007, -0.00028],
        [ 0.00004,  0.00004,  0.00002],
        [ 0.00004,  0.00004,  0.00003],
        [ 0.00003,  0.00003,  0.00003],
        [ 0.00003,  0.00003,  0.00004],
        [-0.00003, -0.00003, -0.00004],
        [ 0.00003,  0.00003,  0.00002],
        [-0.00002, -0.00002, -0.00005],
        [-0.00002, -0.00002, -0.00002],
        [ 0.00002,  0.00002,  0.0],
        [ 0.0    ,  0.0    ,  0.00004]
    ]
    // which values of M, M', F and E shall be used
    // first three - value is negative, 0 do not use, 1 use one, 2 use double, 3 use triple, 4 use quadrupel
    // last - 0 do not use E, 1 use E, 2 use E square
    var moonPhaseFactors: [[Int]] = [
        [ 0, 1, 0, 0], [ 1, 0, 0, 1], [ 0, 2, 0, 0], [ 0, 0, 2, 0],
        [-1, 1, 0, 1], [ 1, 1, 0, 1], [ 2, 0, 0, 2], [ 0, 1,-2, 0],
        [ 0, 1, 2, 0], [ 1, 2, 0, 1], [ 0, 3, 0, 0], [ 1, 0, 2, 1],
        [ 1, 0,-2, 1], [-1, 2, 0, 1], [ 2, 1, 0, 0], [ 0, 2,-2, 0],
        [ 3, 0, 0, 0], [ 1, 1,-2, 0], [ 0, 2, 2, 0], [ 1, 1, 2, 0],
        [-1, 1, 2, 1], [-1, 1,-2, 0], [ 1, 3, 0, 0], [ 0, 4, 0, 0],
        [-2, 1, 0, 0]
    ]
    // Coefficients of A1 - A14.
    let moonPhaseExtras = [
        [299.77,  0.107408, 0.000325],
        [251.88,  0.016321, 0.000165],
        [251.83, 26.651886, 0.000164],
        [349.42, 36.412478, 0.000126],
        [ 84.66, 18.206239, 0.000110],
        [141.74, 53.303771, 0.000062],
        [207.14,  2.153732, 0.000060],
        [154.84,  7.306860, 0.000056],
        [ 34.52, 27.261239, 0.000047],
        [207.19,  0.121824, 0.000042],
        [291.34,  1.844379, 0.000040],
        [161.72, 24.198154, 0.000037],
        [239.56, 25.513099, 0.000035],
        [331.55,  3.592518, 0.000023]
    ]
    let rads: Double = 0.0174532925199433  // pi / 180

    init(luna: Int, ph: Int) {
        lunation = luna
        phase = ph
        eventName = eventNames[ph]
    }

    func sortDatesAscending (moonPhase: MoonPhase) -> Bool {
        // NSOrderedAscending = -1, NSOrderedSame, NSOrderedDescending
        return (eventBegin.compare(moonPhase.eventBegin) == NSComparisonResult.OrderedAscending)
    }

    private func evaluateMoonPhaseData(k: Double, T: Double) -> Double {
        // evaluate jde, M, MStrich, F, Omega and store sinus of the last four sequentially into an array
        // jde  : julian ephemeris day, read more at <https://en.wikipedia.org/wiki/Terrestrial_Time>
        // M    : mean anomaly of the sun at time jde
        // M'   : mean anomaly of the moon at time jde
        // F    : moon's argument of latitude
        // Omega: longitude of the ascending node of the lunar orbit
        var items: [Double] = []
        for moonItems in moonPhaseData {
            var poly = 0.0
            for (n, moonItem) in moonItems.enumerate().reverse() {
                switch n {
                case 0:
                    poly += moonItem
                case 1:
                    poly *= T
                    poly += k * moonItem
                default:
                    poly += moonItem
                    poly *= T
                }
            }
            items.append(poly)
        }
        for item in items[1...4] {
            moonAngles.append(item * rads)
        }
        return items[0]
    }

    // corrections for new, full moon , first / last quarter of moon
    func correctMoon(col: Int, E: Double) -> Double {
        // array moonAngles contains M, MStrich, F and Omega
        let E2 = E * E
        var add: [Double] = [-0.00017 * sin(moonAngles[3])]
        for (phaseFactors, phaseCoeffs) in zip(moonPhaseFactors, moonPhaseCoeffs) {
            var value = 0.0
            for (index, phaseFactor) in phaseFactors.enumerate() {
                let aFactor = abs(phaseFactor)
                let dFactor = Double(phaseFactor)
                if (aFactor != 0) {
                    value += dFactor * moonAngles[index]
                }
                if (index == 2) {
                    break
                }
            }
            var sinValue = sin(value)
            switch phaseFactors[3] {
            case 1:
                sinValue *= E
            case 2:
                sinValue *= E2
            default:
                break
            }
            add.append(phaseCoeffs[col] * sinValue)
        }
        return add.reduce(0, combine: +)
    }

    private func evalW(E: Double) -> Double {
        let coeffs: [Double] = [-0.00038, 0.00026, -0.00002, 0.00002, 0.00002]
        // M, M', F
        let factors: [[Int]] = [
            [ 1,  0,  0],
            [ 0,  1,  0],
            [-1,  1,  0],
            [ 1,  1,  0],
            [ 0,  0,  2]
        ]
        var w: [Double] = [0.00306]
        for (fs, c) in zip(factors, coeffs) {
            var value = 0.0
            for (index, f) in fs.enumerate() {
                let aFactor = abs(f)
                let dFactor = Double(f)
                if (aFactor != 0) {
                    value += dFactor * moonAngles[index]
                }
                if (index == 2) {
                    break
                }
            }
            w.append(c * cos(value))
        }
        w[1] *= E
        return w.reduce(0, combine: +)
    }

    func eventBeginPastJulianDay(jd: Double) -> Void {
        // next moon phase after julian day
        // from the Book Jean Meeus, Astronomische Algorithmen, p. 348 ff.
        // lunations since new moon on january 6, 2000
        let k: Double = (jd - 2451550.09765) / 29.530588853
        let k0: Double = floor(k) + Double(lunation) + Double(phase) * 0.25
        // time in julian centuries since epoche Y2000
        let T = k0 / 1236.85
        // eccentricity of the orbit of earth
        let E = 1 - T * (0.002516 + T * 0.0000074)
        let jde = evaluateMoonPhaseData(k0, T: T)
        // apply perturbation terms due to sun and planets
        // first the sun
        var sun: Double = 0.0
        switch (phase) {
        case 0:
            sun = correctMoon(0, E: E)
       case 1, 3:
            sun = correctMoon(2, E: E)
            if (phase == 1) {
                sun += evalW(E)
            }
            else {
                sun -= evalW(E)
            }
        case 2:
            sun = correctMoon(1, E: E)
        default:
            Swift.print(NSLocalizedString("Phase not between 0 and 3", comment: "no real moon phase"))
        }
        // extra perturbations due to planets
        var planets = 0.0
        var As: [Double] = []
        for extra in moonPhaseExtras {
            As.append((extra[0] + k0 * extra[1]) * rads)
        }
        As[0] -= 0.009173 * T * T * rads
        for (moonPhaseExtra, A) in zip(moonPhaseExtras, As) {
            // moonPhaseExtras and array of As run synchronously
            planets += moonPhaseExtra[2] * sin(A)
        }
        // beginning of event, expressed in seconds relative to January 1, 2001 as NSDate object
        eventBegin = NSDate(timeIntervalSinceReferenceDate: (jde + sun + planets - 2451910.5) * 86400)
    }
}
