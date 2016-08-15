#!/usr/bin/env node

'use strict';

var program = require('commander'),
    execSync = require('child_process').execSync,
    fs = require('fs'),
    path = require('path'),
    replace = require('replace'),
    semver = require('semver'),
    shell = require('shelljs'),
    util = require('util');

require('colors');

var PARENT_DIR = path.resolve(__dirname, '../..');
var baseVersion = '0.1.0';

program.version('0.0.1');

program.command('apps')
    .description('Rebase apps')
    .action(rebaseApps);

program.command('addons')
    .description('Rebase addons')
    .action(rebaseAddons);

program.parse(process.argv);

if (!process.argv.slice(2).length) {
    program.outputHelp();
}

function shellExec(args) {
    var result = shell.exec(args);
    if (result.code === 0) return true;

    console.log((args + ' failed').red);
    return false;
}

function rebase(app, appName, isApp) {
    var appDir = path.join(PARENT_DIR, app);

    shell.cd(appDir);
    var result = shell.exec('git stash && git fetch origin && git rebase origin/master', { silent: true });
    if (result.code !== 0) {
        console.log((app + ' is not in git repo. skipping').yellow);
        return false;
    }

    if (!fs.existsSync('Dockerfile')) {
        console.log((app + ' has no Dockerfile').red);
        return false;
    }

    if (shell.grep('girish/base:' + baseVersion, 'Dockerfile')) {
        console.log((app + ' is already rebased. skipping').yellow);
    } else {
        console.log((app + ' is worthy').green);

        replace({ regex: 'FROM girish/base.*', replacement: 'FROM girish/base:' + baseVersion, paths: [ 'Dockerfile' ], silent: true });

        var latestTag = shell.exec('git describe --tags --abbrev=0').output.trim();
        var latestVersion = latestTag.substr(1); // remove the 'v'
        if (!semver.valid(latestVersion)) latestVersion = '0.' + latestVersion; // 0.x -> 0.0.x
        var nextVersion = semver.inc(latestVersion, 'minor');

        var imageName = 'girish/' + appName + ':' + nextVersion;

        console.log('Building ', imageName);

        if (!shellExec('docker build -t ' + imageName + ' .')) return false;
        if (!shellExec('docker push ' + imageName)) return false;

        if (isApp) {
            var manifest = JSON.parse(fs.readFileSync('CloudronManifest.json', 'utf8'));
            manifest.dockerImage = imageName;
            manifest.version = nextVersion;
            fs.writeFileSync('CloudronManifest.json', JSON.stringify(manifest, null, 2));
        }

        if (!shellExec('git commit -a -m "Rebase to girish/base:' + baseVersion + '"')) return false;
        if (!shellExec('git tag -f v' + nextVersion + ' -a -m "Version ' + nextVersion + '"')) return false;
        if (!shellExec('git push origin master --tags')) return false;
        if (isApp && !shellExec('cloudron publish')) return false;
    }

    return true;
}

function rebaseApps() {
    var apps = fs.readdirSync(PARENT_DIR).filter(function (file) { return /-app$/.test(file); });
    var failed = [ ];
    apps.forEach(function (app) {
        var appName = app.replace(/-app$/, '');
        if (!rebase(app, appName, true /* isApp */)) failed.push(app);
    });

    if (failed.length !== 0) console.log(util.format('Failed: %j', failed).red);
}

function rebaseAddons() {
    var addons = fs.readdirSync(PARENT_DIR).filter(function (file) { return /-addon$/.test(file); });
    var failed = [ ];
    addons.forEach(function (addon) {
        var addonName = addon.replace(/-addon$/, '');
        if (!rebase(addon, addonName, false /* isApp */)) failed.push(addon);
    });

    if (failed.length !== 0) console.log(util.format('Failed: %j', failed).red);
}

