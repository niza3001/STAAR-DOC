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
    
    func setPageWordsDetails(){
        myPageWordsDetails.mySelections = myScanner.select(" ") as NSArray
        let pageTextString = myScanner.getPageText()!
        //let pageTextString = pageTextStringRaw.replace(target: "'", withString:"''")
        myPageWordsDetails.words = pageTextString.components(separatedBy: " ")
        var transformedRects: [CGRect] = []
        
        for object in myPageWordsDetails.mySelections{
            let rect: CGRect = (object as AnyObject).frame.applying((object as AnyObject).transform)
            let x = rect.origin.x*(1.176 as CGFloat) + 1.041
            let y = rect.origin.y*(-1.174 as CGFloat) + 942.7
            let w = rect.width * 1.176
            let h = rect.height * 1.174
            
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
    
    
    //MARK: Initialization
    //____________________________________________
    init(thisPath:URL){
        self.PDFPath = thisPath
        self.PDFdoc = CGPDFDocument(thisPath as CFURL)
        let pageCount = self.PDFdoc.numberOfPages
        for pageNum in 1...pageCount{
            let page = STAAR_PDFPageClass(aPDFDoc: self.PDFdoc,aPageNum: pageNum)
            page.setPageWordsDetails()
            var line = STAAR_Lineclass()
            line.lineYvalue = page.myPageWordsDetails.wordBBoxArray[0].origin.y - page.myPageWordsDetails.wordBBoxArray[0].height/2
            var counter = 0
            for wordBBox in page.myPageWordsDetails.wordBBoxArray{
                if line.lineYvalue == wordBBox.origin.y - wordBBox.height/2 {
                    let str = page.myPageWordsDetails.words[counter]
                    //print(str)
                    let start = CGPoint(x: wordBBox.origin.x, y: line.lineYvalue)
                    let end = CGPoint(x: wordBBox.origin.x+wordBBox.width, y: line.lineYvalue)
                    let word = STAAR_Wordclass(str: str, bbox: wordBBox,startpoint: start,endpoint: end)
                    line.lineWords.append(word)
                }
                else {
                    page.pageLines.append(line)
                    let nextLine = line.lineNum
                    line = STAAR_Lineclass()
                    line.lineNum = nextLine
                    let str = page.myPageWordsDetails.words[counter]
                    line.lineYvalue = wordBBox.origin.y - wordBBox.height/2
                    let start = CGPoint(x: wordBBox.origin.x, y: line.lineYvalue)
                    let end = CGPoint(x: wordBBox.origin.x+wordBBox.width, y: line.lineYvalue)
                    let word = STAAR_Wordclass(str: str, bbox: wordBBox,startpoint: start,endpoint: end)
                    line.lineWords.append(word)
                }
                counter += 1
            }
            self.PDFPages.append(page)
            
        }
    }
    
    
//    func lineCounter(wordStarts : [CGPoint], i: Int) -> Int{
//        
//        if i == 0 {
//            l = 1
//        }
//        else if (wordStarts[i].y == wordStarts[i-1].y){
//            //Do Nothing
//        }
//        else {
//            l = l+1
//        }
//        return l
//    }
    
    func writeDataToFile(ParentDir:String, documentName: String) -> Bool
    {
        // check our data exists
        var wordsArray = self.PDFPages[0].myPageWordsDetails.words
        var newWordsArray: [String] = []
        for word in wordsArray{
            var newWord = word.removingCharacters(forbiddenCharacters: CharacterSet.alphanumerics.inverted)
            newWordsArray.append(newWord)
        }
        var wordStarts : [CGPoint] = []
        var wordEnds : [CGPoint] = []
        for line in self.PDFPages[0].pageLines{
            for word in line.lineWords{
                wordStarts.append(word.wordSegment.startPoint)
                wordEnds.append(word.wordSegment.endPoint)
            }
        }
//        print("Validation")
//        debugPrint(wordsArray.count)
//        debugPrint(wordStarts.count)
//        debugPrint(wordEnds.count)
//        debugPrint(wordsArray[18])
        var CSVText = "ID,WORD,POSWX,POSLY,LENGTH,LINE,PAGE,DURATION,AUDIOSLOW,AUDIONORMAL,AUDIOFAST\n"
        let mainDir = "/Users/NiloofarZarei/Desktop/STAAR_2016/STAAR_2016" + "/\(documentName)_STAAR/"
        let slowDir = mainDir + "AudioSlow/"
        let normalDir = mainDir + "AudioNormal/"
        let fastDir = mainDir + "AudioFast/"
        let durationPath = Bundle.main.path(forResource: "NormalDurations", ofType: "txt")! as String
        let content = try! String(contentsOfFile: durationPath, encoding: String.Encoding.utf8).components(separatedBy: "\n")
        debugPrint(content.last)
        for i in 0...340 {
            CSVText.append("\(i+1),\(newWordsArray[i]),\(wordStarts[i].x),\(wordStarts[i].y),\(wordEnds[i].x-wordStarts[i].x),0,1,\(content[i]),\(slowDir + "\(i+1).aiff"),\(normalDir + "\(i+1).aiff"),\(fastDir + "\(i+1).aiff")\n")
        }
        
        do{
            try CSVText.write(toFile: ParentDir + "\(documentName)_data.csv", atomically: true, encoding: String.Encoding.utf8 )
            return true
        } catch{
            return false
        }
    }

}



