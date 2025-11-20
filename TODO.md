# Dart SDK - TODO

## Missing Utility Methods

Add the following utility methods to match Python SDK:

### Additional Utility Methods
- [ ] `getVersion() -> String` - Get SDK version string
- [ ] `setNode(String address) -> void` - Set primary node address for querying blockchain

## Notes
- Dart currently has 46 public methods (the most complete)
- Python has 42 public methods but includes `getVersion` and `setNode`
- Adding these 2 methods will bring Dart to 48 methods (fully aligned with Python)
- Dart already has unique methods like `setHeader` and `dispose` that other SDKs should adopt
- Note: `handleError` is already implemented as a private method (`_handleError`) and should remain private per canonical spec
