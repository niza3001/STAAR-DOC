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

class STAAR_PDFAnalyzerClass{
    
    func createDoc (url: CFURL) {
        let pdfDocument = CGPDFDocumentCreateWithURL(url)
        let numPages = CGPDFDocumentGetNumberOfPages(pdfDocument)
        let operatorTableRef = CGPDFOperatorTableCreate()
        
        
        // http://stackoverflow.com/questions/4080373/get-pdf-hyperlinks-on-ios-with-quartz
        
        for pageNum in 1...numPages {
            
            //get page
            let page = CGPDFDocumentGetPage(pdfDocument, pageNum)
            //create content stream with page
            let stream = CGPDFContentStreamCreateWithPage(page)
            //
            let scanner = CGPDFScannerCreate(stream, operatorTableRef, nil)
            CGPDFScannerScan(scanner)
            //CGPDFDictionaryRef pageDictionary = CGPDFPageGetDictionary(page)
            let pageDictionary = CGPDFStreamGetDictionary(stream)
            //not sure if the next two lines work
            var outputArray: CGPDFArrayRef = nil
            if (!CGPDFDictionaryGetArray(pageDictionary, "Annots",UnsafeMutablePointer<CGPDFArrayRef>(outputArray))){
                return;
            }
            
            let arrayCount = CGPDFArrayGetCount( outputArray )
            if(arrayCount == 0){
                return
            }
            
            let words = NSMutableArray.init(capacity:arrayCount)
            let BBoxes = NSMutableArray.init(capacity:arrayCount)
            
            for counter in 1...arrayCount{
                var DictObj: CGPDFObjectRef!
                if(!CGPDFArrayGetObject(outputArray, counter,UnsafeMutablePointer<CGPDFObjectRef>(DictObj))) {
                    return;
                }
                
                var annotDict: CGPDFDictionaryRef!
                if(!CGPDFObjectGetValue(DictObj,CGPDFObjectType.Dictionary, UnsafeMutablePointer<CGPDFDictionaryRef>(annotDict))) {
                    return;
                }
                
                var aDict: CGPDFDictionaryRef!
                if (!CGPDFDictionaryGetDictionary(annotDict, "A", UnsafeMutablePointer<CGPDFDictionaryRef>(aDict))) {
                    continue;
                }
                
                var uriStringRef: CGPDFStringRef!
                if(!CGPDFDictionaryGetString(aDict, "URI", UnsafeMutablePointer<CGPDFStringRef>(uriStringRef))) {
                    return;
                }
                
                var rectArray: CGPDFArrayRef!
                if(!CGPDFDictionaryGetArray(annotDict, "Rect",UnsafeMutablePointer<CGPDFArrayRef>(rectArray))) {
                    return;
                }
                    
 
            }
            
            
            CGPDFScannerRelease(scanner)
            CGPDFContentStreamRelease(stream)
            CGPDFScannerRelease(scanner)
            CGPDFContentStreamRelease(stream)
            
        }
        
        CGPDFOperatorTableRelease(operatorTableRef)

            }

}