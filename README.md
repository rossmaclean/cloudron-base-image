This is the base image used for all docker containers in the Cloudron.

## Building

    docker build -t cloudron/base:<tag> .

## Pushing

    docker push cloudron/base:<tag>

*WARNING*: Don't do `docker push cloudron/base` since this will
push the latest tag as well.

## Notes

### Locales

https://wiki.archlinux.org/index.php/locale

locales contain various locale specific information. the locale db is in text format
and has to be "generated" (compiled) using locale-gen tool to be used.

the locale-gen generates the locales specified in `/etc/locale.gen` (apparently, some old
locale-gen used to take it as argument).

`locale -a` gives list of locales that are installed and ready to use. `update-locale LANG=en_US.utf8`
pretty much sets the `/etc/default/locale` file. Simply running `locale` displays current set locale.

list of all avaiable locales is at /usr/share/i18n/SUPPORTED. so one can copy over that
SUPPORTED file into locale.gen and run `locale-gen` to compile everything.

on ubuntu, locales-all contains all the pre-compiled info thankfully. all the things are in
/usr/lib/locale. locale -a will show all locales as well.

`/etc/default/locale` contains the system default locale.

The are packages of the form `language-pack-*` in ubuntu, but those also provide translations.

