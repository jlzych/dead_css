(function() {
  if (document.styleSheets) {
    var stylesheets = document.styleSheets,
        $elements = [],
        i = 0,
        j = 0,
        numRules = 0;
        numStylesheets = stylesheets.length,
        rules = [],
        unusedRules = [];

    for (i; i < numStylesheets; i++) {
      rules = stylesheets[i].rules;
      rules = (rules) ? rules : []; // rules is sometimes null

      numRules = rules.length;

      for (j = 0; j < numRules; j++) {
        var selectorText = removePseudoSelectors(rules[j].selectorText);
        try {
          $elements = $(selectorText);
        }
        catch (e) {
          $elements = [];
        }

        if ($elements.length === 0) {
          unusedRules.push({
            stylesheet: stylesheets[i],
            rule: rules[j],
            selector: rules[j].selectorText
          });
        }
      } // j for
    } // i for
    return unusedRules;
  }

  function removePseudoSelectors(selector) {
    var selectors = selector.split(",");
    var finalSelectors = [];
    var blacklistedSelectors = [
      ":active",
      ":after",
      ":before",
      ":focus",
      ":hover",
      ":link",
      ":target",
      ":visited"].join("|");

    for (var i = 0; i < selectors.length; i++) {
      if (!selectors[i].match(blacklistedSelectors)) {
        finalSelectors.push(selectors[i]);
      }
    }

    if (selectors.length != finalSelectors.length)
      console.log({ before: selector, after: finalSelectors.join(",") });

    return finalSelectors.join(",");
  }
}
)();

/**
 * False positives to think about:
 *
 * pseudo-state selectors, :hover, :focus, etc.
 * pseudo-element selectors, ::after, ::before
 * what about :not(), :last-child, :first-child, etc.?
 */
