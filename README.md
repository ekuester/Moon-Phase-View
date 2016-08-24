# Moon-Phase-View
Moon phase calendar with creating of ICS files

See all moon phases of a given year and put the dates into your personal calendar

The program was written in Swift version 2.2 for Mac OS X.

The development environment in the moment is Xcode 7.3.1 under OS X 10.11 El Capitan. The storyboard method ( main.storyboard ) is used for coupling AppDelegate, WindowsController and ViewController together. You will find some useful methods to exchange data between these three objects. I wrote this program to become familiar with the Swift language and to get a feeling how to display table views on the screen. It contains a lot of useful stuff regarding handling of windows, menus, calendars and dates in table views.

Usage: You will find the program mostly self explaining. On input of a year number between 1600 and 2399 the phases of moon are calculated. By clicking on "Save..." you have the possibilty to save the dates for the phases in a calendar file with the extension .ics, which will accepted by calendar programs on PC or mobile phones. Thereby you are able to view the phases of the moon on your personal calendar and know exactly, when you will be moonstruck ...

Very useful algorithms for calculating are found in the excellent book "Astronomische Algorithmen" by Jean Meeus, Johann Ambrosius Barth 1992, ISBN-13 978-3335003182. Unfortunately the book is not any longer available.

Every lunar cycle ( called lunation ) consists of four phases

- new moon, no moon visible
- crescent moon, half of the moon is visible, the sickle is on the right side smooth )
- full moon, all of the moon is visible ( )
- waning moon, half of the moon is visible, the sickle is on the left side smooth (

In most cases the dates for the lunar events are accurate to roundabout some seconds.

German localization is added.

Disclaimer: Use the program for what purpose you like, but hold in mind, that I will not be responsible for any harm it will cause to your hard- or software. It was your decision to use this piece of software.
