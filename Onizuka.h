/*
Copyright © 2005-2010 Brian S. Hall

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/
#import <Cocoa/Cocoa.h>
#include <regex.h>

@interface Onizuka : NSObject
{
  NSString*  _appName;    // Used for menu items like "About MyApp...".
  NSString*  _appVersion; // The short version string like "2.0.1".
  regex_t    _regex;      // Matches __BLAH_BLAH__
}
+(Onizuka*)sharedOnizuka;
-(NSString*)appName;
-(NSString*)appVersion;
-(void)localizeMenu:(NSMenu*)menu;
-(void)localizeWindow:(NSWindow*)window;
-(void)localizeView:(NSView*)window;
// Low-level method that localizes item via setLabel: setTitle: or
// setStringValue: (using the first method that item responds to).
// If title is nil, uses existing label, title, or value.
// Generally this is used internally when you call one of the three high-level
// methods above. You would typically use a non-nil title when changing an item
// in response to some change in application  state, for example:
//   [[Onizuka sharedOnizuka] localizeObject:myTextField
//                            withTitle:@"__NETWORK_ERROR__"];
-(void)localizeObject:(id)item withTitle:(NSString*)title;
-(NSMutableString*)copyLocalizedTitle:(NSString*)title;
// Returns an autoreleased string
-(NSString*)bestLocalizedString:(NSString*)key;
@end
