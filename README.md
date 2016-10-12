Snark-proto
===========

Prototype snark transpiler with extremely naive implementation.

## Limitation

Snark-proto is not a full-featured Snark compiler implementation, and it can only handle a subset of well-formed Snark codes. This repository is also an example of the minimal-yet-usable real code compiler.

## Usage

```
$ npm install --global snark-proto
$
$ snark-proto source.snark [-o result.js]
```

## Development

```
$ git clone https://github.com/HyeonuPark/snark-proto.git
$ cd snark-proto
$ npm install
$ npm run build
$
$ npm test                  # execute all tests with mochajs
$ npm run print <test-name> # compile matching test code and print readable output
```

## License

Copyright (c) 2016 Hyeonu Park


Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
