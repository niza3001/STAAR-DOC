//
//  PDFAnalyzerClass.swift
//  STAAR_DocParser_2016
//
//  Created by niloofar zarei on 7/15/16.
//  Copyright © 2016 Niloofar Zarei. All rights reserved.
//

import Foundation
import CoreGraphics
import QuartzCore

//MARK: Structures
//____________________________________________________________________________________

struct Segment{
    var startPoint = CGPoint()
    var endPoint = CGPoint()
    
    init(startpoint: CGPoint, endpoint: CGPoint){
        self.startPoint = startpoint
        self.endPoint = endpoint
    }
}

struct pageWordsDetails {
    var mySelections: NSArray
    var pageTextString: String
    var words: [String]
    var wordBBoxArray: [CGRect] = []
    var wordSegment: [Segment] = []
    
    init(){
        mySelections = []
        pageTextString = ""
        words = []
    }
}

//MARK: Classes
//____________________________________________________________________________________

class STAAR_Wordclass {
    
    //MARK: Properties
    //____________________________________________
    
    var wordBBox: CGRect!
    var wordString: String!
    var wordSegment: Segment!
    
    
    //MARK: Initialization
    //____________________________________________
    
    init(str: String, bbox: CGRect, startpoint: CGPoint, endpoint: CGPoint) {
        self.wordString = str
        self.wordBBox = bbox
        self.wordSegment = Segment.init(startpoint: startpoint, endpoint: endpoint)
    }
    
    //MARK: Functions
    //____________________________________________
    
    func doesMatch(inputString: String) -> Bool {
        
        if (self.wordString == inputString){
            return true
        }
        else{
            return false
        }
    }
}

class STAAR_Lineclass{
    
    //MARK: Properties
    //____________________________________________
    var lineNum: Int = 1
    var lineYvalue: CGFloat = 0
    var lineWords: [STAAR_Wordclass] = []
}

class STAAR_PDFPageClass {
    
    //MARK: Properties
    //____________________________________________
    var myPage: CGPDFPage!
    var pageNum: Int
    let myScanner: Scanner2
    var myPageWordsDetails: pageWordsDetails = pageWordsDetails.init()
    var pageLines: [STAAR_Lineclass] = []
    
    //MARK: Initialization
    //____________________________________________
    
    init(aPDFDoc: CGPDFDocument!,aPageNum: Int){
        self.myPage = aPDFDoc.page(at: aPageNum)
        self.pageNum = aPageNum
        self.myScanner = Scanner2(page: self.myPage)
    }
    
    
    //MARK: Functions
    //____________________________________________
    
    func setPageWordsDetails(devSize: String){
        myPageWordsDetails.mySelections = myScanner.select(" ") as NSArray
        let pageTextString = myScanner.getPageText()!
        debugPrint("***** \(pageTextString)")
        //let pageTextString = pageTextStringRaw.replace(target: "'", withString:"''")
        myPageWordsDetails.words = pageTextString.components(separatedBy: " ")
        myPageWordsDetails.words = myPageWordsDetails.words.filter {$0.isEmpty==false}
        var transformedRects: [CGRect] = []
        
        for object in myPageWordsDetails.mySelections{
            let rect: CGRect = (object as AnyObject).frame.applying((object as AnyObject).transform)
            let deviceModel = devSize
            
            var x = rect.origin.x
            var y = rect.origin.y
            var w = rect.width
            var h = rect.height
            
            if devSize == "9.7" {
//            For 9.7 inch iPad
                x = rect.origin.x*(1.176 as CGFloat) + 1.041
                y = rect.origin.y*(-1.174 as CGFloat) + 942.7
                w = rect.width * 1.176
                h = rect.height * 1.174
            }
            
            if devSize == "12.9" {
//          For 12.9 inch iPad
                x = rect.origin.x*(1.593  as CGFloat) + 0.133
                y = rect.origin.y*(-1.594 as CGFloat) + 1288
                w = rect.width * 1.593
                h = rect.height * 1.594
            }
 
            
            let transformedRect = CGRect(x: x,y: y,width: w,height: h)
            transformedRects.append(transformedRect)
        }
        

        for var word in myPageWordsDetails.words{
            let counter = word.characters.count
            if counter == 0 {continue}
            var wordCharsRect: [CGRect] = []
            var aRect : CGRect
            for _ in 1...counter{
                if !(transformedRects.isEmpty){
                    aRect = transformedRects.removeFirst()
                    wordCharsRect.append(aRect)
                }
            }
            
            if (wordCharsRect.count == counter){
                var tempRect = wordCharsRect.removeFirst()
                if counter == 1 {
                    myPageWordsDetails.wordBBoxArray.append(tempRect)
                    continue
                }
                for _ in 1...(counter-1){
                    let tempRect2 = wordCharsRect.removeFirst()
                    tempRect = tempRect.union(tempRect2)
                }
                myPageWordsDetails.wordBBoxArray.append(tempRect)
            }
        }

    }
}



class STAAR_PDFDocClass {
    
