pragma Singleton

// Pragma on the first line, before the comment - reason in Icons.qml.

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
//  PROGRAM ICON FROM A .desktop ENTRY - for Arsenal slots.
//
//  Order of attempts:
//
//    1. Icon from the entry (Icon=). The name is resolved by the shell's icon theme -
//       Papirus-Dark, set with the IconTheme pragma in shell.qml - together
//       with the themes it inherits from and the pixmaps directories that Quickshell itself
//       adds to the fallback paths. That is where e.g. the VS Code icon lives.
//       An absolute path goes straight to the file.
//
//    2. CATEGORY icon from the theme. For programs whose icon does not exist
//       anywhere on the system: yazi has Icon=yazi, the VTE terminal
//       Icon=org.gnome.Terminal, and no installed theme contains
//       such files.
//
//    3. Generic program icon. Only when that one is missing too do we return an empty
//       string, and the tile shows its own glyph.
//
//  Why not Quickshell.iconPath() directly: without an icon theme set, Qt
//  searches only in hicolor and loses everything that exists only in a full
//  theme such as breeze - the Konsole terminal, system settings, system
//  monitor, printers.
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

import Quickshell

Singleton {
    // The FIRST category from the list that the entry has wins, so specific
    // ones come before generic ones: yazi is both FileManager and Utility, and should
    // get the file manager icon. Every name checked in breeze.
    readonly property var categoryIcons: [
        ["TerminalEmulator", "utilities-terminal"],
        ["FileManager", "system-file-manager"],
        ["WebBrowser", "internet-web-browser"],
        ["TextEditor", "accessories-text-editor"],
        ["Settings", "preferences-system"],
        ["Development", "applications-development"],
        ["Game", "applications-games"],
        ["AudioVideo", "applications-multimedia"],
        ["Audio", "applications-multimedia"],
        ["Video", "applications-multimedia"],
        ["Graphics", "applications-graphics"],
        ["Network", "applications-internet"],
        ["Office", "applications-office"],
        ["Education", "applications-education"],
        ["Science", "applications-science"],
        ["System", "applications-system"],
        ["Utility", "applications-utilities"]
    ]

    function path(entry: var): string {
        if (!entry) return "";

        const icon = entry.icon;
        if (icon !== "") {
            if (icon.startsWith("/")) return "file://" + icon;

            // "true" = empty string instead of Qt's fallback icon, so that we can
            // move on to the next attempt.
            const own = Quickshell.iconPath(icon, true);
            if (own !== "") return own;
        }

        const categories = entry.categories;
        for (const [category, name] of categoryIcons) {
            if (categories.indexOf(category) === -1) continue;
            const byCategory = Quickshell.iconPath(name, true);
            if (byCategory !== "") return byCategory;
        }

        return Quickshell.iconPath("application-x-executable", true);
    }
}
