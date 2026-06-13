# Player Context

V1 playback uses `media_kit` through a Flutter adapter.

## Boundary

```text
Source -> Parser -> Matcher -> Playback contract -> Player adapter
```

Rust resolves playback contracts. Flutter owns the visible player and user
controls. Player code must not parse sources.

## V1 Danmaku

Danmaku has model and renderer-slot placeholders only. Remote danmaku source
integration is not part of V1.

## Verification

Player changes require adapter tests and a Windows smoke path once Flutter is
available.

