# Omarchy clipboard text preservation: native validation

The original `omarchy-clipboard-open` strips all trailing LF bytes when decoded text is assigned with Bash command substitution. The clipboard history itself is correct; the temporary file handed to the editor is truncated.

The fix retains the JSON-encoded text until writing the editor file with `jq -j`. URL detection still uses decoded text. No runtime dependency is added.

## Source and environment

- Upstream base: `f5006bd41a1755d46e0a4f2c0c4c54fca703cd9b` (`quattro`).
- Fix commit: `fb6c902d9208fdafea94b997bdb1600ede590651`.
- Official disposable Omarchy edge image: `omarchy-edge-2026.10.12.442.qcow2`.
- Image SHA256: `7ed0bd351861bce80c43434a9fb48fe6058dc12dbdb0bde2b14e59d7fe9d4110`.
- Booted with the repository's VM harness using QEMU/KVM, 4 CPUs and 4 GiB RAM; this is an actual Arch Linux/Hyprland/Quickshell session.
- `dependencies.txt` records installed package versions. Node 26.11.1 is installed through mise, rather than the Arch `nodejs` package. Ubuntu CLI validation uses a separately installed/extracted gawk dependency prefix; `host-dependencies.txt` records its versions.
- The installed original helper matched the upstream source SHA256 exactly. Only that helper was replaced in the disposable guest for the native after run. The cached base image was unchanged.

## Reproduction

1. Write a real file with `printf 'First line\nSecond line\n\n\n' > expected.txt` (25 bytes).
2. Copy it through the actual Wayland clipboard: `wl-copy --type text/plain < expected.txt`.
3. Open the native Omarchy clipboard panel. Check that the saved history entry is byte-identical to the source file.
4. Press Alt+Enter in the panel to launch the default editor (Neovim). Inspect the actual file passed to that editor.
5. Repeat after installing the fixed helper in the same disposable guest. `verify-native-open.sh` drives Alt+Enter, checks that the native editor appears and compares its actual file bytes.

| Check | Original | Fixed |
| --- | ---: | ---: |
| Source / captured history bytes | 25 / 25 | 25 / 25 |
| Actual editor-file bytes | 22 | 25 |
| Identical to the source file | No | Yes |
| Last three LF bytes retained | No | Yes |

`before.png` and `after.png` were saved by `omarchy capture screenshot fullscreen save` inside the running guest. Neovim shows two lines before, and the two trailing blank lines after. The initial editor launch also performs its usual tree-sitter setup; this is visible in the before screenshot. `clipboard-panel.png` shows the real clipboard panel used for the test.

## Verification

- Regression test run against the original helper failed on the single-final-newline case (`regression-red.log`).
- Focused clipboard suite: 89 assertions passed on Ubuntu and 89 passed on native Arch/Omarchy.
- Full CLI suite on Ubuntu: 125 assertions passed.
- New byte-comparison cases cover no final newline, one final newline, multiple blank lines, CRLF and Unicode. Existing URL, text and image checks also pass.
- `bash -n` and `git diff --check` passed.
- Independent Codex review found no blocking issues and additionally checked JSON escaping, URL/domain entries, an image path with spaces and invalid inputs. This is AI review, not a human review.
- The whole graphical acceptance suite was not run. The native clipboard-panel-to-editor flow was exercised directly, with real clipboard, shell and editor processes.

## Duplicate review

The open clipboard PRs were queried again before submission. The actual patches for #14224, #11920, #15187, #14919, #13706 and #15137 were checked; their work covers selection snapshots, size limits, pins, storage, URL punctuation or MIME handling, and does not preserve trailing LF bytes in the editor file. Additional patches #14760, #13360, #11701, #7381 and #8343 do not modify the open helper. `duplicate-check.json` records the search results and inspected PRs.

Screenshots and text samples are unedited native outputs. There are no credentials, private keys or VM overlays in this evidence directory.
