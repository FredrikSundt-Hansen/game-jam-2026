# Santa's Coal Dodge

A retro 2D arcade game built with Godot 4.7, exported as an HTML5 web application.
Santa slides on ice in a square arena, dodging coal thrown by angry children while delivering gifts to his sleigh.

## Requirements

- [Godot 4.7](https://godotengine.org/download) (standard build, GL Compatibility renderer)
- Web export templates, installed via **Editor > Manage Export Templates**
- A modern browser to play the exported build

## Run

1. Open the project folder in Godot (`project.godot`).
2. Press **F5** to run. The game starts at the main menu.

## Controls

| Key | Action |
| --- | --- |
| Arrow keys | Move Santa |
| Enter / Space | Confirm, restart |
| F11 | Toggle fullscreen |

## Export for the web

1. Open **Project > Export** and select the **Web** preset (already configured).
2. Set the export path to `export/index.html`, outside the project folder.
3. Click **Export Project**.
4. Serve the output over HTTP. Opening `index.html` directly from disk will not work:

   ```sh
   cd export
   python3 -m http.server 8000
   ```

   Then open <http://localhost:8000>.

To export from the command line instead, run:

```sh
./export.sh
```

It looks for `godot` on the `PATH` or in `/Applications/Godot.app`; set `GODOT=/path/to/godot` to override. It writes to `export/` inside the project, which is git-ignored.

The exported files can be hosted on any static host, such as itch.io (upload as a zip with `index.html` at its root) or GitHub Pages.
