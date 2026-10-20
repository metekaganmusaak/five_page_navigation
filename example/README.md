# five_page_navigation example

A showcase of the [five_page_navigation](https://pub.dev/packages/five_page_navigation) package.

- **Center page**: a D-pad that navigates with a `FivePageController`, a picker for every built-in transition and switches for previews, return buttons, swipe back and haptics.
- **Left page** (Profile): no `AppBar`; keeps its state while visible.
- **Right page** (Messages): an `AppBar` whose automatic back button returns to the center page.
- **Top page** (Notifications): a long list; swipe up from its lower part to go back.
- **Bottom page** (Discover): an `AppBar` and a bottom navigation bar; the return button is placed below the `AppBar`.

## Run

```sh
flutter run                # the default device
flutter run -d chrome      # web
flutter run -d macos       # or windows / linux
```

On desktop and web, drag from the edges with the mouse, use the D-pad, or press <kbd>Alt</kbd> + arrow keys (<kbd>Esc</kbd> returns to the center page).
