enum SyncProtocol {
  webdav('WebDAV'),
  ftp('FTP'),
  s3('Amazon S3'),
  googleDrive('Google Drive'),
  oneDrive('OneDrive'),
  dropbox('Dropbox');

  const SyncProtocol(this.displayName);
  
  final String displayName;
}