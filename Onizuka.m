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
#import "Onizuka.h"

@interface Onizuka (Private)
-(void)localizeTextView:(NSTextView*)tv;
-(void)localizeTableView:(NSTableView*)item;
-(void)localizeForm:(NSForm*)form;
-(void)localizeMatrix:(NSMatrix*)matrix;
-(void)localizeSegmentedControl:(NSSegmentedControl*)item;
-(void)localizeComboBox:(NSComboBox*)box;
-(void)localizeToolbar:(NSToolbar*)bar;
-(NSObject*)copyLocalizedTitle1Pass:(NSObject*)title;
@end

@implementation Onizuka
static Onizuka* gSharedOnizuka = nil;

+(Onizuka*)sharedOnizuka
{
  if (nil == gSharedOnizuka) gSharedOnizuka = [[Onizuka alloc] init];
  return gSharedOnizuka;
}

-(id)init
{
  self = [super init];
  // Uses the value of CFBundleName from Info.plist (which is localizable).
  // If not found, uses NSProcessInfo to get the name.
  NSBundle* mb = [NSBundle mainBundle];
  NSString* appname = [mb objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey];
  if (!appname) appname = [[NSProcessInfo processInfo] processName];
  _appName = [[NSString alloc] initWithString:appname];
  NSString* version = [mb objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  if (!version) version = @"1.0";
  _appVersion = [[NSString alloc] initWithString:version];
  return self;
}

-(void)dealloc
{
  [_appName release];
  [super dealloc];
}

-(NSString*)appName { return _appName; }
-(NSString*)appVersion { return _appVersion; }

-(void)localizeMenu:(NSMenu*)menu
{
  if (menu)
  {
    //NSLog(@"Localizing menu %@", menu);
    [self localizeObject:menu withTitle:nil];
    NSArray* items = [menu itemArray];
    NSEnumerator* enumerator = [items objectEnumerator];
    NSMenuItem* item;
    while ((item = [enumerator nextObject]))
    {
      //NSLog(@"Localizing menu item %@", item);
      [self localizeObject:item withTitle:nil];
      if ([item submenu]) [self localizeMenu:[item submenu]];
      if ([item respondsToSelector:@selector(view)])
      {
        id view = [item performSelector:@selector(view)];
        [self localizeView:view];
      }
    }
  }
}

-(void)localizeWindow:(NSWindow*)window
{
  [self localizeObject:window withTitle:nil];
  NSView* item = [window contentView];
  [self localizeView:item];
  NSToolbar* bar = [window toolbar];
  if (bar) [self localizeToolbar:bar];
  NSArray* drawers = [window drawers];
  if (drawers)
  {
    NSEnumerator* enumerator = [drawers objectEnumerator];
    NSDrawer* drawer;
    while ((drawer = [enumerator nextObject]))
      [self localizeView:[drawer contentView]];
  }
}

-(void)localizeView:(NSView*)view
{
  //NSLog(@"Localizing view (%@) %@", [view class], view);
  if ([view respondsToSelector:@selector(menu)])
  {
    //NSLog(@"Localizing view w/ menu: [%@ %@", [view class], view);
    [self localizeMenu:[view menu]];
  }
  [self localizeObject:view withTitle:nil];
  NSArray* items = nil;
  if ([view isKindOfClass:[NSTabView class]])
  {
    items = [(NSTabView*)view tabViewItems];
  }
  else if ([view isKindOfClass:[NSTabViewItem class]])
  {
    items = [[(NSTabViewItem*)view view] subviews];
  }
  else if ([view isKindOfClass:[NSTextView class]])
  {
    [self localizeTextView:(NSTextView*)view];
  }
  else if ([view isKindOfClass:[NSTableView class]])
  {
    [self localizeTableView:(NSTableView*)view];
  }
  else if ([view isKindOfClass:[NSForm class]])
  {
    [self localizeForm:(NSForm*)view];
  }
  else if ([view isKindOfClass:[NSMatrix class]])
  {
    [self localizeMatrix:(NSMatrix*)view];
  }
  else if ([view isKindOfClass:[NSComboBox class]])
  {
    [self localizeComboBox:(NSComboBox*)view];
  }
  else
  {
    // NSSegmentedControl is 10.3 only, so we use generic code so as not
    // to be dependent on the 10.3 SDK.
    id segctlClass = objc_getClass("NSSegmentedControl");
    if (segctlClass && [view isKindOfClass:segctlClass])
    {
      [self localizeSegmentedControl:(NSSegmentedControl*)view];
    }
    else items = [view subviews];
  }
  if (items)
  {
    NSEnumerator* enumerator = [items objectEnumerator];
    NSView* item;
    while ((item = [enumerator nextObject]))
    {
      [self localizeView:item];
    }
  }
}

-(void)localizeTextView:(NSTextView*)tv
{
  NSTextStorage* ts = [tv textStorage];
  NSAttributedString* localized = [self copyLocalizedAttributedTitle:ts];
  if (localized) [ts setAttributedString:localized];
}

-(void)localizeTableView:(NSTableView*)item
{
  NSTableView* tv = item;
  NSArray* cols = [tv tableColumns];
  NSEnumerator* enumerator = [cols objectEnumerator];
  NSTableColumn* col;
  while ((col = [enumerator nextObject]))
    [self localizeObject:[col headerCell] withTitle:nil];
}

-(void)localizeForm:(NSForm*)form
{
  unsigned i = 0;
  while (YES)
  {
    NSFormCell* cell = [form cellAtIndex:i];
    if (nil == cell) break;
    [self localizeObject:cell withTitle:nil];
    if ([cell respondsToSelector:@selector(placeholderString)])
    {
      NSString* title = [cell placeholderString];
      if (title)
      {
        NSString* localized = (NSString*)[self copyLocalizedTitle:title];
        if (![localized isEqualToString:title])
        {
          [cell setPlaceholderString:localized];
        }
        [localized release];
      }
    }
    i++;
  }
}

-(void)localizeMatrix:(NSMatrix*)matrix
{
  unsigned i = 0, j = 0;
  unsigned rows = [matrix numberOfRows];
  unsigned cols = [matrix numberOfColumns];
  for (i = 0; i < rows; i++)
  {
    for (j = 0; j < cols; j++)
    {
      NSCell* cell = [matrix cellAtRow:i column:j];
      [self localizeObject:cell withTitle:nil];
    }
  }
}

-(void)localizeSegmentedControl:(NSSegmentedControl*)item
{
  unsigned i, nsegs = [item segmentCount];
  NSSegmentedCell* cell = [item cell];
  for (i = 0; i < nsegs; i++)
  {
    NSString* lab = (NSString*)[self copyLocalizedTitle:[cell labelForSegment:i]];
    if (lab)
    {
      [cell setLabel:lab forSegment:i];
      [lab release];
    }
    lab = (NSString*)[self copyLocalizedTitle:[cell toolTipForSegment:i]];
    if (lab)
    {
      [cell setToolTip:lab forSegment:i];
      [lab release];
    }
    [self localizeMenu:[cell menuForSegment:i]];
  }
}

-(void)localizeComboBox:(NSComboBox*)box
{
  if (![box usesDataSource])
  {
    NSArray* objs = [box objectValues];
    NSEnumerator* enumerator = [objs objectEnumerator];
    id val;
    NSMutableArray* newVals = [[NSMutableArray alloc] init];
    while ((val = [enumerator nextObject]))
    {
      id newVal = nil;
      if ([val isKindOfClass:[NSString class]])
      {
        newVal = [self copyLocalizedTitle:val];
        if (newVal) [newVal autorelease];
      }
      [newVals addObject:(newVal)? newVal:val];
    }
    [box removeAllItems];
    [box addItemsWithObjectValues:newVals];
    [newVals release];
  }
}

-(void)localizeToolbar:(NSToolbar*)bar
{
  NSArray* objs = [bar items];
  NSEnumerator* enumerator = [objs objectEnumerator];
  NSToolbarItem* item;
  while ((item = [enumerator nextObject]))
  {
    // NSToolbarItemGroup is 10.5 only, so we use generic code so as not
    // to be dependent on the 10.5 SDK.
    id tbigClass = objc_getClass("NSToolbarItemGroup");
    if (tbigClass && [item isKindOfClass:tbigClass])
    {
      NSArray* subs = [item performSelector:@selector(subitems)];
      NSEnumerator* enumerator2 = [subs objectEnumerator];
      NSToolbarItem* item2;
      while ((item2 = [enumerator2 nextObject]))
        [self localizeObject:item2 withTitle:nil];
    }
    else [self localizeObject:item withTitle:nil];
  }
}

-(void)localizeObject:(id)item withTitle:(NSString*)title
{
  SEL getters[6] = {@selector(title),@selector(stringValue),
                    @selector(attributedStringValue),@selector(label),
                    @selector(toolTip),@selector(paletteLabel)};
  SEL setters[6] = {@selector(setTitle:),@selector(setStringValue:),
                    @selector(setAttributedStringValue:),@selector(setLabel:),
                    @selector(setToolTip:),@selector(setPaletteLabel:)};
  unsigned i;
  if (!item) return;
  NSString* cmp1 = title;
  if ([cmp1 isKindOfClass:[NSAttributedString class]])
    cmp1 = [(NSAttributedString*)title string];
  // NSPathControl doesn't like atributed string localizations.
  id pcClass = objc_getClass("NSPathControl");
  BOOL gotOne = NO;
  for (i = 0; i < 6; i++)
  {
    if (i == 2 && pcClass && [item isKindOfClass:pcClass]) continue;
    // If this is a passed-in title, don't fiddle with attributed strings.
    if (i == 2 && title) continue;
    if ([item respondsToSelector:getters[i]] &&
        [item respondsToSelector:setters[i]])
    {
      NSObject* locTitle = (title)? title:[item performSelector:getters[i]];
      if (locTitle)
      {
        NSObject* localized = [self copyLocalizedTitle:(NSString*)locTitle];
        if (localized)
        {
          gotOne = YES;
          NSString* cmp2 = (NSString*)localized;
          if ([localized isKindOfClass:[NSAttributedString class]])
            cmp2 = [(NSAttributedString*)localized string];
          if (![cmp1 isEqualToString:cmp2])
          {
            NS_DURING
            [item performSelector:setters[i] withObject:localized];
            NS_HANDLER
            gotOne = NO;
            NS_ENDHANDLER
          }
          [localized release];
          localized = nil;
        }
      }
    }
    // I expect a passed-in title will correspond to only one accessor.
    if (title && gotOne) break;
  }
}

// Returns nil if no localization could be found.
-(NSString*)copyLocalizedTitle:(NSString*)title
{
  NSString* localized = nil;
  NSString* loc1 = (NSString*)[self copyLocalizedTitle1Pass:title];
  //NSLog(@"Pass 1: %@", loc1);
  if (loc1)
  {
    localized = (NSString*)[self copyLocalizedTitle1Pass:loc1];
    //NSLog(@"Pass 2: %@", localized);
    if (!localized) localized = loc1;
    else [loc1 release];
  }
  return localized;
}

// Returns nil if no localization could be found.
-(NSAttributedString*)copyLocalizedAttributedTitle:(NSAttributedString*)title
{
  return (NSAttributedString*)[self copyLocalizedTitle:(NSString*)title];
}

-(NSObject*)copyLocalizedTitle1Pass:(NSObject*)title
{
  if (!title) return nil;
  BOOL attr = [title isKindOfClass:[NSAttributedString class]];
  NSObject* localized = [title mutableCopy];
  NSString* s = (attr)? [(NSMutableAttributedString*)title string]:(NSString*)title;
  unsigned i, len = [s length];
  unsigned state = 0;
  unsigned start = 0;
  for (i = 0; i < len; i++)
  {
    unichar c = [s characterAtIndex:i];
    // State table for FSA accepting __[A-Z]+(_[A-Z]+)*__
    switch (state)
    {
      case 0:
      if (c == '_')
      {
        state = 1;
        start = i;
      }
      break;
      
      case 1:
      if (c == '_') state = 2;
      else state = 0;
      break;
      
      case 2:
      if (c == '_')
      {
        state = 1;
        start = i-1;
      }
      else if (isupper(c)) state = 3;
      else state = 0;
      break;
      
      case 3:
      if (c == '_') state = 4;
      else if (isupper(c)) state = 3;
      else state = 0;
      break;
      
      case 4:
      if (c == '_')
      {
        NSString* loc = nil;
        unsigned sublen = 1+i-start;
        NSRange r = NSMakeRange(start, sublen);
        NSString* sub = [s substringWithRange:r];
        if ([sub isEqualToString:@"__APPNAME__"]) loc = _appName;
        else if ([sub isEqual:@"__VERSION__"]) loc = _appVersion;
        else loc = [self bestLocalizedString:sub];
        if (loc)
        {
          // Go forward or back depending on the size difference between capture
          // and replacement text.
          int delta = sublen - [loc length];
          len -= delta;
          i -= delta;
          [(NSMutableString*)localized replaceCharactersInRange:r
                                       withString:loc];
          s = (attr)? [(NSMutableAttributedString*)localized string]:(NSString*)localized;
        }
        state = 0;
        start = 0;
      }
      else if (isupper(c)) state = 3;
      else state = 0;
      break;
    }
  }
  return localized;
}

-(NSString*)bestLocalizedString:(NSString*)key
{
  NSString* localized = NSLocalizedString(key, nil);
  if ([localized isEqualToString:key])
  {
    NSBundle* mb = [NSBundle mainBundle];
    NSArray* locs = [NSBundle preferredLocalizationsFromArray:[mb preferredLocalizations]];
    NSEnumerator* iter = [locs objectEnumerator];
    NSString* lang;
    BOOL gotIt = NO;
    while ((lang = [iter nextObject]) && !gotIt)
    {
      NSString* p = [mb pathForResource:@"Localizable" ofType:@"strings"
                        inDirectory:nil forLocalization:lang];
      NSDictionary* strings = [[NSDictionary alloc] initWithContentsOfFile:p];
      localized = [strings objectForKey:key];
      if (localized)
      {
        [[localized retain] autorelease];
        gotIt = YES;
      }
      if (strings) [strings release];
      if (!gotIt)
      {
        p = [mb pathForResource:@"Onizuka" ofType:@"strings"
                inDirectory:nil forLocalization:lang];
        strings = [[NSDictionary alloc] initWithContentsOfFile:p];
        localized = [strings objectForKey:key];
        if (localized)
        {
          [[localized retain] autorelease];
          gotIt = YES;
        }
        if (strings) [strings release];
      }
    }
  }
  return localized;
}

@end
