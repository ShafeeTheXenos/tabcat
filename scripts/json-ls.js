// print paths from a json file. This supports computing makefile dependencies
// and making cache manifests.
//
// usage: node json-ls.js <levels> [ <file1> [ <file2> ... ] ]
//
// levels tells us what field(s) to look in for filenames.
//
// Examples:
//
// attachments+modules: print contents of attachments and modules field
// /attachments: print paths in attachments field, relative to input file
// tabcat.icon: look in <input data>.tabcat.icon
fs = require('fs');
path = require('path');


if (process.argv.length > 2) {
    var levels = process.argv[2].split('+');
} else {
    var level = [];
}

if (process.argv.length > 3) {
    inputPaths = process.argv.slice(3);
} else {
    inputPaths = [''];
}


var printed = false;

var printAtLevel = function(data, level, dirName) {
    // handle level as string from the command line
    if (typeof level == 'string') {
        if (!level) {
            level = [];
            dirName = null;
        } else {
            if (level[0] == '/') {
                level = level.substring('1');
            } else {
                dirName = null;
            }
            level = level.split('.');
        }
    }

    if (Array.isArray(data)) {
        data.forEach(function (item) {
            printAtLevel(item, level, dirName);
        });
    } else if (level.length > 0) {
        if (data != null) {
            printAtLevel(data[level[0]], level.slice(1), dirName);
        }
    } else if (typeof data == 'string') {
        if (printed) {
            // don't put a newline before the first item
            process.stdout.write('\n')
        }
        if (dirName) {
            data = path.join(dirName, data);
        }
        process.stdout.write(data);
        printed = true;
    }
};

inputPaths.forEach(function(inputPath) {
    var data = JSON.parse(fs.readFileSync(inputPath || '/dev/stdin', 'utf8'));
    levels.forEach(function(level) {
        printAtLevel(data, level, path.dirname(inputPath));
    });
});
