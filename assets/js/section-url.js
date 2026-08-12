/**
 * Keeps the address bar in step with the visible section.
 *
 * The template is a section-swap layout: its nav handler calls preventDefault()
 * and toggles .section-show itself, so location never changes and whatever URL
 * the page was opened with stays frozen there. This rewrites it to the clean
 * paths that /resume, /about, /portfolio and /contact already redirect from.
 *
 * Must be loaded AFTER main.js: main.js reads location.hash on 'load' to decide
 * which section to open, so the hash has to survive until then.
 */
(function () {
  "use strict";

  var SECTIONS = ["about", "resume", "portfolio", "contact"];
  var suppress = false; // set while we drive a nav link ourselves

  function pathFor(hash) {
    var id = String(hash || "").replace(/^#/, "");
    return SECTIONS.indexOf(id) !== -1 ? "/" + id : "/";
  }

  function linkFor(path) {
    var id = String(path || "").replace(/^\/+|\/+$/g, "");
    var hash = SECTIONS.indexOf(id) !== -1 ? "#" + id : "#header";
    return document.querySelector('#navbar .nav-link[href="' + hash + '"]');
  }

  function writeUrl(hash, push) {
    if (!window.history || !history.replaceState) return;
    var url = pathFor(hash);
    if (location.pathname === url && !location.hash) return;
    try {
      history[push ? "pushState" : "replaceState"]({ section: hash || "" }, "", url);
    } catch (err) {
      /* cross-origin or file:// — leave the URL alone */
    }
  }

  // On load main.js has already consumed location.hash, so it is safe to
  // swap "/#resume" for "/resume". Registered after main.js's own listener,
  // which is why this file must come second in index.html.
  window.addEventListener("load", function () {
    writeUrl(location.hash, false);
  });

  // Nav clicks: let the template switch sections, then record it in the URL.
  document.addEventListener("click", function (e) {
    var link = e.target.closest ? e.target.closest("#navbar .nav-link") : null;
    if (!link || !link.hash || suppress) return;
    var hash = link.hash;
    setTimeout(function () {
      writeUrl(hash, true);
    }, 0);
  });

  // Back/forward: replay the corresponding nav link so the section follows,
  // without pushing another entry onto the stack.
  window.addEventListener("popstate", function () {
    var link = linkFor(location.pathname);
    if (!link) return;
    suppress = true;
    link.click();
    setTimeout(function () {
      suppress = false;
    }, 0);
  });
})();
