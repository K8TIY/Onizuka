/*
The MIT License (MIT)

Copyright © 2005-2018 Brian S. Hall

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/
#import "Onizuka.h"
#import <objc/objc-class.h>

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
  NSBundle* mb = [NSBundle mainBundle];
  NSString* appname = [[mb localizedInfoDictionary] objectForKey:(NSString*)kCFBundleNameKey];
  if (!appname) [mb objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey];
  if (!appname) appname = [[NSProcessInfo processInfo] processName];
  _appName = [[NSString alloc] initWithString:appname];
  NSString* version = [mb objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
  if (!version) version = @"1.0";
  _appVersion = [[NSString alloc] initWithString:version];
  version = [mb objectForInfoDictionaryKey:@"CFBundleVersion"];
  if (!version) version = @"1.0";
  _appLongVersion = [[NSString alloc] initWithString:version];
  _cache = [[NSMutableDictionary alloc] init];
  NSFileManager* fm = [NSFileManager defaultManager];
  NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
  NSArray* langs = [defs objectForKey:@"AppleLanguages"];
  //NSLog(@"raw languages %@", langs);
  NSMutableArray* tmpArray = [[NSMutableArray alloc] init];
  NSEnumerator* iter = [langs objectEnumerator];
  NSString* lang;
  while (lang = [iter nextObject])
  {
    NSString* p = [mb pathForResource:@"Localizable" ofType:@"strings"
                      inDirectory:nil forLocalization:lang];
    if ([fm fileExistsAtPath:p])
    {
      [tmpArray addObject:lang];
    }
    NSArray* comps = [lang componentsSeparatedByString:@"-"];
    if ([comps count] > 1)
    {
      NSMutableArray* mcomps = [[NSMutableArray alloc] initWithArray:comps];
      while ([mcomps count] > 1)
      {
        [mcomps removeLastObject];
        lang = [mcomps componentsJoinedByString:@"-"];
        p = [mb pathForResource:@"Localizable" ofType:@"strings"
                inDirectory:nil forLocalization:lang];
        if ([fm fileExistsAtPath:p])
        {
          [tmpArray addObject:lang];
        }
      }
      [mcomps release];
    }
  }
  _languages = [[NSArray alloc] initWithArray:tmpArray];
  [tmpArray release];
  //NSLog(@"Languages: %@", _languages);
  return self;
}

-(void)dealloc
{
  [_appName release];
  [_appVersion release];
  [_cache release];
  [_languages release];
  [super dealloc];
}

-(void)clearCache
{
  [_cache removeAllObjects];
}

-(NSString*)appName { return _appName; }
-(NSString*)appVersion { return _appVersion; }
-(NSArray*)languages { return _languages; }

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
  if (localized)
  {
    if ([localized isKindOfClass:[NSString class]])
    {
      NSAttributedString* as = [[NSAttributedString alloc]
                                 initWithString:(NSString*)localized];
      [ts setAttributedString:as];
      [as release];
    }
    else [ts setAttributedString:localized];
    [localized release];
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
  NSInteger i = 0, j = 0;
  NSInteger rows = [matrix numberOfRows];
  NSInteger cols = [matrix numberOfColumns];
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
  NSInteger i, nsegs = [item segmentCount];
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
        if (!cmp1)
        {
          cmp1 = (NSString*)locTitle;
          if ([cmp1 isKindOfClass:[NSAttributedString class]])
            cmp1 = [(NSAttributedString*)locTitle string];
        }
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
  NSInteger i, len = [s length];
  NSInteger state = 0;
  NSInteger start = 0;
  for (i = 0; i < len; i++)
  {
    unichar c = [s characterAtIndex:i];
    // State table for FSA accepting /__[A-Z0-9]+(_[A-Z0-9]+)*__/i
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
      else if (isalpha(c) || isdigit(c)) state = 3;
      else state = 0;
      break;
      
      case 3:
      if (c == '_') state = 4;
      else if (isalpha(c) || isdigit(c)) state = 3;
      else state = 0;
      break;
      
      case 4:
      if (c == '_')
      {
        NSString* loc = nil;
        NSInteger sublen = 1+i-start;
        NSRange r = NSMakeRange(start, sublen);
        NSString* sub = [s substringWithRange:r];
        if ([sub isEqualToString:@"__APPNAME__"]) loc = _appName;
        else if ([sub isEqual:@"__VERSION__"]) loc = _appVersion;
        else if ([sub isEqual:@"__LONG_VERSION__"]) loc = _appLongVersion;
        else loc = [self bestLocalizedString:sub];
        if (loc)
        {
          // Go forward or back depending on the size difference between capture
          // and replacement text.
          NSInteger delta = sublen - [loc length];
          len -= delta;
          i -= delta;
          [(NSMutableString*)localized replaceCharactersInRange:r
                                       withString:loc];
          s = (attr)? [(NSMutableAttributedString*)localized string]:
                      (NSString*)localized;
        }
        state = 0;
        start = 0;
      }
      else if (isalpha(c) || isdigit(c)) state = 3;
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
    NSFileManager* fm = [NSFileManager defaultManager];
    NSBundle* mb = [NSBundle mainBundle];
    NSEnumerator* iter = [_languages objectEnumerator];
    NSString* lang;
    BOOL gotIt = NO;
    while ((lang = [iter nextObject]) && !gotIt)
    {
      NSString* p = [mb pathForResource:@"Localizable" ofType:@"strings"
                        inDirectory:nil forLocalization:lang];
      NSDictionary* strings = [_cache objectForKey:p];
      if (!strings && [fm fileExistsAtPath:p])
      {
        strings = [[NSDictionary alloc] initWithContentsOfFile:p];
        if (strings)
        {
          [_cache setObject:strings forKey:p];
          [strings release];
        }
      }
      localized = [strings objectForKey:key];
      if (localized)
      {
        [[localized retain] autorelease];
        gotIt = YES;
      }
      if (!gotIt)
      {
        p = [mb pathForResource:@"Onizuka" ofType:@"strings"
                inDirectory:nil forLocalization:lang];
        strings = [_cache objectForKey:p];
        if (!strings && [fm fileExistsAtPath:p])
        {
          strings = [[NSDictionary alloc] initWithContentsOfFile:p];
          if (strings)
          {
            [_cache setObject:strings forKey:p];
            [strings release];
          }
        }
        localized = [strings objectForKey:key];
        if (localized)
        {
          [[localized retain] autorelease];
          gotIt = YES;
        }
      }
    }
  }
  return localized;
}

@end
