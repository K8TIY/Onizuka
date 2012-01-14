## This is Onizuka version 1.2

I named it for Onizuka Eikichi of the Japanese manga/anime/drama/film
GTO "Great Teacher Onizuka", which holds a special place in my heart.
I'm not sure I recall why I named it Onizuka -- maybe I was thinking GTO
could also stand for "Great Translator Onizuka".

### What can you do with this thing?

Onizuka does one-nib-many-languages localization. Which means you
have lots of Localizable.strings but only one MainMenu.xib and strings from
the former are inserted in the latter at runtime. Obviously, care must be
taken with item labels as they can suffer great length differences.
But I like this over Apple's current approach (massive redundancy violation
of SPOT rule: fundamental flaw) because I like stuff that generalizes.

To use the code, instantiate the singleton "Onizuka" and give it a window,
menu, or view to work on. The code recursively walks the view hierarchy and
localizes anything with a string value or title or label that looks like
`__BLAH_Blah_1__` (alphanumeric substrings separated by underscores,
and flanked by two underscores) if the placeholder title can be found in
Localizable.strings or the supplied Onizuka.strings.
It does this in a two-pass manner, so you can have strings file entries like
this:

  `"__BLAH__" = "Blah blah __BLEH__ __APPNAME__ __VERSION__";`  
  `"__BLEH__" = "Bleh";`  

Onizuka understands the special expressions `__APPNAME__` and `__VERSION__`
which are determined at runtime and do not need to be localized
(unless you want to).
Onizuka uses `CFBundleName` from Info.plist or the process info for
`__APPNAME__`, and `CFBundleShortVersionString` for `__VERSION__`.

Onizuka has a unique way of searching for localized strings: it searches
in order of user language preferences. For each language in this order, it
first looks in that language's Localizable.strings, and then its Onizuka.strings
(if available); if the localization can be found that is what is returned.
This allows you to do partial localizations, so long as you have at least one
full localization. (In an ideal world maybe you would always do full
localizations for every supported language, but if you write free software maybe
you have to rely on translations trickling in from generous donors. Or maybe
you're like me, and you sometimes put together an en_GB localization that just
lists the dozen or so differences between American and British spellings.
With Onizuka you can do that. I use that technique in my IPA Palette software
["velarised" vs "velarized"] and have had no complaints about it from anyone.)

Some container classes -- or those with a special accessor for cells or
subviews -- possibly are not covered by the current code. Submissions welcome.
I'd like to avoid diving into undocumented methods but it may be inevitable....

Included is a MainMenu.nib on or from which you can base standard application
menus. I think I've got them all wired up to First Responder, but in order to
paste the menu into a new nib you have to copy BOTH the Main Menu and the First
Responder, otherwise the connections get broken.

Because XCode has such a weird (broken) workflow for making files localizable,
I recommend selecting the StandardUI directory and dragging it into the files
section of the XCode interface. It worked for me on Leopard, haven't tried it on
Snow yet.

### What's new in 1.2?

* Onizuka now caches the `.strings` files for faster subsequent lookups,
and makes public a method to clear the cache when you are (more or less) done
using it.

### What's new in 1.1?

* Onizuka can handle localizing parts of attributed strings
(like in an NSTextView).

### Todo

* More basic Onizuka.strings and StandardUI localizations.
Can someone help me with these? Like oatmeal, it's the "right thing to do."

### Bugs

* I detect NSPathControl explicitly and suppress doing any attributed string
 stuff with it. It's not pretty but it works.
