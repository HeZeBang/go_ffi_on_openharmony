# Go FFI on OpenHarmony

A minimal template showing how to call a Go shared library (`.so`) from a Flutter app
via `dart:ffi` on OpenHarmony.

| Side | Where | What |
|---|---|---|
| Go | `native/golib/` | a tiny `-buildmode=c-shared` library exporting `GoSum` and `GoGreeting` |
| Flutter | `lib/golib.dart` | `dart:ffi` bindings for the library |
| Demo | `lib/main.dart` | calls the Go functions on startup and prints the result |

A **prebuilt `libgolib.so` is committed** under `ohos/entry/libs/arm64-v8a/`, so the app
runs out of the box. It can be rebuilt from `native/golib/` (see [Building](#building)).

## Why this template exists

Go's `-buildmode=c-shared` output does **not** dlopen on OpenHarmony when built with the
older `go1.22.x` OpenHarmony fork: the runtime accesses `runtime.tls_g` with the
**initial-exec (IE) TLS** model, and OpenHarmony's musl loader rejects
`R_AARCH64_TLS_TPREL64` relocations:

```
initial-exec TLS resolves to dynamic definition in .../libgolib.so
```

You **must** use **`go1.24.5.ohosv1r1`** (or newer) from the OpenHarmony SIG fork. That
release enables the **general-dynamic (GD) TLS** model for `c-shared` on
`openharmony/arm64`, so the relocations become `R_AARCH64_TLSDESC` and dlopen works.
This corresponds to upstream Go issue [#13492](https://github.com/golang/go/issues/13492).

## Prerequisites

### 1. Go toolchain — OpenHarmony fork (required)

The regular upstream Go has no `openharmony` target; use the OpenHarmony SIG fork.

```bash
git clone --depth 1 --branch go1.24.5.ohosv1r1 \
  https://gitcode.com/openharmony-sig/ohos_golang_go.git ~/dev/ohos_golang_go
cd ~/dev/ohos_golang_go/src
GOROOT_BOOTSTRAP=$(go env GOROOT) ./make.bash          # any working Go as bootstrap
~/dev/ohos_golang_go/bin/go tool dist list | grep openharmony   # → openharmony/arm64
```

Add it to your PATH (or `direnv`/`.envrc`):

```bash
export GOROOT="$HOME/dev/ohos_golang_go"
export PATH="$GOROOT/bin:$PATH"
```

> ⚠️ The older gitee fork (`go1.22.10`) still produces a `.so` that fails at dlopen with
> the IE-TLS error above. Always build with `go1.24.5.ohosv1r1`+.

### 2. OpenHarmony SDK (command-line-tools)

Provides `hdc` (device tool), `hvigor` (build), and the LLVM cross-compiler
`native/llvm/bin/aarch64-unknown-linux-ohos-clang` used to build the `.so`.

Set `hwsdk.dir` in `ohos/local.properties` to your SDK root.

### 3. Flutter with OpenHarmony support

A Flutter SDK built for `ohos` targets (e.g. the `flutter ...-ohos` fork), plus the
`ohos` platform tooling. Run `flutter pub get` first.

## Project layout

```
native/golib/                             Go c-shared library (source + prebuilt .so/.h)
lib/golib.dart                            dart:ffi bindings
lib/main.dart                             demo UI; calls Go on startup
ohos/                                     OpenHarmony app (bundleName com.example.goffi)
ohos/entry/libs/arm64-v8a/libgolib.so     prebuilt .so packaged into the HAP
```

## Building

### 1. (Re)build the Go `.so`

```bash
cd native/golib
export CC=$HOS_SDK_HOME/native/llvm/bin/aarch64-unknown-linux-ohos-clang
GOOS=openharmony GOARCH=arm64 CGO_ENABLED=1 go build -buildmode=c-shared -o libgolib.so .
cp libgolib.so ../../ohos/entry/libs/arm64-v8a/libgolib.so

# sanity check: TLS must be general-dynamic (TLSDESC), not initial-exec
readelf -Wr libgolib.so | grep TLS      # expect: R_AARCH64_TLSDESC
```

### 2. Build & run the app

```bash
flutter pub get
cd ohos && ohpm install && cd ..
flutter run -d <device-id>
# or, to build only:
flutter build hap --debug
```

## Signing

A HAP must be signed to install on a device. `ohos/build-profile.json5` ships with an
**empty `signingConfigs`** — configure your own signing before `flutter run`:

- **DevEco Studio** — Project Structure → Signing Configs → *Automatically generate
  signature*.
- **Manual** — fill `signingConfigs` with your `.p12` / `.cer` / `.p7b` materials.

> Newer SDKs' `hvigor` signing expects an encrypted-password + `material/` directory
> layout. If `flutter run` fails with `stat .../signature/material`, sign the HAP
> manually with the SDK's `hap-sign-tool.jar` (`sign-app -mode localSign ...`; note
> `-appCertFile` must be the **full certificate chain**), then `hdc install` the signed
> HAP.

## Result

On launch, `lib/main.dart` calls `GoSum(3, 4)` and `GoGreeting()` and logs:

```
GOFFI|OK|Go FFI OK: GoSum(3,4)=7, GoGreeting()="Hello from Go on OpenHarmony!"
```

View it with:

```bash
hdc shell hilog | grep GOFFI
```

(The result is also shown in the app UI, and logged via `dart:developer`.)
