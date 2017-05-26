#import <Foundation/Foundation.h>
#import "StringDetector.h"
#import "FontCollection.h"
#import "RenderingState.h"
#import "Selection.h"
#import "RenderingStateStack.h"

@interface Scanner2 : NSObject <StringDetectorDelegate> {
	CGPDFPageRef pdfPage;
	NSMutableArray *selections;
    Selection *possibleSelection;
	
	StringDetector *stringDetector;
	FontCollection *fontCollection;
	RenderingStateStack *renderingStateStack;
	NSMutableString *content;
}

+ (Scanner2 *)scannerWithPage:(CGPDFPageRef)page;

- (void)scan;
- (NSArray *)select:(NSMutableString *)keyword;
- (NSString *)getPageText;

@property (nonatomic, readonly) RenderingState *renderingState;

@property (nonatomic, retain) RenderingStateStack *renderingStateStack;
@property (nonatomic, retain) FontCollection *fontCollection;
@property (nonatomic, retain) StringDetector *stringDetector;
@property (nonatomic, retain) NSMutableString *content;


@property (nonatomic, retain) NSMutableArray *selections;
@end
