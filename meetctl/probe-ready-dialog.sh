#!/bin/bash
# Dump elements in the "Your meeting's ready" dialog so we can find its
# close button. Run this while the dialog is visible in Meet.

exec meetctl eval '
(function(){
    // Look for anything containing "meeting" + "ready" text; then dump
    // the subtree around it, especially close/dismiss buttons.
    const all = Array.from(document.querySelectorAll("*"));
    const dialog = all.find(el => {
        const t = (el.textContent || "").toLowerCase();
        return t.includes("your meeting") && t.includes("ready") && t.length < 300;
    });
    if (!dialog) return {error: "no ready dialog found"};

    // Collect close-ish buttons in the dialog subtree.
    const closeButtons = Array.from(dialog.querySelectorAll("[aria-label], [role=button], button"))
        .filter(el => {
            const label = (el.getAttribute("aria-label") || "").toLowerCase();
            const role  = el.getAttribute("role") || "";
            return /close|dismiss|hide|no thanks|got it|cancel/.test(label);
        })
        .map(el => ({
            tag: el.tagName,
            role: el.getAttribute("role") || "-",
            ariaLabel: el.getAttribute("aria-label") || "-",
            text: (el.textContent || "").trim().slice(0, 40),
        }));

    return {
        dialogText: (dialog.textContent || "").trim().slice(0, 200),
        closeButtons,
    };
})()'
