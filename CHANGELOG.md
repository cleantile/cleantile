## Unreleased

### Modified

- Improved initialization of `<cleantile-pane>` and `<cleantile-tabs>`:
  - Added extra sanity checks
  - Modified sanity checks to throw errors where errors couldn't be corrected later
  - Fixed cross-platform load order, which caused silent failures in testing. See details in #7 
    ([comment](https://github.com/cleantile/cleantile/issues/7#issuecomment-271100384)) for more details.

## 0.1.0 - 2017-01-02

First release.

### Added

- `<cleantile-container>` placeholder
- `<cleantile-pane>`, `<cleantile-tabs>`, `<cleantile-tab>` prototype
- `<cleantile-split>` placeholder (default width, not movable)
- `CleanTile.ViewBehavior` prototype
