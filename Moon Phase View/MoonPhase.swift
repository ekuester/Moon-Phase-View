//
//  MoonPhase.swift
//  Moon Phase View
//
//  Created by Erich Küster on 23.08.16.
//  Copyright © 2016 Erich Küster. All rights reserved.
//

import Cocoa

class MoonPhase: NSObject {
    var lunation: Int = 0
    var phase: Int = 0
    var eventBegin = NSDate()
    var localizedEventBegin = ""
    var eventName: String = ""
    
    init(luna: Int, ph: Int) {
        lunation = luna
        phase = ph
    }
    
    func sortDatesAscending (moonPhase: MoonPhase) -> Bool {
        // NSOrderedAscending = -1, NSOrderedSame, NSOrderedDescending
        return (eventBegin.compare(moonPhase.eventBegin) == NSComparisonResult.OrderedAscending)
    }
    
    func correctMoon(coeffs: Array<Double>, E: Double, F: Double, M: Double, MStrich: Double, Omega: Double) -> Double {
        var add = coeffs[0] * sin(MStrich)
        add = add + coeffs[1] * E * sin(M)
        add = add + coeffs[2] * sin(2 * MStrich)
        add = add + coeffs[3] * sin(2 * F)
        add = add + coeffs[4] * E * sin(MStrich - M)
        add = add + coeffs[5] * E * sin(MStrich + M)
        add = add + coeffs[6] * E * E * sin(2 * M)
        add = add + coeffs[7] * sin(MStrich - 2 * F)
        add = add + coeffs[8] * sin(MStrich + 2 * F)
        add = add + coeffs[9] * E * sin(2 * MStrich + M)
        add = add + coeffs[10] * sin(3 * MStrich)
        add = add + coeffs[11] * E * sin(M + 2 * F)
        add = add + coeffs[12] * E * sin(M - 2 * F)
        add = add + coeffs[13] * E * sin(2 * MStrich - M)
        add = add + coeffs[14] * sin(Omega)
        add = add + coeffs[15] * sin(MStrich + 2 * M)
        add = add + coeffs[16] * sin(2 * MStrich - 2 * F)
        add = add + coeffs[17] * sin(3 * M)
        add = add + coeffs[18] * sin(MStrich + M - 2 * F)
        add = add + coeffs[19] * sin(2 * MStrich + 2 * F)
        add = add + coeffs[20] * sin(MStrich + M + 2 * F)
        add = add + coeffs[21] * sin(MStrich - M + 2 * F)
        add = add + coeffs[22] * sin(MStrich - M - 2 * F)
        add = add + coeffs[23] * sin(3 * MStrich + M)
        add = add + coeffs[24] * sin(4 * MStrich)
        return add
    }
    
    func correctQuarter(coeffs: Array<Double>, E: Double, F: Double, M: Double, MStrich: Double, Omega: Double, sign:Int) -> Double {
        // corrections for first resp. last moon quarter
        var add = coeffs[0] * sin(MStrich)
        add = add + coeffs[1] * E * sin(M)
        add = add + coeffs[2] * E * sin(MStrich + M)
        add = add + coeffs[3] * sin(2 * MStrich)
        add = add + coeffs[4] * sin(2 * F)
        add = add + coeffs[5] * E * sin(MStrich - M)
        add = add + coeffs[6] * E * E * sin(2 * M)
        add = add + coeffs[7] * sin(MStrich - 2 * F)
        add = add + coeffs[8] * sin(MStrich + 2 * F)
        add = add + coeffs[9] * sin(3 * MStrich)
        add = add + coeffs[10] * E * sin(2 * MStrich - M)
        add = add + coeffs[11] * E * sin(M + 2 * F)
        add = add + coeffs[12] * E * sin(M - 2 * F)
        add = add + coeffs[13] * E * E * sin(MStrich + 2 * M)
        add = add + coeffs[14] * E * sin(2 * MStrich + M)
        add = add + coeffs[15] * sin(Omega)
        add = add + coeffs[16] * sin(MStrich - M - 2 * F)
        add = add + coeffs[17] * sin(2 * MStrich + 2 * F)
        add = add + coeffs[18] * sin(MStrich + M + 2 * F)
        add = add + coeffs[19] * sin(MStrich - 2 * M)
        add = add + coeffs[20] * sin(MStrich + M - 2 * F)
        add = add + coeffs[21] * sin(3 * M)
        add = add + coeffs[22] * sin(2 * MStrich - 2 * F)
        add = add + coeffs[23] * sin(MStrich - M + 2 * F)
        add = add + coeffs[24] * sin(3 * MStrich + M)
        var W = 0.00306 - 0.00038 * E * Double(cos(M))
        W += 0.00026 * Double(cos(MStrich))
        W -= 2e-05 * Double(cos(MStrich - M))
        W += 2e-05 * Double(cos(MStrich + M))
        W += 2e-05 * Double(cos(2 * F))
        add = add + Double(sign) * W
        return add
    }
    
