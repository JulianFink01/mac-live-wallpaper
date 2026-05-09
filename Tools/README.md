# Tools

`generate_app_icon.swift` creates the deterministic local app icon assets used by the Xcode project.

Run it from the project root:

```sh
swift Tools/generate_app_icon.swift
```

The script writes PNGs into:

- `LiveWallpaper/Assets.xcassets/AppIcon.appiconset/`
- `LiveWallpaper/Assets.xcassets/MenuBarIcon.imageset/`
