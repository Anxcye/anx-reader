import 'package:logging/logging.dart';

Level stringToLevel(String str){
  switch(str){
    case 'OFF':
      return Level.OFF;
    case 'FINEST':
      return Level.FINEST;
    case 'FINER':
      return Level.FINER;
    case 'FINE':
      return Level.FINE;
    case 'CONFIG':
      return Level.CONFIG;
    case 'INFO':
      return Level.INFO;
    case 'WARNING':
      return Level.WARNING;
    case 'SEVERE':
      return Level.SEVERE;
    case 'SHOUT':
      return Level.SHOUT;
    default:
      return Level.ALL;
  }
}