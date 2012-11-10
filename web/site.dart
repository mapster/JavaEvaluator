library site;

import 'dart:html';

var context;

main() {
  InputElement bruk = query("#bruk");
  bruk.on.click.add((Event e){readFile();});
  
  
  CanvasElement canvas = query("#canvas");
  context = canvas.context2d;
  print("Heisann");
}

readFile(){
  InputElement fileChoice = query("#file");
  FileReader reader = new FileReader();
  context.fillStyle = "black";
  context.font = "normal 16px Monospace";
  reader.on.loadEnd.add((Event e){printSource(reader.result);});
  reader.readAsText(fileChoice.files[0]);
}

printSource(String text){
  int y = 0;
  text.split("\n").map((line){context.fillText(line, 0, y += 15);});
}