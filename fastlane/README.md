fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios tests

```sh
[bundle exec] fastlane ios tests
```

Roda os testes do iOS

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Captura screenshots em todos os dispositivos e idiomas

### ios certificates

```sh
[bundle exec] fastlane ios certificates
```

Sincroniza certificados e provisioning profiles

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build e upload para TestFlight (beta)

### ios release

```sh
[bundle exec] fastlane ios release
```

Build e publicação na App Store

----


## Android

### android tests

```sh
[bundle exec] fastlane android tests
```

Roda os testes unitários

### android screenshots

```sh
[bundle exec] fastlane android screenshots
```

Captura screenshots via Espresso

### android beta

```sh
[bundle exec] fastlane android beta
```

Build e upload para Google Play (internal track)

### android release

```sh
[bundle exec] fastlane android release
```

Build e publicação no Google Play (production)

### android promote

```sh
[bundle exec] fastlane android promote
```

Promove internal para production sem novo build

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
