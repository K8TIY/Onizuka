#import "OnizukaTester.h"
#import "Onizuka.h"

@implementation OnizukaTester
-(void)awakeFromNib
{
  [[Onizuka sharedOnizuka] localizeMenu:[[NSApplication sharedApplication] mainMenu]];
  [[Onizuka sharedOnizuka] localizeWindow:_window];
}
@end
