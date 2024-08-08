String convertDartColorToJs(String dartColor){
  // convert color from AABBGGRR to RRGGBBAA
  return dartColor.substring(2) + dartColor.substring(0, 2);
}