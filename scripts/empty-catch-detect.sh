#!/usr/bin/env bash
# scripts/empty-catch-detect.sh — Detect empty error handling blocks
#
# Scans a file for:
#   Python: bare `except:` or `except X: pass` (with nothing else)
#   JS/TS: `catch (e) {}` or `catch {}` or catch with only a comment
#
# An empty catch block is ALWAYS wrong — zero false positives.
# Per error-handling-performance.md: "Never silently ignore errors"
#
# Usage: empty-catch-detect.sh <file>

set -euo pipefail

main() {
    local file="${1:-}"
    [ -z "$file" ] && exit 0
    [ -f "$file" ] || exit 0

    local ext="${file##*.}"
    local findings=""

    case "$ext" in
        py)
            # Detect: bare except: pass / except Exception: pass / except:\n    pass
            # Match lines with just `pass` or `...` after except
            findings=$(awk '
                /^\s*except\s*:/ || /^\s*except\s+[A-Za-z_]+.*:/ {
                    except_line = NR; except_text = $0; next
                }
                except_line && /^\s*(pass|\.\.\.)\s*$/ {
                    printf "  Line %d: %s → Line %d: %s\n", except_line, except_text, NR, $0
                    except_line = 0; next
                }
                except_line && /^\s*#/ { next }
                except_line { except_line = 0 }
            ' "$file" 2>/dev/null || true)
            ;;
        js|jsx|ts|tsx)
            # Detect: catch (e) {} or catch {} or catch (e) { /* comment */ }
            # Single-line empty catch
            local single_line
            single_line=$(grep -nE 'catch\s*(\([^)]*\))?\s*\{\s*(//.*|/\*.*\*/)?\s*\}' "$file" 2>/dev/null || true)
            if [ -n "$single_line" ]; then
                findings=$(echo "$single_line" | while IFS= read -r line; do
                    echo "  Line $(echo "$line" | cut -d: -f1): $(echo "$line" | cut -d: -f2- | sed 's/^\s*//')"
                done)
            fi

            # Multi-line empty catch: catch (...) {\n}
            local multi_line
            multi_line=$(awk '
                /catch\s*(\([^)]*\))?\s*\{/ {
                    catch_line = NR; catch_text = $0
                    if (match($0, /\{\s*(\/\/.*|\/\*.*\*\/)?\s*\}/)) {
                        next  # already caught by single-line
                    }
                    next
                }
                catch_line && /^\s*\}\s*$/ {
                    printf "  Line %d-%d: empty catch block\n", catch_line, NR
                    catch_line = 0; next
                }
                catch_line && /^\s*(\/\/|\/\*|\*\/)/ { next }
                catch_line && /^\s*$/ { next }
                catch_line { catch_line = 0 }
            ' "$file" 2>/dev/null || true)

            if [ -n "$multi_line" ]; then
                findings="${findings}${findings:+$'\n'}${multi_line}"
            fi
            ;;
        *)
            exit 0
            ;;
    esac

    if [ -n "$findings" ]; then
        echo "🚫 EMPTY CATCH DETECTED in ${file}:"
        echo "$findings"
        echo ""
        echo "Per error-handling-performance.md: 'Never silently ignore errors.'"
        echo "Every error must be raised, logged, or explicitly handled."
    fi
}

main "$@"
