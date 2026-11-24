# openQA Needler

A utility to create and edit needles for openQA test suites.

##  Flatpak

Install the nightly build with Flatpak:

```sh
flatpak install --user https://cdn.kde.org/flatpak/openqa-needler-nightly/org.kde.needler.flatpakref
flatpak run org.kde.needler
```

The Flatpak can read and write needle directories in your home folder. For a checkout outside your home folder, grant access to that directory with `flatpak override --user --filesystem=/absolute/path/to/needles org.kde.needler`.

## Build and Installation Instructions

Can be built and installed with KDE Builder:
```
kde-builder openqa-needler
```
