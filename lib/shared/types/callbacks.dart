/// Common callback typedefs to replace raw `Function(...)` usages and
/// improve analyzer type safety across the app.
library;

/// A JSON-like map used for passing lightweight structured data.
typedef JsonMap = Map<String, dynamic>;

/// Callback receiving a JSON-like map.
typedef JsonMapCallback = void Function(JsonMap data);

/// Callback receiving an `int` (e.g. IDs).
typedef IntCallback = void Function(int value);

/// Callback receiving a `String` (e.g. IDs, codes, messages).
typedef StringCallback = void Function(String value);

/// Generic value change callback.
typedef ValueCallback<T> = void Function(T value);
