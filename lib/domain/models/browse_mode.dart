/// Browse mode for the image gallery viewer
/// 
/// Defines the two mutually exclusive modes the application can operate in
enum BrowseMode {
  /// System browse mode - launched directly, scans system directories
  systemBrowse,
  
  /// File association mode - launched via file association with a specific image
  fileAssociation,
}
