#!/usr/bin/env bash
# clock.sh — elapsed-time formatting for the scripts' timing clock. Sourced,
# not executed. Defines functions only; sets no shell options and runs nothing
# at load time. macOS bash 3.2 compatible.
#
# Source this unconditionally: it ships beside every script that uses it, so a
# missing file is a broken checkout and should fail loudly rather than silently
# degrade. Copy this file to <repo>/scripts/lib/clock.sh.

# format_duration <total_seconds> -> "9m 57s", "1h 04m 12s", "42s"
#
# Raw seconds stop being readable at about a minute: a provision that reports
# "597s" makes the reader do arithmetic to learn it took ten minutes. Units
# that match the magnitude cost nothing and remove that step.
format_duration() {
  local total_seconds="$1"
  local hours=$(( total_seconds / 3600 ))
  local minutes=$(( (total_seconds % 3600) / 60 ))
  local seconds=$(( total_seconds % 60 ))

  if (( hours > 0 )); then
    printf '%dh %02dm %02ds' "$hours" "$minutes" "$seconds"
  elif (( minutes > 0 )); then
    printf '%dm %02ds' "$minutes" "$seconds"
  else
    printf '%ds' "$seconds"
  fi
}
