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
    //  2451550.09166 + 29.53O58886t.t+0.00015437..
    let moonPhaseData =  [
        [2451550.09766, 29.530588861, 0.00015437,  0.00000015,  0.00000000073],
        [      2.1534,  29.10535669, -0.0000014,  -0.00000011,  0],
        [    201.5643, 385.81693528,  0.0107582,   0.00001238, -0.000000058],
        [    160.7108, 390.67050284, -0.0016118,  -0.00000227,  0.000000011],
        [    124.7746,  -1.56375580,  0.0020691,   0.00000215,  0]
    ]
    // coefficients for new moon, full moon, first/last quarter
    let moonPhaseCoeffs = [
        [-0.40720, -0.40614, -0.62801],
        [ 0.17241,  0.17302,  0.17172],
        [ 0.01608,  0.01614, -0.01183],
        [ 0.01039,  0.01043,  0.00862],
        [ 0.00739,  0.00734,  0.00804],
        [-0.00514, -0.00515,  0.00454],
        [ 0.00208,  0.00209,  0.00204],
        [-0.00111, -0.00111, -0.00180],
        [-0.00057, -0.00057, -0.00070],
        [ 0.00056,  0.00056, -0.00040],
        [-0.00042, -0.00042, -0.00034],
        [ 0.00042,  0.00042,  0.00032],
        [ 0.00038,  0.00038,  0.00032],
        [-0.00024, -0.00024, -0.00028],
        [-0.00017, -0.00017,  0.00027],
        [-0.00007, -0.00007, -0.00017],
        [ 0.00004,  0.00004, -0.00005],
        [ 0.00004,  0.00004,  0.00004],
        [ 0.00003,  0.00003, -0.00004],
        [ 0.00003,  0.00003,  0.00004],
        [-0.00003, -0.00003,  0.00003],
        [ 0.00003,  0.00003,  0.00003],
        [-0.00002, -0.00002,  0.00002],
        [-0.00002, -0.00002,  0.00002],
        [ 0.00002,  0.00002, -0.00002],
    ]
    // Coefficients of A1 - A14.
    let moonPhaseExtra = [
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
        [331.55,  2.592518, 0.000023]
    ]
    let pi2 = 2.0 * M_PI
    let rads: Double = 0.0174532925199433

    init(luna: Int, ph: Int) {
        lunation = luna
        phase = ph
    }

    func sortDatesAscending (moonPhase: MoonPhase) -> Bool {
        // NSOrderedAscending = -1, NSOrderedSame, NSOrderedDescending
        return (eventBegin.compare(moonPhase.eventBegin) == NSComparisonResult.OrderedAscending)
    }

    func evalMoonPhaseData(n: Int, k: Double, T: Double) -> Double {
        var sum = moonPhaseData[n][0] + k * moonPhaseData[n][1]
        let m2 = moonPhaseData[n][2]
        let m3 = moonPhaseData[n][3]
        let m4 = moonPhaseData[n][4]
        sum = sum + T * T * (m2 + T * (m3 + T * m4))
        if n > 0 {
            sum *= rads
            // reduce angle in radians to the interval 0 ... 2pi
//            sum -= floor (sum / pi2) * pi2
        }
        return sum
    }

    func correctMoon(row: Int, E: Double, F: Double, M: Double, MStrich: Double, Omega: Double) -> Double {
        // corrections for new resp. full moon
        var add = moonPhaseCoeffs[0][row] * sin(MStrich)
        add = add + moonPhaseCoeffs[1][row] * E * sin(M)
        add = add + moonPhaseCoeffs[2][row] * sin(2.0 * MStrich)
        add = add + moonPhaseCoeffs[3][row] * sin(2.0 * F)
        add = add + moonPhaseCoeffs[4][row] * E * sin(MStrich - M)
        add = add + moonPhaseCoeffs[5][row] * E * sin(MStrich + M)
        add = add + moonPhaseCoeffs[6][row] * E * E * sin(2.0 * M)
        add = add + moonPhaseCoeffs[7][row] * sin(MStrich - 2.0 * F)
        add = add + moonPhaseCoeffs[8][row] * sin(MStrich + 2.0 * F)
        add = add + moonPhaseCoeffs[9][row] * E * sin(2.0 * MStrich + M)
        add = add + moonPhaseCoeffs[10][row] * sin(3.0 * MStrich)
        add = add + moonPhaseCoeffs[11][row] * E * sin(M + 2.0 * F)
        add = add + moonPhaseCoeffs[12][row] * E * sin(M - 2.0 * F)
        add = add + moonPhaseCoeffs[13][row] * E * sin(2.0 * MStrich - M)
        add = add + moonPhaseCoeffs[14][row] * sin(Omega)
        add = add + moonPhaseCoeffs[15][row] * sin(MStrich + 2.0 * M)
        add = add + moonPhaseCoeffs[16][row] * sin(2.0 * MStrich - 2.0 * F)
        add = add + moonPhaseCoeffs[17][row] * sin(3.0 * M)
        add = add + moonPhaseCoeffs[18][row] * sin(MStrich + M - 2.0 * F)
        add = add + moonPhaseCoeffs[19][row] * sin(2.0 * MStrich + 2.0 * F)
        add = add + moonPhaseCoeffs[20][row] * sin(MStrich + M + 2.0 * F)
        add = add + moonPhaseCoeffs[21][row] * sin(MStrich - M + 2.0 * F)
        add = add + moonPhaseCoeffs[22][row] * sin(MStrich - M - 2.0 * F)
        add = add + moonPhaseCoeffs[23][row] * sin(3.0 * MStrich + M)
        add = add + moonPhaseCoeffs[24][row] * sin(4 * MStrich)
        return add
    }
    
    func correctQuarter(row: Int, E: Double, F: Double, M: Double, MStrich: Double, Omega: Double) -> Double {
        // corrections for first resp. last moon quarter
        var add = moonPhaseCoeffs[0][row] * sin(MStrich)
        add = add + moonPhaseCoeffs[1][row] * E * sin(M)
        add = add + moonPhaseCoeffs[2][row] * E * sin(MStrich + M)
        add = add + moonPhaseCoeffs[3][row] * sin(2.0 * MStrich)
        add = add + moonPhaseCoeffs[4][row] * sin(2.0 * F)
        add = add + moonPhaseCoeffs[5][row] * E * sin(MStrich - M)
        add = add + moonPhaseCoeffs[6][row] * E * E * sin(2.0 * M)
        add = add + moonPhaseCoeffs[7][row] * sin(MStrich - 2.0 * F)
        add = add + moonPhaseCoeffs[8][row] * sin(MStrich + 2.0 * F)
        add = add + moonPhaseCoeffs[9][row] * sin(3.0 * MStrich)
        add = add + moonPhaseCoeffs[10][row] * E * sin(2.0 * MStrich - M)
        add = add + moonPhaseCoeffs[11][row] * E * sin(M + 2.0 * F)
        add = add + moonPhaseCoeffs[12][row] * E * sin(M - 2.0 * F)
        add = add + moonPhaseCoeffs[13][row] * E * E * sin(MStrich + 2.0 * M)
        add = add + moonPhaseCoeffs[14][row] * E * sin(2.0 * MStrich + M)
        add = add + moonPhaseCoeffs[15][row] * sin(Omega)
        add = add + moonPhaseCoeffs[16][row] * sin(MStrich - M - 2.0 * F)
        add = add + moonPhaseCoeffs[17][row] * sin(2.0 * MStrich + 2.0 * F)
        add = add + moonPhaseCoeffs[18][row] * sin(MStrich + M + 2.0 * F)
        add = add + moonPhaseCoeffs[19][row] * sin(MStrich - 2.0 * M)
        add = add + moonPhaseCoeffs[20][row] * sin(MStrich + M - 2.0 * F)
        add = add + moonPhaseCoeffs[21][row] * sin(3.0 * M)
        add = add + moonPhaseCoeffs[22][row] * sin(2.0 * MStrich - 2.0 * F)
        add = add + moonPhaseCoeffs[23][row] * sin(MStrich - M + 2.0 * F)
        add = add + moonPhaseCoeffs[24][row] * sin(3.0 * MStrich + M)
        return add
    }

    func evalW(E: Double, F: Double, M: Double, MStrich: Double) -> Double {
        var w = 0.00306 - 0.00038 * E * cos(M)
        w += 0.00026 * cos(MStrich)
        w -= 0.00002 * cos(MStrich - M)
        w += 0.00002 * cos(MStrich + M)
        w += 0.00002 * cos(2.0 * F)
        return w
    }

    func eventBeginPastJulianDay(jd: Double) -> Void {
        // next moon phase after julian day
        // from the Book Jean Meeus, Astronomische Algorithmen, p. 348 ff.
        // lunations since new moon on january 6, 2000
        let k: Double = (jd - 2451550.09765) / 29.530588853
        let k0: Double = floor(k) + Double(lunation) + Double(phase) * 0.25
        let T = k0 / 1236.82664
        // excentricity of the orbit of earth
        let E = 1 - T * (0.002516 + T * 0.0000074)
        // julian ephemeris day, read more at <https://en.wikipedia.org/wiki/Terrestrial_Time>
        let jde = evalMoonPhaseData(0, k: k0, T: T)
        // mean anomaly of the sun at time jde
        let M = evalMoonPhaseData(1, k: k0, T: T)
        // mean anomaly of the moon at time jde
        let MStrich = evalMoonPhaseData(2, k: k0, T: T)
        // moon's argument of latitude
        let F = evalMoonPhaseData(3, k: k0, T: T)
        // longitude of the ascending node of the lunar orbit
        let Omega = evalMoonPhaseData(4, k: k0, T: T)
        // apply perturbation terms due to sun and planets
        // first the sun
        var sun: Double = 0.0
        switch (phase) {
        case 0:
            eventName = NSLocalizedString("new moon", comment: "first moon phase")
            sun = correctMoon(0, E: E, F: F, M: M, MStrich: MStrich, Omega: Omega)
        case 1:
            eventName = NSLocalizedString("crescent moon", comment: "second moon phase")
            sun = correctQuarter(2, E: E, F: F, M: M, MStrich: MStrich, Omega: Omega)
            sun = sun + evalW(E, F: F, M: M, MStrich: MStrich)
        case 2:
            eventName = NSLocalizedString("full moon", comment: "third moon phase")
            sun = correctMoon(1, E: E, F: F, M: M, MStrich: MStrich, Omega: Omega)
        case 3:
            eventName = NSLocalizedString("waning moon", comment: "last moon phase")
            sun = correctQuarter(2, E: E, F: F, M: M, MStrich: MStrich, Omega: Omega)
            sun = sun - evalW(E, F: F, M: M, MStrich: MStrich)
        default:
            Swift.print(NSLocalizedString("Phase not between 0 and 3", comment: "no real moon phase"))
        }
        // extra perturbations due to planets
        var planets = 0.0
        var A: [Double] = []
        for i in 0 ..< 14 {
            A.append(moonPhaseExtra[i][0] + k0 * moonPhaseExtra[i][1])
        }
        A[0] -= 0.009173 * T * T
        for i in 0 ..< 14 {
            planets += moonPhaseExtra[i][2] * sin(A[i] * rads)
        }
        // beginning of event, expressed in seconds relative to January 1, 2001 as NSDate object
        eventBegin = NSDate(timeIntervalSinceReferenceDate: (jde + sun + planets - 2451910.5) * 86400)
    }
}
