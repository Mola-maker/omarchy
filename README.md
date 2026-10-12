# Omarchy web app local icon cleanup validation

Local SVG/XPM icons retain their extensions when `omarchy webapp install` copies them. The individual web app remover only deleted PNG files. The patch removes the exact generated PNG, SVG and XPM filenames while retaining both legacy PNG paths.

## Actual runtime

- Official Omarchy edge VM image `2026.10.12.442`, downloaded from nightly.omarchy.org and verified against SHA-256 `7ed0bd351861bce80c43434a9fb48fe6058dc12dbdb0bde2b14e59d7fe9d4110`.
- QEMU 10.2.1 with KVM, 4 CPUs, 4 GiB RAM; copy-on-write overlay, original image untouched.
- Omarchy `4.0.0.r6911.g9480d1b-1`, kernel `7.2.8-5-omarchy-bore`; complete installed package versions are in `dependencies.txt`.
- The original remover is the unmodified file from quattro commit `defbf90e893e741067e48f4a27d2ec694c71358e`. The candidate is the PR file, verified by matching SHA-256 inside and outside the guest.
- `verify-icons.sh` ran real installed web app installation, removal, file comparisons and desktop database updates in the native desktop session. It uses no command stubs. PNG, SVG and XPM icons were installed, removed, and checked alongside neighboring icons.
- Before: two residual SVG/XPM icons. After: zero residual icons; neighbors remain intact.
- `before.png` and `after.png` are unmodified native full-screen screenshots from `omarchy capture screenshot fullscreen save`. They show the live foot terminal and actual post-removal directory contents.

## Focused automated checks

- `test/shell.d/webapp-name-test.sh`: original code fails on SVG cleanup; candidate passes all nine assertions, including PNG/SVG/XPM round trips and preservation of neighbors and backups.
- `test/shell.d/webapp-install-test.sh`: nine assertions pass.
- `test/shell.d/webapp-install-escaping-test.sh`: five assertions pass.
- Complete `test/cli` passes with the expected GNU awk and Python command available.
- `bin/omarchy commands --check`: 509 commands; shell style, Bash syntax, and diff whitespace checks pass.
- Read-only independent code review found no blocking issue.

## Dependency setup

The official installed VM already provides git, GTK, desktop-file-utils, curl, jq, file, foot, grim and omasnap. No new runtime dependency is introduced by this patch. On the Ubuntu host, GNU awk 5.3.2 and libsigsegv2 were downloaded and extracted into an isolated workspace prefix; `awk` points to GNU awk and `python` points to the existing Python 3 executable. No global package or desktop configuration was changed.

Host CLI invocation:

```bash
PATH="$DEPENDENCY_PREFIX/bin:$PATH" \
LD_LIBRARY_PATH="$DEPENDENCY_PREFIX/usr/lib/x86_64-linux-gnu" \
OMARCHY_PATH="$OMARCHY_SOURCE" ./test/cli
```

The whole repository suite is not claimed green. The initial Ubuntu baseline encountered missing Quickshell/graphical tools and a namespace probe that blocked its output pipe. Targeted checks and the full CLI suite above completed separately; graphical verification ran in the disposable Omarchy guest.

Host paths in text logs are normalized. Screenshots and runtime results are not edited.

Candidate source commit: `28d84db99a532f7a67b821c63564ccc84b24c366`.
