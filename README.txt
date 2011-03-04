This code is named for Onizuka Eikichi of the Japanese manga/anime/drama/film
GTO "Great Teacher Onizuka", which holds a special place in my heart.
I'm not sure I recall why I named it Onizuka -- maybe I was thinking GTO
could also stand for "Great Translator Onizuka".

Anyway, this code is for one-nib-many-languages localization. Which means you
have lots of Localizable.strings but only one MainMenu.nib and strings from
the former are inserted in the latter at runtime. Obviously, care must be
taken with item labels as they can suffer great length differences.
But I like this over Apple's current approach (massive redundancy violation
of SPOT rule: fundamental flaw) because I like stuff that generalizes.

To use the code, instantiate the singleton "Onizuka" and give it a window,
menu, or view to work on. The code recursively walks the view hierarchy and
localizes anything with a string value or title or label that looks like
__BLAH_BLAH__ (uppercase alphabetic substrings separated by underscores,
and flanked by two underscores) if the placeholder title can be found in
Localizable.strings or the supplied Onizuka.strings.
It does this in a two-pass manner, so you can have strings file entries like this:

"__BLAH__" = "Blah blah __BLEH__ __APPNAME__ __VERSION__";
"__BLEH__" = "Bleh";

Onizuka understands the special expressions __APPNAME__ and __VERSION__ which
are determined at runtime and do not need to be localized (unless you want to).
Onizuka uses the CFBundleName from Info.plist or the process info for
__APPNAME__, and CFBundleShortVersionString for __VERSION__.

Some container classes -- or those with a special accessor for cells or
subviews -- probably are not covered by the current code. Submissions welcome.
Tool tips for cells in an NSMatrix are particularly problematic. I'd like to avoid
diving into undocumented methods but it may be inevitable....

Included is a MainMenu.nib on or from which you can base standard application
menus. I think I've got them all wired up to First Responder, but in order to
paste the menu into a new nib you have to copy BOTH the Main Menu and the First
Responder, otherwise the connections get broken.

Because XCode has such a weird (broken) workflow for making files localizable,
I recommend selecting the StandardUI directory and dragging it into the files
section of the XCode interface. It worked for me on Leopard, haven't tried it on
Snow yet.

