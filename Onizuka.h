/*
Copyright © 2005-2012 Brian S. Hall

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

@interface Onizuka : NSObject
{
  NSString*            _appName;
  NSString*            _appVersion;
  NSMutableDictionary* _cache;
}
+(Onizuka*)sharedOnizuka;
// Localizable.strings (and Onizuka.strings) dictionaries are cached for
// faster subsequent lookups. If your strings files are large, if you have
// partial localizations that may default back to a more general localization
// (e.g., an en_GB file that only contains a few British vs American spelling
// differences), and/or you will do most localization once at program launch
// and thereafter do little or no on-the-fly localization, call this method to
// possibly improve the memory footprint of your application.
-(void)clearCache;
// Used for menu items like "About MyApp".
// Uses the value of CFBundleName from Info.plist (which is localizable).
// If not found, uses NSProcessInfo to get the name.
-(NSString*)appName;
// The short version string like "2.0.1".
-(NSString*)appVersion;
-(void)localizeMenu:(NSMenu*)menu;
-(void)localizeWindow:(NSWindow*)window;
-(void)localizeView:(NSView*)window;
// Low-level nonrecursive method that localizes via setTitle:, setStringValue:,
// setAttributedStringValue:, setLabel:, setToolTip:, and setPaletteLabel:,
// using any and all of these (and their associated getters) if the object
// responds to the selector.
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
// The next two wrap basically the same code. If your title is an attributed
// string, that's what you get back. Otherwise you get back a string.
// Returns a copy of the title with all instances of the __X__ pattern replaced
// with localized substrings, if they could be found.
-(NSString*)copyLocalizedTitle:(NSString*)title;
-(NSAttributedString*)copyLocalizedAttributedTitle:(NSAttributedString*)title;
// Searches Localizable.strings and Onizuka.strings in order of user
// language preference and returns the first match for the key.
// Returns an autoreleased string.
-(NSString*)bestLocalizedString:(NSString*)key;
@end
