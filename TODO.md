# Dart SDK - TODO

## Missing Utility Methods

Add the following utility methods to match Python SDK:

### Additional Utility Methods
- [ ] `getVersion() -> String` - Get SDK version string
- [ ] `setNode(String address) -> void` - Set primary node address for querying blockchain
- [ ] `handleError(Map<String, dynamic> result) -> void` - Handle API error responses

## Notes
- Dart currently has 46 public methods (the most complete)
- Python has 42 public methods but includes `getVersion`, `setNode`, and `handleError`
- Adding these 3 methods will bring Dart to 49 methods (fully aligned with Python)
- Dart already has unique methods like `setHeader` and `dispose` that other SDKs should adopt
