// Meet Link Bouncer.
//
// Intercepts clicks on links inside meet.google.com. If the target URL is
// NOT on meet.google.com itself, prevent the default (which would open a
// new Chrome tab) and instead hand the URL to Hammerspoon via the
// `hammerspoon://open-external?url=…` scheme. Hammerspoon then routes
// through urlhandler.lua, which sends the URL to the system default
// browser -- Firefox.
//
// One-time setup: Chrome asks "Open Hammerspoon?" on the first bounce.
// Check "Always allow meet.google.com to open links of this type", click
// Open, and it stays silent after.

(function () {
    "use strict";

    // Fire a hammerspoon:// URL without disturbing the Meet tab. Using a
    // hidden iframe means the navigation attempt happens in the iframe --
    // Chrome hands the scheme off to the OS and the Meet tab's own
    // location never changes. We remove the iframe shortly after so nothing
    // accumulates in the DOM.
    function bounce(url) {
        const bouncer = `hammerspoon://open-external?url=${encodeURIComponent(url)}`;
        const iframe = document.createElement("iframe");
        iframe.style.display = "none";
        iframe.src = bouncer;
        document.body.appendChild(iframe);
        setTimeout(() => iframe.remove(), 500);
    }

    // Decide whether a URL should be handled by Meet (stay in Chrome) or
    // bounced externally.
    function shouldBounce(href) {
        let url;
        try {
            url = new URL(href, document.baseURI);
        } catch (_) {
            return false;
        }
        if (!url.protocol.startsWith("http")) return false;   // mailto, tel, javascript, …
        if (url.host === document.location.host) return false; // relative Meet link
        if (url.host.endsWith("meet.google.com")) return false;
        return true;
    }

    // Capture phase so we beat Meet's own click handlers. Meet marks many
    // links target="_blank" which routes through window.open — click still
    // fires first, so preventDefault + stopPropagation is sufficient.
    document.addEventListener(
        "click",
        (ev) => {
            const a = ev.target.closest?.("a[href]");
            if (!a) return;
            const href = a.href;
            if (!href || !shouldBounce(href)) return;

            ev.preventDefault();
            ev.stopPropagation();
            bounce(href);
        },
        true, // capture
    );

    // Some Meet widgets call window.open directly. Wrap it so those get
    // bounced too.
    const origOpen = window.open;
    window.open = function (url, ...rest) {
        if (typeof url === "string" && shouldBounce(url)) {
            bounce(url);
            return null;
        }
        return origOpen.call(this, url, ...rest);
    };
})();
