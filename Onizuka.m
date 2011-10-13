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
-(NSMutableString*)copyLocalizedTitle1Pass:(NSString*)title;
@end

@implementation Onizuka
static Onizuka* gSharedOnizuka = nil;
static const char* gRegexString = "__[A-Z]+(_[A-Z]+)*__";

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
  if (0 != regcomp(&_regex, gRegexString, REG_EXTENDED))
    [NSException raise:@"OnizukaException"
                 format:@"Error: could not compile Onizuka regex '%s'", gRegexString];
  return self;
}

-(void)dealloc
{
  [_appName release];
  regfree(&_regex);
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
  NSString* str = [ts string];
  NSString* localized = [self copyLocalizedTitle:str];
  if (localized)
  {
    NSRange range = NSMakeRange(0, 1);
    NSDictionary* attrs = [ts attributesAtIndex:0 effectiveRange:&range];
    range.length = [str length];
    NSAttributedString* attrStr = [[NSAttributedString alloc] initWithString:localized attributes:attrs];
    [localized release];
    [ts replaceCharactersInRange:range withAttributedString:attrStr];
    [attrStr release];
  }
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
        NSString* localized = [self copyLocalizedTitle:title];
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
    NSString* lab = [self copyLocalizedTitle:[cell labelForSegment:i]];
    if (lab)
    {
      [cell setLabel:lab forSegment:i];
      [lab release];
    }
    lab = [self copyLocalizedTitle:[cell toolTipForSegment:i]];
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
  NSMutableString* localized;
  SEL getters[5] = {@selector(title),@selector(stringValue),@selector(label),@selector(toolTip),@selector(paletteLabel)};
  SEL setters[5] = {@selector(setTitle:),@selector(setStringValue:),@selector(setLabel:),@selector(setToolTip:),@selector(setPaletteLabel:)};
  unsigned i;
  for (i = 0; i < 5; i++)
  {
    if ([item respondsToSelector:getters[i]] &&
        [item respondsToSelector:setters[i]])
    {
      NSString* locTitle = (title)? title:[item performSelector:getters[i] withObject:nil];
      if (locTitle)
      {
        localized = [self copyLocalizedTitle:locTitle];
        if (localized)
        {
          if (![localized isEqualToString:locTitle])
          {
            [item performSelector:setters[i] withObject:localized];
          }
          [localized release];
          localized = nil;
        }
      }
    }
  }
}

// Returns a string that must be released, or nil if no localization could be found.
-(NSMutableString*)copyLocalizedTitle:(NSString*)title
{
  NSMutableString* localized = nil;
  NSMutableString* loc1 = [self copyLocalizedTitle1Pass:title];
  //NSLog(@"Pass 1: %@", loc1);
  if (loc1)
  {
    localized = [self copyLocalizedTitle1Pass:loc1];
    //NSLog(@"Pass 2: %@", localized);
    if (!localized) localized = loc1;
    else [loc1 release];
  }
  return localized;
}

-(NSMutableString*)copyLocalizedTitle1Pass:(NSString*)title
{
  if (!title) return nil;
  NSMutableString* localized = nil;
  const char* s = [title UTF8String];
  regoff_t handled = 0L; // The last character we handled
  regmatch_t match = {0,strlen(s)};
  BOOL gotOne = NO;
  NSString* add;
  NSString* loc;
  //NSLog(@"%llu-%llu handled %llu", match.rm_so, match.rm_eo, handled);
  while (YES)
  {
    int e = regexec(&_regex, s, 1, &match, REG_STARTEND);
    if (e)
    {
      size_t errneeded = regerror(e, &_regex, NULL, 0);
      char* errbuf = malloc(errneeded);
      regerror(e, &_regex, errbuf, errneeded);
      if (e != REG_NOMATCH) NSLog(@"%d: %s", e, errbuf);
      free(errbuf);
      break;
    }
    if (!localized) localized = [[NSMutableString alloc] init];
    gotOne = YES;
    //NSLog(@"regexec: %llu-%llu handled %llu", match.rm_so, match.rm_eo, handled);
    if (match.rm_so > handled)
    {
      add = [[NSString alloc] initWithBytes:s+handled
                              length:match.rm_so-handled
                              encoding:NSUTF8StringEncoding];
      [localized appendString:add];
      [add release];
    }
    add = [[NSString alloc] initWithBytes:s+match.rm_so
                            length:match.rm_eo-match.rm_so
                            encoding:NSUTF8StringEncoding];
    if ([add isEqual:@"__APPNAME__"]) loc = _appName;
    else if ([add isEqual:@"__VERSION__"]) loc = _appVersion;
    else loc = [self bestLocalizedString:add];
    [localized appendString:(loc)? loc:add];
    [add release];
    handled = match.rm_eo;
    match.rm_so = match.rm_eo;
    match.rm_eo = strlen(s);
  }
  if (gotOne && handled < strlen(s))
  {
    add = [[NSString alloc] initWithBytes:s+handled
                            length:strlen(s)-handled
                            encoding:NSUTF8StringEncoding];
    if ([add isEqual:@"__APPNAME__"]) loc = _appName;
    else if ([add isEqual:@"__VERSION__"]) loc = _appVersion;
    else loc = [self bestLocalizedString:add];
    [localized appendString:(loc)? loc:add];
    [add release];
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
