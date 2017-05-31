//
//  ViewController.swift
//  STAAR_DocParser_2016
//
//  Created by niloofar zarei on 7/7/16.
//  Copyright © 2016 Niloofar Zarei. All rights reserved.
//

import Cocoa
import AppKit
import CoreAudio
import AVFoundation

class ViewController: NSViewController {
    
    //--------------------------------------------------------------------------------------------------------------
    //MARK: - Variables
    //--------------------------------------------------------------------------------------------------------------
    let mySynth: NSSpeechSynthesizer = NSSpeechSynthesizer(voice: NSSpeechSynthesizer.defaultVoice())!
    let dirs : [String] = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true) as [String])
    var documentURL: URL?
    public var newWordsArray: [String] = []

    
    //--------------------------------------------------------------------------------------------------------------
    //MARK: - Interface
    //--------------------------------------------------------------------------------------------------------------
    @IBOutlet weak var inputField: NSTextField!
    @IBAction func generateDBPressed(_ sender: AnyObject) {
        if (!inputField.stringValue.isEmpty) {
            processDocument(documentURL!, documentName: inputField.stringValue)
        }

    }

    @IBAction func browsePressed(_ sender: AnyObject) {
        //Create the File Open Dialog class.
        debugPrint("browse pressed")
        let openDialog = NSOpenPanel()
        
        //Array of acceptable filetypes
        let fileTypesArray: [String] = ["pdf"] //Only allow selection of supported filetypes
        
        //Change Open Dialog options
        openDialog.canChooseFiles = true //Choose Files
        openDialog.allowedFileTypes = fileTypesArray //Choose only files of types in fileTypesArray
        openDialog.allowsMultipleSelection = false //Only choose one file at a time
        
        // Display the dialog.
        if (openDialog.runModal() == NSModalResponseOK) {
            documentURL = openDialog.url! //Get the selected document URL
            var documentName = openDialog.url!.lastPathComponent //Get the selected document
            documentName = documentName[0...documentName.characters.count-5] //Remove the file extension (3 char extensions ONLY)
            inputField.stringValue = documentName //Set the input field to the filename
        }
    }
    
    func getWordsArray(array: [String]){
        self.newWordsArray = array
    }
    
    //--------------------------------------------------------------------------------------------------------------
    //MARK: - Functions
    //--------------------------------------------------------------------------------------------------------------
    // This is the function called when "Generate DB" button is pressed.
    func processDocument(_ documentURL: URL, documentName: String) {
        
        let alert = NSAlert()
        alert.messageText = "Please Wait..."
        alert.addButton(withTitle: "")
        alert.informativeText = "Your document is being processed."
        alert.beginSheetModal(for: NSApplication.shared().mainWindow!, completionHandler: nil)
        
        
        //Get the default file manager
        let fileManager = FileManager.default
        
        
        //Set up the file Handler
        let fileHandle = FileHandle(forReadingAtPath: documentURL.path)
        
        //Get the documents directory
        let documentsDir = dirs[0]
        print(documentsDir)
        
        
        //Create some new folders
        let parentDir = "/Users/NiloofarZarei/Desktop/" + "\(documentName)_STAAR_3/" //The parent directory should be named after the parsed document
        
        if (fileManager.fileExists(atPath: parentDir)) { //If the parent directory already exists, delete the existing one.
            do {
                try fileManager.removeItem(atPath: parentDir)
            } catch let error as NSError {
                print("Failed to delete dir: \(error.localizedDescription)")
            }
        }
        
        do {
            try fileManager.createDirectory(atPath: parentDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError { //Create the directory
            print("Failed to create dir: \(error.localizedDescription)") //Catch an error of the directory is not created properly
        }
        
        //Create directories for the audio files.
//        let slowDir = parentDir + "AudioSlow/" //The audio files should be stored in a folder for grouping
//        do {
//            try fileManager.createDirectory(atPath: slowDir, withIntermediateDirectories: true, attributes: nil)
//        } catch let error as NSError {
//            print("Failed to create dir: \(error.localizedDescription)") //Catch an error of the directory is not created properly
//        }
        let normalDir = parentDir + "AudioNormal/" //The audio files should be stored in a folder for grouping
        do {
            try fileManager.createDirectory(atPath: normalDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Failed to create dir: \(error.localizedDescription)") //Catch an error of the directory is not created properly
        }
//        let fastDir = parentDir + "AudioFast/" //The audio files should be stored in a folder for grouping
//        do {
//            try fileManager.createDirectory(atPath: fastDir, withIntermediateDirectories: true, attributes: nil)
//        } catch let error as NSError {
//            print("Failed to create dir: \(error.localizedDescription)") //Catch an error of the directory is not created properly
//        }
        
    
        //Create the SQLite database file
        let dbPath = parentDir + "\(documentName)_STAAR.db" //Set the path to the file location
        
        if (fileManager.fileExists(atPath: dbPath)) { //If the database exists, delete the existing database.
            do {
                try fileManager.removeItem(atPath: dbPath)
            } catch _ as NSError {
                //Handle Error -  this should alert the user to select another file
            }
        }
        
        let readerDB = FMDatabase(path: dbPath)
        
        if (readerDB?.open())! { //Open and configure database tables.
            /*
             Create a table called DICTIONARY with fields as follows:
             ID, Integer, Primary key, automatically increments.
             WORD, String, holds a single word.
             POSX, Real, holds the X location on the screen of the beginning of a word.
             POSY, Real, holds the Y location on the screen of the beginning of a word.
             LENGTH, Real, holds the length  of the WORD.
             LINE, Integer, holds the line number which the WORD belongs to.
             PAGE, Integer, holds the page number which the WORD belongs to.
             AUDIOSLOW, String, holds the relative URL of the audio file corresponding to WORD which is the slow rendering.
             AUDIONORMAL, String, holds the relative URL of the audio file corresponding to WORD which is the normal rendering.
             AUDIOFAST, String, holds the relative URL of the audio file corresponding to WORD which is the fast rendering.
             TO ADD: length of each audio file
             */
            let sql_stmt = "CREATE TABLE IF NOT EXISTS DICTIONARY (ID INTEGER PRIMARY KEY AUTOINCREMENT, WORD TEXT, POSWX REAL, POSLY REAL, LENGTH REAL, LINE INTEGER, PAGE INTEGER, AUDIOSLOW TEXT, AUDIONORMAL TEXT, AUDIOFAST TEXT)"
            
            readerDB?.executeStatements(sql_stmt) // Pass in the SQL statement.
            
            let doc = STAAR_PDFDocClass(thisPath: documentURL)
            doc.writeDataToFile(ParentDir: parentDir, documentName: "\(documentName)")
            
            //var insertSQL = "temp"
            var wordNum = 1
            //var result = true
            
            let seconds = 0.25 // An Quarter of a Second delay
            let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
            let dispatchTime = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC) //For Audio Generation
            
            //Add delay between words, then split with SOX.
            let silence = "[[slnc 1000]]" //TTS will wait 1000 ms (1s) before speaking the next word w/o sacrificing coarticulation.
            
            var audioPath = parentDir + "test.aiff"
            var audioURL: URL = URL(fileURLWithPath: audioPath)
            mySynth.startSpeaking("A \(silence) humongous \(silence) elephant, Joe, ate a red apple happily.", to: audioURL)
            
            audioPath = normalDir + "449.aiff"
            audioURL = URL(fileURLWithPath: audioPath)
            debugPrint(audioPath)
            debugPrint(audioURL)
            mySynth.rate = 220.0
            let aWord = "yards"
            mySynth.startSpeaking(aWord, to: audioURL)
            debugPrint(doc.NewWordsArray[8])
            
            //var wordcounter = 0
            for page in doc.PDFPages {
                for line in page.pageLines {
                    for word in line.lineWords {
                            audioPath = normalDir + "\(wordNum).aiff"
                            audioURL = URL(fileURLWithPath: audioPath)
                            self.mySynth.rate = 220.0
                            var bool = self.mySynth.startSpeaking(word.wordString, to: audioURL)
                            if word.wordString != "" {
                            wordNum += 1
                            }
                }
                }
            }
            
            audioPath = normalDir + "446.aiff"
            audioURL = URL(fileURLWithPath: audioPath)
            self.mySynth.rate = 220.0
            self.mySynth.startSpeaking("fifty", to: audioURL)
            
            audioPath = normalDir + "447.aiff"
            audioURL = URL(fileURLWithPath: audioPath)
            self.mySynth.rate = 220.0
            self.mySynth.startSpeaking("or", to: audioURL)
            
            audioPath = normalDir + "448.aiff"
            audioURL = URL(fileURLWithPath: audioPath)
            self.mySynth.rate = 220.0
            self.mySynth.startSpeaking("sixty", to: audioURL)


            
            //debugPrint("number of words is \(wordcounter)")
//            for word in doc.NewWordsArray {
//                audioPath = normalDir + "\(wordNum).aiff"
//                audioURL = URL(fileURLWithPath: audioPath)
//                self.mySynth.rate = 220.0
//                debugPrint(doc.NewWordsArray[wordNum-1])
//                var bool = self.mySynth.startSpeaking(word, to: audioURL)
//                if !bool {
//                debugPrint(wordNum)
//                debugPrint(doc.NewWordsArray[wordNum-1])
//                }
//            wordNum += 1
//            }
            
        readerDB?.close() //Finished with the database.
        }
        NSApplication.shared().mainWindow?.endSheet(alert.window)
}
}



//--------------------------------------------------------------------------------------------------------------
//MARK: - Extensions
//--------------------------------------------------------------------------------------------------------------
extension String {
    
    subscript (r: CountableClosedRange<Int>) -> String {
        get {
            let startIndex =  self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(startIndex, offsetBy: r.upperBound - r.lowerBound)
            return self[startIndex...endIndex]
        }
    }
    
    subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        return substring(with: Range(characters.index(startIndex, offsetBy: r.lowerBound)..<characters.index(startIndex, offsetBy: r.upperBound)))
}

    func removingCharacters(forbiddenCharacters:CharacterSet) -> String
    {
        var filteredString = self
        while true {
            if let forbiddenCharRange = filteredString.rangeOfCharacter(from: forbiddenCharacters)  {
                filteredString.removeSubrange(forbiddenCharRange)
            }
            else {
                break
            }
        }
        
        return filteredString
    }
    
    var asciiArray: [UInt32] {
        return unicodeScalars.filter{$0.isASCII}.map{$0.value}
    }

}

extension Character {
    var asciiValue: UInt32? {
        return String(self).unicodeScalars.filter{$0.isASCII}.first?.value
    }
}
