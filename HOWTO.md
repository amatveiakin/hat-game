## Compile

It should be possible to compile Android and iOS versions of the app with
a simple Flutter build.

To compile web version, first run:

    $ gen_index_html.sh

and then proceed with building as usual.

Also, changes to certain aspects of the app require additional recompilation
steps:

### built_value

In order to change anything under `lib/built_value`, run:

    $ flutter pub run build_runner build

to recompile once, or

    $ flutter pub run build_runner watch

to launch a deamon that watches for file changes and recompiles automatically.

### Icons

In order to change app icon:

1. Put the icon under `images/app_icon.png`
2. Run `flutter packages pub run flutter_launcher_icons:main` to update Android
   and iOS icons.
3. Update web icons. So far I've been doing this manually.


## Deploy

### Web

In order to deploy the web version, run:

    $ ./deploy_web.sh

The new version should be immediately accessible at https://hatgame.web.app.