    //MARK: Properties
    //____________________________________________
    let PDFdoc: CGPDFDocument!
    var PDFPages: [STAAR_PDFPageClass] = []
    var PDFPath: URL
    var NewWordsArray: [String] = []
    
    
    //MARK: Initialization
    //____________________________________________
    init(thisPath:URL, size: String){
        self.PDFPath = thisPath
        self.PDFdoc = CGPDFDocument(thisPath as CFURL)
        let pageCount = self.PDFdoc.numberOfPages
        for pageNum in 1...pageCount{
            let page = STAAR_PDFPageClass(aPDFDoc: self.PDFdoc,aPageNum: pageNum)
            page.setPageWordsDetails(devSize: size)
            var line = STAAR_Lineclass()
            line.lineYvalue = page.myPageWordsDetails.wordBBoxArray[0].origin.y + page.myPageWordsDetails.wordBBoxArray[0].height/2
            var counter = 0
            debugPrint(page.myPageWordsDetails.wordBBoxArray.count)
            
            for wordBBox in page.myPageWordsDetails.wordBBoxArray{
//                debugPrint("@@ before change0 \(line.lineYvalue)")
                debugPrint("@@ value given \(line.lineYvalue - wordBBox.origin.y - wordBBox.height/2)")
                if (truncf(Float(line.lineYvalue)) != truncf(Float(wordBBox.origin.y + wordBBox.height/2))) {
//                    debugPrint("@@ before change \(line.lineYvalue)")
//                    debugPrint("@@ before change1 \(wordBBox.origin.y + wordBBox.height/2)")
                    //let str = page.myPageWordsDetails.words[counter]
                    //print(str)
                    page.pageLines.append(line)
                    let nextLine = line.lineNum
                    line = STAAR_Lineclass()
                    line.lineNum = nextLine
                    //let str = page.myPageWordsDetails.words[counter]
                    line.lineYvalue = wordBBox.origin.y + wordBBox.height/2
//                    debugPrint("@@ after change \(line.lineYvalue)")
                    debugPrint("@@ line changed")
                }
                
                let str = page.myPageWordsDetails.words[counter]
                let start = CGPoint(x: wordBBox.origin.x, y: line.lineYvalue)
                let end = CGPoint(x: wordBBox.origin.x+wordBBox.width, y: line.lineYvalue)
                let word = STAAR_Wordclass(str: str, bbox: wordBBox,startpoint: start,endpoint: end)
                line.lineWords.append(word)
                debugPrint("@@ this word was lined \(word.wordString.debugDescription)and counter is \(counter)")
                
//                else {
//                    page.pageLines.append(line)
//                    let nextLine = line.lineNum
//                    line = STAAR_Lineclass()
//                    line.lineNum = nextLine
//                    //let str = page.myPageWordsDetails.words[counter]
//                    line.lineYvalue = wordBBox.origin.y + wordBBox.height/2
//                    let start = CGPoint(x: wordBBox.origin.x, y: line.lineYvalue)
//                    let end = CGPoint(x: wordBBox.origin.x+wordBBox.width, y: line.lineYvalue)
//                    let word = STAAR_Wordclass(str: str, bbox: wordBBox,startpoint: start,endpoint: end)
//                    line.lineWords.append(word)
//                    debugPrint("@BOL this word was lined \(word.wordString.debugDescription) and counter is \(counter)")
//                }
                
                if counter==page.myPageWordsDetails.words.count-1 {page.pageLines.append(line)
                    debugPrint(line.lineWords.last?.wordString as Any)
                    
                }
                counter += 1
                
                //debugPrint("counter is \(counter)")
            }//}
            self.PDFPages.append(page)
            
            }
        }
        
    //}
    
        func writeDataToFile(ParentDir:String, documentName: String, durationArray: [String], addrArray: [String]) {
        var CSVText = "id,WORD,POSWX,POSLY,LENGTH,LINE,PAGE,DURATION,AUDIOFILE\n"//,AUDIOSLOW,AUDIONORMAL,AUDIOFAST\n"
        let mainDir = "/Users/NiloofarZarei/Desktop/STAAR_2016/STAAR_2016" + "/\(documentName)_STAAR/"
        let slowDir = mainDir + "AudioSlow/"
        let normalDir = mainDir + "AudioNormal/"
        let fastDir = mainDir + "AudioFast/"
     
        
        var pageNum = 1
        var lineNum = 1
        var wordNum = 1
        var wordIndex = 1
        
        for page in self.PDFPages
            {
        var wordsArray = page.myPageWordsDetails.words
                
        
        var newWordsArray: [String] = []
        for word in wordsArray{
            if word == "" || word.asciiArray == [] {
                wordsArray.remove(at: wordsArray.index(of: word)!)
                continue
            }
            let newWord = word.removingCharacters(forbiddenCharacters: CharacterSet.alphanumerics.inverted)
            newWordsArray.append(newWord)
        }
        
        self.NewWordsArray = newWordsArray
        var wordStarts : [CGPoint] = []
        var wordEnds : [CGPoint] = []
        var check = 0
        debugPrint("number of lines in this page \(page.pageLines.count)")
        for line in page.pageLines{
            check += 1
            debugPrint("number of words in line \(check) is \(line.lineWords.count)")
            for word in line.lineWords{
                wordStarts.append(word.wordSegment.startPoint)
                wordEnds.append(word.wordSegment.endPoint)
                debugPrint("check is \(check)")
            }
        }
                
        for line in page.pageLines{
            for word in line.lineWords{
                CSVText.append("\(wordIndex),\(newWordsArray[wordNum-1].description),\(wordStarts[wordNum-1].x),\(wordStarts[wordNum-1].y),\(wordEnds[wordNum-1].x-wordStarts[wordNum-1].x),\(lineNum),\(pageNum),\(NSString(string: durationArray[wordNum-1]).floatValue),\(addrArray[wordNum-1])\n")
                wordNum += 1
                wordIndex += 1
            }
            lineNum += 1
        }

        
        do{
            try CSVText.write(toFile: ParentDir + "\(documentName)_data.csv", atomically: true, encoding: String.Encoding.utf8 )
//            return true
        } catch{
//            return false
        }
        
        wordNum = 1
        lineNum = 1
        pageNum += 1
    }

    }

}


