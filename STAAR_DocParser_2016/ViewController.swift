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
    var durationsArray: [String] = []
    var addrArray: [String] = []
    let deviceModels = ["12.9 inch iPad Pro", "9.7 inch iPad"]

    
    //--------------------------------------------------------------------------------------------------------------
    //MARK: - Interface
    //--------------------------------------------------------------------------------------------------------------
    @IBOutlet weak var inputField: NSTextField!
    @IBAction func generateDBPressed(_ sender: AnyObject) {
        if (!inputField.stringValue.isEmpty) {
            processDocument(documentURL!, documentName: inputField.stringValue, deviceModel: deviceModelSelector.indexOfSelectedItem)
        }

    }

    @IBAction func browsePressed(_ sender: AnyObject) {
        debugPrint(NSSpeechSynthesizer.availableVoices())
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
    
    
    @IBOutlet weak var deviceModelSelector: NSPopUpButton!
    
    
    //--------------------------------------------------------------------------------------------------------------
    //MARK: - Functions
    //--------------------------------------------------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        deviceModelSelector.removeAllItems()
        deviceModelSelector.addItems(withTitles: deviceModels)
        deviceModelSelector.selectItem(at: 0)
        deviceModelSelector.autoenablesItems = false
    }
    
    // This is the function called when "Generate DB" button is pressed.
    func processDocument(_ documentURL: URL, documentName: String, deviceModel: Int) {
        
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
        
        var devSize = "12.9"
        if deviceModel == 1 {devSize = "9.7"}
        
        
        //Create some new folders
        let parentDir = "/Users/NiloofarZarei/Desktop/" + "\(documentName)_STAARFormat/" //The parent directory should be named after the parsed document
//let parentDir2 = "/Users/NiloofarZarei/Desktop/"
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
        
  
        let normalDir = parentDir + "AudioFiles/" //The audio files should be stored in a folder for grouping
        do {
            try fileManager.createDirectory(atPath: normalDir, withIntermediateDirectories: true, attributes: nil)
        } catch let error as NSError {
            print("Failed to create dir: \(error.localizedDescription)") //Catch an error of the directory is not created properly
        }

        let doc = STAAR_PDFDocClass(thisPath: documentURL, size: devSize)
            //doc.writeDataToFile(ParentDir: parentDir, documentName: "\(documentName)", durationArray: self.durationsArray, addrArray: self.addrArray)
            
            //var insertSQL = "temp"
            var wordNum = 1
            var pageNum = 1
            //var result = true
            
            let seconds = 0.25 // An Quarter of a Second delay
            let delay = seconds * Double(NSEC_PER_SEC)  // nanoseconds per seconds
            let dispatchTime = DispatchTime.now() + Double(Int64(delay)) / Double(NSEC_PER_SEC) //For Audio Generation
            
            //Add delay between words, then split with SOX.
            let silence = "[[slnc 1000]]" //TTS will wait 1000 ms (1s) before speaking the next word w/o sacrificing coarticulation.
            var audioPath = parentDir + "test.aiff"
            var audioURL: URL = URL(fileURLWithPath: audioPath)
            //var textTest = "A \(silence) humongous \(silence) elephant, Joe, ate a red apple happily."
            //var textTest = "A \(silence) humongous \(silence) elephant,\(silence) Joe,\(silence)ate \(silence) a \(silence) red \(silence) apple \(silence) happily."
        var textTest = "Now,\(silence)cancel!"
            mySynth.startSpeaking(textTest, to: audioURL)

            for page in doc.PDFPages {
                for line in page.pageLines {
                    for word in line.lineWords {
                            audioPath = normalDir + "\(pageNum)_" + modifyDigits(num: wordNum) + "\(wordNum).aiff"
                            self.addrArray.append("\(pageNum)_" + modifyDigits(num: wordNum) + "\(wordNum)")
                            audioURL = URL(fileURLWithPath: audioPath)
                            self.mySynth.rate = 220.0
                            var bool = self.mySynth.startSpeaking(word.wordString.lowercased(), to: audioURL)
                        debugPrint("word \(wordNum) spoken")
                        if word.wordString != "" {
                            wordNum += 1
                            }
                }
                }
                wordNum = 1
                pageNum += 1
            }
        

        self.durationsArray = self.runShell("/Users/NiloofarZarei/Desktop/getDurations.sh", normalDir)
        doc.writeDataToFile(ParentDir: parentDir, documentName: "\(documentName)", durationArray: self.durationsArray, addrArray: self.addrArray)
        NSApplication.shared().mainWindow?.endSheet(alert.window)
}
    
    func runShell(_ args: String, _ audioDir: String) -> [String]{
        var output : [String] = []
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = [args,"-a", audioDir]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        //let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String(data: data, encoding: .utf8) {
            string = string.trimmingCharacters(in: .newlines)
            output = string.components(separatedBy: "\n")
        }
        task.waitUntilExit()
        //debugPrint(output)
        return output
    }
    
    func modifyDigits(num: Int) -> String{
        var digits = 0
        var num = num
        while num > 0 {
            digits += 1
            num = num / 10
        }
        switch digits {
        case 1:
            return "000\(num)"
        case 2:
            return "00\(num)"
        case 3:
            return "0\(num)"
        default:
            return "\(num)"
        }
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
