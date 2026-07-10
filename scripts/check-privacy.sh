#!/bin/sh
set -eu

root="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
if rg -n 'NSMicrophoneUsageDescription|RequestsOpenAccess</key>[[:space:]]*<true|com\.apple\.security\.network|aps-environment' "$root/WenmoApp" "$root/WenmoKeyboard"; then
  echo "Privacy check failed: forbidden capability found." >&2
  exit 1
fi
if rg -n 'URLSession|NWConnection|Network\.framework|AVAudioRecorder|SFSpeechRecognizer' "$root/WenmoApp" "$root/WenmoKeyboard"; then
  echo "Privacy check failed: network or recording API found." >&2
  exit 1
fi
echo "Privacy check passed: no network, open-access, microphone, speech, or recording capability."
