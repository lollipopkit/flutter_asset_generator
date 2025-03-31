# flutter_asset_generator

Automatically generate the dart file for pubspec.yaml

## Usage

### Run

`pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_asset_generator:
    git:
      url: https://github.com/lollipopkit/flutter_asset_generator
      ref: master
```

```bash
dart run flutter_asset_generator
```

### Support options

```bash
-o, --output             Output resource file path
-s, --src                Flutter project root path
                         (defaults to ".")
-n, --name               The generated class name
-w, --[no-]watch         Monitor changes after execution of orders.
-p, --preview            Enable preview comments
-r, --replace_strings    Enable replace strings ('assets/image.png' -> 'R.ASSETS_IMAGE_PNG')
                         (defaults to false)
-d, --debug              debug mode
-h, --help               Print this usage information.
```

### Exclude and include rules

The file is yaml format, every element is `glob` style.
The name of the excluded file is under the `exclude` node, and the type is a string array. If no rule is included, it means no file is excluded.
The `include` node is the name of the file that needs to be imported, and the type is a string array. If it does not contain any rules, all file are allowed.


### Configs

```yaml
watch: false
# watch: true

# Whether to generate preview comments in the generated file.
# eg.: /// ![preview](file:///path/to/file.jpg)
preview: false

output: lib/const/r.dart
# output: lib/const/resource.dart

name: RRR

# replace all assets strings to the vars defined in the generated file
replace: true
```

### Replacement Rules

File names can be replaced according to the configuration file as shown below:

```yaml

replace:
  - from: “
    to: 
  - from: ”
    to: 
  - from: ’
    to:
  - from: (
    to:
  - from: )
    to:
  - from: "!"
    to:
```

#### Example

```yaml
exclude:
  - "**/add*.png"
  - "**_**"

include:
  - "**/a*.png"
  - "**/b*"
  - "**/c*"
```

```sh
assets
├── address.png           # exclude by "**/add*.png"
├── address@at.png        # exclude by "**/add*.png"
├── bluetoothon-fjdfj.png
├── bluetoothon.png
└── camera.png

images
├── address space.png     # exclude by "**/add*.png"
├── address.png           # exclude by "**/add*.png"
├── addto.png             # exclude by "**/add*.png"
├── audio.png
├── bluetooth_link.png    # exclude by **_**
├── bluetoothoff.png
├── child.png
└── course.png
```

```dart
class R {
  const R._();

  /// ![preview](file:///Users/jinglongcai/code/dart/self/flutter_resource_generator/example/assets/bluetoothon-fjdfj.png)
  static const String ASSETS_BLUETOOTHON_FJDFJ_PNG = 'assets/bluetoothon-fjdfj.png';
}
```

## Config file

The location of the configuration file is conventional.
Configuration via commands is **not supported**.
The specified path is `fgen.yaml` in the flutter project root directory.

### Config schema for vscode

Install [YAML Support](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml) plugin.

Config your vscode `settings.json` file.

It can be used to prompt the configuration file.

```json
{
  "yaml.schemas": {
    "https://raw.githubusercontent.com/fluttercandies/flutter_asset_generator/master/fgen_schema.json": ["fgen.yaml"]
  }
}
```