## Compile

After cloning the repository before compiling the app for the first time, run

    $ ./init_repo.sh

Afterwards use the normal Flutter build proccess in order to compile the app.

Changes to certain aspects of the app require additional recompilation steps:

### built_value

In order to change anything under `lib/built_value`, run:

    $ dart run build_runner build

to recompile once, or

    $ dart run build_runner watch

to launch a deamon that watches for file changes and recompiles automatically.

### Icons

In order to change app icon:

1. Put the icon under `images/app_icon.png`
2. Run `flutter packages pub run flutter_launcher_icons:main` to update Android
   and iOS icons.
3. Update web icons. So far I've been doing this manually.


## Deploy

Before releasing the app anywhere, update the version:

    $ ./update_git_version.sh

### Install on Android via USB

1. Make sure USB debugging is enabled on the device.
2. Run `flutter build apk`.
3. Run `flutter devices` to find out the device id.
4. Run `flutter install -d <device-id>`.

### Web

In order to deploy the web version, run:

    $ ./deploy_web.sh

This script calls `update_git_version.sh` internally, so there is no need to
run it manually.

The new version should be immediately accessible at https://hatgame.web.app.
