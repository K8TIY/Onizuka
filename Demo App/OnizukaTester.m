#import "OnizukaTester.h"
#import "Onizuka.h"

@implementation OnizukaTester
-(void)awakeFromNib
{
  Onizuka* oz = [Onizuka sharedOnizuka];
  [oz localizeMenu:[[NSApplication sharedApplication] mainMenu]];
  [oz localizeWindow:_window];
  [oz clearCache];
}
@end
