//
//  ViewController.swift
//  Moon Phase View
//
//  Created by Erich Küster on 23.08.16.
//  Copyright © 2016 Erich Küster. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    @IBOutlet var moonphaseTableView: NSTableView!
    @IBOutlet var yearTextField: NSTextField!

    var formatter = NSDateFormatter()
    var gregorian = NSCalendar(calendarIdentifier: NSCalendarIdentifierGregorian)
    var moonPhaseArray: Array<MoonPhase> = []
    var yearNumber: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // assign TableView specialties
        moonphaseTableView.setDelegate(self)
        moonphaseTableView.setDataSource(self)
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // Methodes for NSTableView
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int
    {
        let numberOfRows: Int = moonPhaseArray.count
        return numberOfRows
    }

    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject?
    {
        let moonPhase: MoonPhase = moonPhaseArray[row]
        return moonPhase.valueForKey(tableColumn!.identifier)
    }

    // add Moon Phase to array
    func addMoonphase(moonPhase: MoonPhase) -> Void {
        moonPhaseArray.append(moonPhase)
    }

    // read yearTextField
    func getYearNumber() -> Int? {
        let year = yearTextField.integerValue
        if (year < 1600 || year > 2399) {
            let message = NSLocalizedString("Input Error", comment: "general error")
            let info = NSLocalizedString("Year must be between 1600 and 2399", comment: "correct input")
            showInformationalAlert(message, info: info)
            return nil
        }
        return year
    }

    func showInformationalAlert(message: String, info: String) {
        let alert = NSAlert()
        alert.addButtonWithTitle("OK")
        alert.messageText = message
        alert.informativeText = info
        alert.alertStyle = .InformationalAlertStyle
        alert.beginSheetModalForWindow(view.window!, completionHandler: nil)
    }

    @IBAction func enterPressed(sender : AnyObject) {
        // Swift.print("'Enter'sent from: \(sender)")
        if let year = getYearNumber() {
            yearNumber = year
            if (moonPhaseArray.count > 0) {
                moonPhaseArray.removeAll(keepCapacity: false)
            }
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss +0000"
            let yearBegin = String(format: "%ld-01-01 00:00:00 +0000", yearNumber)
            let startTime = formatter.dateFromString(yearBegin)!
            let yearEnd = String(format: "%ld-12-31 23:59:59 +0000", yearNumber)
            let endTime = formatter.dateFromString(yearEnd)!
            var eventDate = NSDate()
            // julian day (number of days since 1. Januar 4713 bc)
            // 2440587.5 julian day for january 1, 1970
            // 2451910.5 julian day for january 1, 2001 is taken
            let julianDay: Double = 2451910.5 + startTime.timeIntervalSinceReferenceDate / 86400.0
            formatter.dateStyle = NSDateFormatterStyle.FullStyle
            formatter.timeStyle = NSDateFormatterStyle.LongStyle
            formatter.timeZone = NSTimeZone(abbreviation: NSLocalizedString("GMT", comment: "time zone for locale"))
            // calculate time of lunations from 0...13 and Phases of 0...3
            for l in 0 ..< 14 {
                for p in 0 ..< 4 {
                    let nextPhase = MoonPhase(luna: l, ph: p)
                    nextPhase.eventBeginPastJulianDay(julianDay)
                    eventDate = nextPhase.eventBegin
                    if (eventDate.timeIntervalSinceDate(startTime) > 0 && eventDate.timeIntervalSinceDate(endTime) < 0) {
                        nextPhase.localizedEventBegin = formatter.stringFromDate(eventDate)
                        addMoonphase(nextPhase)
                    }
                }
            }
            // update table view in one go
            moonphaseTableView.reloadData()
            let message = NSLocalizedString("Status Message", comment: "informal message")
            let format = NSLocalizedString("calculated %d moon phases for the year %d.", comment: "final information")
            let info = String(format: format, moonPhaseArray.count, year)
            showInformationalAlert(message, info: info)
        }
    }

    @IBAction func saveDocument(sender : AnyObject) {
        // Swift.print("'Save...'sent from: \(sender)")
        if let year = getYearNumber() {
            if (moonPhaseArray.isEmpty || (year != yearNumber)) {
                let message = NSLocalizedString("Input Error", comment: "general error")
                let info = String(format: NSLocalizedString("moon phases in year %d not calculated yet", comment: "report the kind of the error"), year)
                showInformationalAlert(message, info: info)
            }
            else {
                yearNumber = year
                // generate File Save Dialog class
                let saveDlg:NSSavePanel = NSSavePanel()
                saveDlg.title = NSLocalizedString("Save moon phases in calendar file", comment: "title of savePanel")
                let holidayFile = String(format: "%@-%ld.ics", NSLocalizedString("Moonphases", comment: "name of file to save"), yearNumber)
                saveDlg.nameFieldStringValue = holidayFile
                // set user's directory
                let userDirectoryPath: NSString = "~"
                saveDlg.directoryURL = NSURL.fileURLWithPath(userDirectoryPath.stringByExpandingTildeInPath)
                if (saveDlg.runModal() == NSFileHandlingPanelOKButton) {
                    var outputString = String()
                    do {
                        try outputString.writeToURL(saveDlg.URL!, atomically:true, encoding:NSUTF8StringEncoding)
                        
                        // File can be written
                        Swift.print("URL: \(saveDlg.URL)")
                        do {
                            let output = try NSFileHandle(forWritingToURL: saveDlg.URL!)
                            outputString += "BEGIN:VCALENDAR\n"
                            outputString += "METHOD:PUBLISH\n"
                            outputString += "VERSION:2.0\n"
                            outputString += NSLocalizedString("X-WR-CALNAME:Moon phases\n", comment: "name for calendar")
                            outputString += "PRODID:-//Apple Inc.//iCal 5.0.0//DE\n"
                            // outputString in NSData-Object umwandeln und nach output schreiben
                            output.writeData(outputString.dataUsingEncoding(NSUTF8StringEncoding)!)
                            outputString = ""
                            // formatter shows date and time in a special form
                            formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
                            // generate timestamp
                            let timeStamp = formatter.stringFromDate(NSDate())
                            var i = 0
                            for moonphaseItem : MoonPhase in moonPhaseArray {
                                // output loop for moon phases in year
                                outputString += "BEGIN:VEVENT\n"
                                outputString += "CREATED: \(timeStamp)\n"
                                // add-on "-kuester-" can be changed at will
                                outputString += "UID:\(timeStamp)@kuester-\(i)\n"
                                outputString += "SUMMARY: \(moonphaseItem.eventName)\n"
                                outputString += "DESCRIPTION:Moon phases\n"
                                outputString += "X-MOZILLA-ALARM-DEFAULT-LENGTH:0\n"
                                outputString += "X-MOZILLA-RECUR-DEFAULT-UNITS:0\n"
                                outputString += "RRULE:0\n"
                                outputString += "TRANSP:TRANSPARENT\n"
                                outputString += "DTSTART;VALUE=DATE:\(formatter.stringFromDate(moonphaseItem.eventBegin))\n"
                                outputString += "DTEND;VALUE=DATE:\(formatter.stringFromDate(moonphaseItem.eventBegin))\n"
                                outputString += "DTSTAMP:\(timeStamp)\n"
                                outputString += "LAST-MODIFIED:\(timeStamp)\n"
                                outputString += "END:VEVENT\n"
                                output.writeData(outputString.dataUsingEncoding(NSUTF8StringEncoding)!)
                                outputString = ""
                                i += 1
                            }
                            outputString += "END:VCALENDAR\n"
                            output.writeData(outputString.dataUsingEncoding(NSUTF8StringEncoding)!)
                            output.closeFile()
                            let message = NSLocalizedString("Status Message", comment: "informal message")
                            let info = String(format: NSLocalizedString("Moon phases stored for year: %d", comment: "message after save panel"), yearNumber)
                            showInformationalAlert(message, info: info)
                        } catch let writeHandleError as NSError {
                            Swift.print("writing to handle failed: \(writeHandleError.localizedDescription)")
                        }
                    } catch let writeURLError as NSError {
                        let message = NSLocalizedString("error during saving", comment: "general error")
                        let info = String(format: "%@ %@", NSLocalizedString("Writing to the file with selected URL failed: ", comment: "report the kind of the error"), saveDlg.URL!)
                        showInformationalAlert(message, info: info)
                        Swift.print("writing to URL failed: \(writeURLError.localizedDescription)")
                    }
                }
                else {
                    let message = NSLocalizedString("Status Message", comment: "informal message")
                    let info = NSLocalizedString("Cancel Button pressed, nothing to do", comment: "cancel pressed")
                    showInformationalAlert(message, info: info)
                }
            }
        }
    }
}

