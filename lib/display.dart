/// A class representing a display device with various properties
class Display {
  /// The unique identifier of the display
  int? displayId = 0;

  /// The flag associated with the display (could represent various statuses or capabilities)
  int? flag;

  /// The rotation of the display (e.g., 0, 90, 180, 270 degrees)
  int? rotation;

  /// The name of the display
  String? name;

  /// Constructor to initialize a Display object
  /// - displayId is required to identify the display
  /// - name is required to provide a label for the display
  /// - flag and rotation are optional and may be null
  Display({
    required this.displayId,
    this.flag,
    required this.name,
    this.rotation,
  });

  /// Factory method to create a Display object from a JSON map
  /// - Extracts displayId, flag, name, and rotation values from the given JSON
  factory Display.fromJson(Map<String, dynamic> json) => Display(
        displayId: json['displayId'],
        flag: json['flags'],
        name: json['name'],
        rotation: json['rotation'],
      );
}
