//
//  ViewController.swift
//  STAAR_DocParser_2016
//
//  Created by niloofar zarei on 7/7/16.
//  Copyright © 2016 Niloofar Zarei. All rights reserved.
//

import Cocoa
import AppKit

class ViewController: NSViewController {
    
    //--------------------------------------------------------------------------------------------------------------
    //MARK: - Variables
    //--------------------------------------------------------------------------------------------------------------
    let mySynth: NSSpeechSynthesizer = NSSpeechSynthesizer(voice: NSSpeechSynthesizer.defaultVoice())!
    let dirs : [String] = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.AllDomainsMask, true) as [String])
    var documentURL: NSURL?
    var PDFAnalyzer: STAAR_PDFAnalyzerClass!

    
    //--------------------------------------------------------------------------------------------------------------
    //MARK: - Interface
    //--------------------------------------------------------------------------------------------------------------
    @IBOutlet weak var inputField: NSTextField!
    @IBAction func generateDBPressed(sender: AnyObject) {
        if (!inputField.stringValue.isEmpty) {
            processDocument(documentURL!, documentName: inputField.stringValue)
        }

    }

    @IBAction func browsePressed(sender: AnyObject) {
        //Create the File Open Dialog class.
        let openDialog = NSOpenPanel()
        
        //Array of acceptable filetypes
        let fileTypesArray: [String] = ["pdf"] //Only allow selection of supported filetypes
        
        //Change Open Dialog options
        openDialog.canChooseFiles = true //Choose Files
        openDialog.allowedFileTypes = fileTypesArray //Choose only files of types in fileTypesArray
        openDialog.allowsMultipleSelection = false //Only choose one file at a time
        
        // Display the dialog.
        if (openDialog.runModal() == NSModalResponseOK) {
            documentURL = openDialog.URL! //Get the selected document URL
            let urlString: String = documentURL!.absoluteString //convert NSURL to string
            let modifiedURL = CFURLCreateWithFileSystemPath(kCFAllocatorSystemDefault, urlString, CFURLPathStyle.CFURLPOSIXPathStyle, false) //convert string to CFURL
            PDFAnalyzer.createDoc(modifiedURL)
            

            var documentName = openDialog.URL!.lastPathComponent! //Get the selected document
            documentName = documentName[0...documentName.characters.count-5] //Remove the file extension (3 char extensions ONLY)
            inputField.stringValue = documentName //Set the input field to the filename
        }
    }
    
    //--------------------------------------------------------------------------------------------------------------
    //MARK: - Functions
    //--------------------------------------------------------------------------------------------------------------
    func processDocument(let documentURL: NSURL, let documentName: String) {
        //Get the default file manager
        let fileManager = NSFileManager.defaultManager()
        
        
        //Set up the file Handler
        let fileHandle = NSFileHandle(forReadingAtPath: documentURL.path!)
        
        //Get the documents directory
        let documentsDir = dirs[0]
        
        
        //Create some new folders
        let parentDir = documentsDir.stringByAppendingString("/\(documentName)_STAAR/") //The parent directory should be named after the parsed document
        
        if (fileManager.fileExistsAtPath(parentDir)) { //If the parent directory already exists, delete the existing one.
            do {
                try fileManager.removeItemAtPath(parentDir)
            } catch let error as NSError {
                print("Failed to delete dir: \(error.localizedDescription)")
            }
        }
        
        do {
            try fileManager.createDirectoryAtPath(parentDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError { //Create the directory
            print("Failed to create dir: \(error.localizedDescription)") //Catch an error of the directory is not created properly
        }
        
        //Create directories for the audio files.
        let slowestDir = parentDir.stringByAppendingString("AudioSlowest/") //The audio files should be stored in a folder for grouping
        do {
            try fileManager.createDirectoryAtPath(slowestDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Failed to create dir: \(error.localizedDescription)") //Catch an error of the directory is not created properly
        }
        let slowDir = parentDir.stringByAppendingString("AudioSlow/") //The audio files should be stored in a folder for grouping
        do {
            try fileManager.createDirectoryAtPath(slowDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Failed to create dir: \(error.localizedDescription)") //Catch an error of the directory is not created properly
        }
        let fastDir = parentDir.stringByAppendingString("AudioFast/") //The audio files should be stored in a folder for grouping
        do {
            try fileManager.createDirectoryAtPath(fastDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Failed to create dir: \(error.localizedDescription)") //Catch an error of the directory is not created properly
        }
        let fastestDir = parentDir.stringByAppendingString("AudioFastest/") //The audio files should be stored in a folder for grouping
        do {
            try fileManager.createDirectoryAtPath(fastestDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Failed to create dir: \(error.localizedDescription)") //Catch an error of the directory is not created properly
        }

    
        //Create the SQLite database file
        let dbPath = parentDir.stringByAppendingString("\(documentName)_STAAR.db") //Set the path to the file location
        
        if (fileManager.fileExistsAtPath(dbPath)) { //If the database exists, delete the existing database.
            do {
                try fileManager.removeItemAtPath(dbPath)
            } catch _ as NSError {
                //Handle Error
            }
        }
        
        let readerDB = FMDatabase(path: dbPath)
        
        if (readerDB.open()) { //Open and configure database tables.
            /*
             Create a table called DICTIONARY with fields as follows:
             ID, Integer, Primary key, automatically increments.
             WORD, String, holds a single word.
             POSX, Real, holds the X location on the screen of the beginning of a word.
             POSY, Real, holds the Y location on the screen of the beginning of a word.
             LENGTH, Real, holds the length  of the WORD.
             LINE, Integer, holds the line number which the WORD belongs to.
             PAGE, Integer, holds the page number which the WORD belongs to.
             AUDIOSLOWEST, String, holds the relative URL of the audio file corresponding to WORD which is the slowest rendering.
             AUDIOSLOW, String, holds the relative URL of the audio file corresponding to WORD which is the slow rendering.
             AUDIOFAST, String, holds the relative URL of the audio file corresponding to WORD which is the fast rendering.
             AUDIOFASTEST, String, holds the relative URL of the audio file corresponding to WORD which is the fastest rendering.
             TO ADD: length of each audio file
             */
            let sql_stmt = "CREATE TABLE IF NOT EXISTS DICTIONARY (ID INTEGER PRIMARY KEY AUTOINCREMENT, WORD TEXT, POSX REAL, POSY REAL, LENGTH REAL, LINE INTEGER, PAGE INTEGER, AUDIOSLOWEST TEXT, AUDIOSLOW TEXT, AUDIOFAST TEXT, AUDIOFASTEST TEXT)"
            
            readerDB.executeStatements(sql_stmt) // Pass in the SQL statement.

        }
    }
}


//--------------------------------------------------------------------------------------------------------------
//MARK: - Extensions
//--------------------------------------------------------------------------------------------------------------
extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(startIndex.advancedBy(r.startIndex)..<startIndex.advancedBy(r.endIndex)))
}

}