    func eventBeginPastJulianDay(jd: Double) -> Void {
        // next moon phase after julian day
        // from the Book Jean Meeus, Astronomische Algorithmen, p. 348 ff.
        let rads: Double = 0.0174532925199433
        let nmCoeffList: Array<Double> = [-0.4072, 0.17241, 0.01608, 0.01039, 0.00739, -0.00514, 0.00208, -0.00111, -0.00057, 0.00056, -0.00042, -0.00042, 0.00038, -0.00024, -0.00017, -7e-05, 4e-05, 4e-05, 3e-05, 3e-05, -3e-05, 3e-05, -2e-05, -2e-05, 2e-05]
        let fmCoeffList: Array<Double> = [-0.40614, 0.17302, 0.01614, 0.01043, 0.00734, -0.00515, 0.00209, -0.00111, -0.00057, 0.00056, -0.00042, 0.00042, 0.00038, -0.00024, -0.00017, -7e-05, 4e-05, 4e-05, 3e-05, 3e-05, -3e-05, 3e-05, -2e-05, -2e-05, 2e-05]
        let quCoeffList: Array<Double> = [-0.62801, 0.17172, -0.01183, 0.00862, 0.00804, 0.00454, 0.00204, -0.0018, -0.0007, -0.0004, -0.00034, 0.00032, 0.00032, -0.00028, 0.00027, -0.00017, -5e-05, 4e-05, -4e-05, 4e-05, 3e-05, 3e-05, 2e-05, 2e-05, -2e-05]
        // lunations since new moon on january 6, 2000
        // k = (jd + 1 - 2451550.09765) / 29.530588853;
        let k: Double = (jd - 2451550.09765) / 29.530588853
        let k0: Double = floor(k) + Double(lunation) + Double(phase) * 0.25
        let T = k0 / 1236.85
        let T2 = T * T
        let T3 = T2 * T
        let T4 = T2 * T2
        let E = 1 - 0.002516 * T - 7.4e-06 * T2
        // mean anomaly of sun at time jde
        let M = (2.5534 + 29.10535669 * k0 - 2.18e-05 * T2 - 1.1e-07 * T3) * rads
        // mean anomaly of moon at time jde
        let MStrich = (201.5643 + 385.81693528 * k0 + 0.1017438 * T2 + 1.239e-05 * T3 - 5.8e-08 * T4) * rads
        // Argument der Breite des Mondes
        let F = (160.7108 + 390.67050274 * k0 - 0.0016341 * T2 - 2.27e-06 * T3 + 1.1e-08 * T4) * rads
        // longitude of the ascending node in lunar orbit
        let Omega = (124.7746 - 1.5637558 * k0 + 0.002091 * T2 + 2.15e-06 * T3) * rads
        let jde = 2451550.09765 + 29.530588853 * k0 + 0.0001337 * T2 - 1.5e-07 * T3 + 7.3e-10 * T4
        var add: Double = 0.0
        switch (phase) {
        case 0:
            eventName = NSLocalizedString("new moon", comment: "first moon phase")
            add = correctMoon(nmCoeffList, E: E, F: F, M: M, MStrich: MStrich, Omega: Omega)
        case 1:
            eventName = NSLocalizedString("crescent moon", comment: "second moon phase")
            add = correctQuarter(quCoeffList, E: E, F: F, M: M, MStrich: MStrich, Omega: Omega, sign: 1)
        case 2:
            eventName = NSLocalizedString("full moon", comment: "third moon phase")
            add = correctMoon(fmCoeffList, E: E, F: F, M: M, MStrich: MStrich, Omega: Omega)
        case 3:
            eventName = NSLocalizedString("waning moon", comment: "last moon phase")
            add = correctQuarter(quCoeffList, E: E, F: F, M: M, MStrich: MStrich, Omega: Omega, sign: -1)
        default:
            Swift.print(NSLocalizedString("Phase not between 0 and 3", comment: "no real moon phase"))
            
        }
        // beginning of event, expressed in seconds relative to 1. january 2001 as NSDate object
        eventBegin = NSDate(timeIntervalSinceReferenceDate: (jde + add - 2451910.5) * 86400)
    }
}

