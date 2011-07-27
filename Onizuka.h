/*
Copyright © 2005-2011 Brian S. Hall

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License version 2 or later as
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
  NSString*  _appName;    // Used for menu items like "About MyApp".
  NSString*  _appVersion; // The short version string like "2.0.1".
  regex_t    _regex;      // Matches __BLAH_BLAH__
}
+(Onizuka*)sharedOnizuka;
-(NSString*)appName;
-(NSString*)appVersion;
-(void)localizeMenu:(NSMenu*)menu;
-(void)localizeWindow:(NSWindow*)window;
-(void)localizeView:(NSView*)window;
// Low-level nonrecursive method that localizes via setTitle:, setStringValue:,
// setLabel:, setToolTip:, and setPaletteLabel:, using any and all of these
// (and their associated getters) if the object responds to the selector.
// If title is nil, uses existing label, title, or value, presumably set up
// in Interface Builder.
// Generally this is used internally when you call one of the three high-level
// methods above. You would typically use a non-nil title when changing an item
// in response to some change in application  state, for example:
//   [[Onizuka sharedOnizuka] localizeObject:myTextField
//                            withTitle:@"__NETWORK_ERROR__"];
// But, for some objects you would end up setting its string value,
// tool tip, and everything to the value you pass in.
// For really fine control, you may have to use even lower level
// techniques, like copyLocalizedTitle: below.
-(void)localizeObject:(id)item withTitle:(NSString*)title;
-(NSMutableString*)copyLocalizedTitle:(NSString*)title;
// Returns an autoreleased string.
-(NSString*)bestLocalizedString:(NSString*)key;
@end
