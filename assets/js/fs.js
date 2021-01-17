fs = {
    readFile: function(path, options, callback) {
        flutter.fsOperation('readFile', path, options, callback);
    },
    writeFile: function(file, data, options, callback) {
        if (data instanceof ArrayBuffer)
            data = new Uint8Array(data);  // flutter_jscore only provides APIs for working with typed arrays, so we need to wrap raw array buffers
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
    },
    createFileStat: function(isDir, size, mtimeMs) {
        return {
            isDir: isDir,
            size: size,
            ino: 1,   // I'm not sure if it's safe to not set an inode here
            uid: 1,
            gid: 1,
            dev: 1,
            mtimeMs: mtimeMs,
            mode: 0,
            isDirectory: function () { return this.isDir; },
            isFile: function() { return !this.isDir; },
            isSymbolicLink: function() { return false; }
        };
    }
};
// I'm having problems with isomorphic-git's use of Promise.all when
// it calls simultaneously into 
async function sequentialPromiseAll(arr) {
    var result = [];
    var it = arr[Symbol.iterator]();
    for (var next = it.next(); !next.done; next = it.next()) {
        flutter.log('in');
        result.push(await next.value);
        flutter.log('out');
    }
    return result;
}

function promisify(fn) {
    return function(...args) {
        return new Promise(function(resolve, reject) {
            args.push(function(err, val) {
                if (err) reject(err);
                else resolve(val);
            });
            Reflect.apply(fn, this, args);
        });
    }
}
async function tester()
{
    flutter.log('start');
    var testfn = promisify(fs.readFile);
    var writefn = promisify(fs.writeFile);
    var readfn = promisify(fs.readFile);
    // var arr = new Uint8Array(5000000);
    // await writefn('bigfile2', arr);
    // await readfn('bigfile2');
    var files = ['a', 'bigfile', 'c', 'd', 'e', 'f', 'g', 'bigfile2', 'i', 'j','k', 'l'];
    // for (var n = 0; n < files.length; n++) {
    //     try {
    //         var s = await fs.readdir(files[n]);
    //     } catch (err) {
    //     }
    // }

    sequentialPromiseAll(files.map(async function(val) {
        try {
         await testfn(val);
        } catch (err) { return null}
        return 1;
    }));

    // for (var n = 0; n < files.length; n++) {
    //     try {
    //         await testfn(files[n]);
    //     } catch (err) {
    //     }
    // }
}
true;