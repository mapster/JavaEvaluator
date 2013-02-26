library site;

import 'dart:html';
import 'dart:json';
import 'dart:math';
import '../Parser.dart';

String exampleSource = "class StaticTest { static int tall0; static int tall2 = 4; static int tall3 = funksjon(fem()); static int tall4 = funksjon3(fem(), funksjon2(fem()), 3); static int funksjon(int tall){ tall0 = tall; return funksjon2(9); }static int funksjon2(int tall){ tall2 = 1; return tall; } static int fem(){ return 5; } static int funksjon3(int tall, int tall2, int tall3){ return tall2;}}";
String toJsonUrl = "/tojson";

DivElement java = query("#java");
DivElement environment = query("#environment");
Program prog;
Runner runner;
InputElement stepBtn = query("#step");

void main() {
  InputElement bruk = query("#bruk");

  //  Parser.prog.root.map(f)
  bruk.onClick.listen((Event e){readFile();});
  stepBtn.onClick.listen((Event e){step();});
  query("#example").onClick.listen((Event e){postSourceToJsonService(exampleSource);});
  
//  drawArrow(new Pos(), new Pos(), 7);
}

void step(){
  if(!runner.isDone()){
    runner.step();
    printEnv();
    query("#stack").text = runner.environment.toString();
    selectCurrent();
  }

  if(runner.isDone())
    stepBtn.disabled = true;
}

selectCurrent(){
  List<Element> prevs = queryAll(".current");
  if(prevs != null)
    prevs.forEach((e) => e.classes.remove("current"));
  
  Element current = query("#node${runner.current.nodeId}");
  if(current != null)
    current.classes.add("current");
}

readFile(){
  InputElement fileChoice = query("#file");
  FileReader reader = new FileReader();
  reader.onLoadEnd.listen((Event e){postSourceToJsonService(reader.result);});
  reader.readAsText(fileChoice.files[0]);
}

postSourceToJsonService(String data){
  HttpRequest req = new HttpRequest();
  
  req.onReadyStateChange.listen((Event e){
      if(req.readyState == HttpRequest.DONE && (req.status == 200 || req.status == 0)){
        print("parsing");
        prog = (new Program(parse(req.responseText)));
        print("intializing runner");
        runner = new Runner(prog);
        java.children[0] = Printer.toHtml(prog.compilationUnits.first);
        stepBtn.disabled = false;
        environment.children.clear();
        printEnv();
        query("#stack").text = runner.environment.toString();
      }
  });
  
  req.open("POST", toJsonUrl);
  req.setRequestHeader("Content-Type", "text/x-java");
  req.send(data);
}

void printEnv(){
//  DivElement root = new DivElement();
//  HeadingElement hValues = new HeadingElement.h3();
//  hValues.text = "Values";
//  DivElement values = new DivElement();
//  values.children = runner.environment.values.keys.mappedBy((key){
//    DivElement val = new DivElement();
//    var v = runner.environment.values[key];
//    val.text = "$key: ${runner.environment.typeOf(v)} => $v";
//    return val;
//  }).toList();
//  root.children = [hValues, values];
//
//  environment.children = [root, Printer.scopeToHtml(runner.environment.currentScope)];
  environment.children = [Printer.staticEnv(runner.environment)];
}

//void drawArrow(Pos p1, Pos p2, num width){
//  DivElement arrow = new DivElement();
//  arrow.attributes['class'] = "arrow";
//  
//  num length = sqrt(pow(p1.x - p2.x, 2) + pow(p1.y - p2.y, 2));
//  num angle = asin((p1.y - p2.y).abs() / length)*180/PI;
//  
//  Pos c = new Pos((p1.x + p2.x).abs()~/2 - length~/2, (p1.y + p2.y).abs()~/2 - width/2);
//  if(p1.x < p2.x && p1.y > p2.y)
//    angle = -angle;
//  else if(p1.x > p2.x && p1.y < p2.y)
//    angle = -angle;
//  
//  arrow.style.transform = "rotate(${angle}deg)";
//  arrow.style.left = "${c.x}px";
//  arrow.style.top = "${c.y}px";
//  arrow.style.width = "${length}px";
//  arrow.style.height = "${width}px";
//  
//  cont.children.add(arrow);
//}
//
//class Pos {
//  num x;
//  num y;
//  Pos(this.x, this.y);
//  String toString() => "($x:$y)";
//}