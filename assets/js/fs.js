fs = {
    readFile: function(path, options, callback) {
        flutter.fsOperation('readFile', path, options, callback);
    },
    writeFile: function(file, data, options, callback) {
        flutter.fsOperation('writeFile', file, data, options, callback);
    },
    unlink: function(path, callback) {
        flutter.fsOperation('unlink', path, callback);
    },
    readdir: function(path, options, callback) {
        flutter.fsOperation('readdir', path, options, callback);
    },
    mkdir: function(path, mode, callback) {
        flutter.fsOperation('mkdir', path, mode, callback);
    },
    rmdir: function(path, callback) {
        flutter.fsOperation('rmdir', path, callback);
    },
    stat: function(path, options, callback) {
        flutter.fsOperation('stat', path, options, callback);
    },
    lstat: function(path, options, callback) {
        flutter.fsOperation('lstat', path, options, callback);
    },
    readlink: function(path, options, callback) {
        flutter.fsOperation('readlink', path, options, callback);
    },
    symlink: function(target, path, type, callback) {
        flutter.fsOperation('symlink', target, path, type, callback);
    },
    chmod: function(path, mode, callback) {
        flutter.fsOperation('chmod', path, mode, callback);
    }
};
true;