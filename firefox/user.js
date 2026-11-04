// Firefox prefs, applied to every profile at startup.
// These are re-applied on each launch, so UI changes to the same prefs do not
// stick -- change them here instead.

// Sidebar + vertical tabs, sidebar pinned to the right edge.
user_pref("sidebar.revamp", true);
user_pref("sidebar.verticalTabs", true);
user_pref("sidebar.position_start", false);
// Keep the launcher on screen; it flips to "hide-sidebar" if the sidebar is
// ever hidden from the View menu.
user_pref("sidebar.visibility", "always-show");
// Launcher tool buttons. Valid names only: aichat, syncedtabs, history,
// bookmarks. A bogus value here breaks the launcher.
user_pref("sidebar.main.tools", "history,bookmarks");
user_pref("browser.ml.chat.enabled", false);

// Compact toolbar density (the option is hidden in Customize unless shown).
user_pref("browser.compactmode.show", true);
user_pref("browser.uidensity", 1);

// Allow userChrome.css / userContent.css from the profile's chrome/ dir.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);

// Housekeeping.
user_pref("browser.aboutConfig.showWarning", false);
user_pref("browser.tabs.warnOnClose", false);
user_pref("browser.download.useDownloadDir", false);

// New tab page: no sponsored tiles, no Pocket stories, no sponsored
// suggestions in the address bar.
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
user_pref("browser.urlbar.suggest.quicksuggest.sponsored", false);

// Behaviour.
user_pref("browser.startup.page", 3);
user_pref("accessibility.typeaheadfind", true);
user_pref("browser.quitShortcut.disabled", false);
// HTTPS-First rather than HTTPS-Only: upgrade where possible, fall back to
// HTTP silently instead of an interstitial (internal hosts are HTTP).
user_pref("dom.security.https_only_mode", false);
user_pref("dom.security.https_first", true);
user_pref("media.autoplay.default", 5);

// Telemetry off.
user_pref("toolkit.telemetry.enabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("app.shield.optoutstudies.enabled", false);
