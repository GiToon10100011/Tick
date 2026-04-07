#!/bin/bash
# --dart-define 값을 DartDefines.xcconfig로 디코딩
# Xcode Build Phase "Run Script"에서 호출됨 (Compile Sources 이전)

OUTPUT="${SRCROOT}/Flutter/DartDefines.xcconfig"

# 파일 초기화
: > "$OUTPUT"

if [ -z "$DART_DEFINES" ]; then
  echo "DART_DEFINES is empty, skipping." >&2
  exit 0
fi

IFS=',' read -r -a items <<< "$DART_DEFINES"
for item in "${items[@]}"; do
  pair=$(echo "$item" | base64 --decode 2>/dev/null)
  if [[ "$pair" == *"="* ]]; then
    key="${pair%%=*}"
    value="${pair#*=}"
    # flutter 내부 변수는 제외
    if [[ "$key" != "flutter."* ]]; then
      echo "${key}=${value}" >> "$OUTPUT"
    fi
  fi
done
