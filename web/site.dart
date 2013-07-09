library site;

import 'dart:html';
import 'dart:json';
import 'dart:math';
import '../Runner.dart';
import '../ast.dart';

part '../printer.dart';

String exampleSource = "class StaticTest { static int tall0; static int tall2 = 4; static int tall3 = funksjon(fem()); static int tall4 = funksjon3(fem(), funksjon2(fem()), 3); static int funksjon(int tall){ tall0 = tall; return funksjon2(9); }static int funksjon2(int tall){ tall2 = 1; return tall; } static int fem(){ return 5; } static int funksjon3(int tall, int tall2, int tall3){ return tall2;}}";
String toJsonUrl = "/tojson";
String javaUrl = "/java";

DivElement value = query("#lastvalue");
DivElement java = query("#java");
DivElement environment = query("#environment");
TableElement memory = query("#memory");
Program prog;
Runner runner;
InputElement stepBtn = query("#step");
Element selectSrcCode = query("#selectSourceCode");
InputElement selectBtn = query("#select");
void main() {
  InputElement bruk = query("#bruk");

  //  Parser.prog.root.map(f)
  bruk.onClick.listen((Event e){readFile();});
  stepBtn.onClick.listen((Event e){step();});
  selectSrcCode.onClick.listen((Event e) {toggleSelectSrcCode();});
  selectBtn.onClick.listen((Event e){selectClicked(e);});
  
//  drawArrow(new Pos(), new Pos(), 7);
}

void selectClicked(Event e) {
  switch(selectBtn.value) {
    case "*upload*":
      query("#uploadFile").style.display = "block";
      query("#inputCode").style.display = "none";
      selectBtn.size = 3;
      break;
    case "*input*":
      query("#uploadFile").style.display = "none";
      query("#inputCode").style.display = "block";
      selectBtn.size = 3;
      break;
    case "":
      query("#uploadFile").style.display = "none";
      query("#inputCode").style.display = "none";
      selectBtn.size = selectBtn.children.length;
      break;
    default:
      query("#uploadFile").style.display = "none";
      query("#inputCode").style.display = "none";
      selectBtn.size = selectBtn.children.length;
      String fileName = selectBtn.value;
      if(new RegExp(r"[a-zA-Z]+\.java$").matchAsPrefix(fileName) != null) {
        HttpRequest.getString(javaUrl + "/" + fileName)
          .then((result) { postSourceToJsonService(name:selectBtn.value, source:result); print(result); });
      }
      break;
  }
}

void toggleSelectSrcCode() {
  if(selectSrcCode.style.backgroundColor == "rgb(255, 0, 0)")
    selectSrcCode.style.backgroundColor = "#fff0f0";
  else
    selectSrcCode.style.backgroundColor = "#ff0000";
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
  
  if(runner.current != null){
    Element current = query("#node${runner.current.nodeId}");
    if(current != null)
      current.classes.add("current");
  }
}

readFile(){
  InputElement fileChoice = query("#file");
  FileReader reader = new FileReader();
  reader.onLoadEnd.listen((Event e){postSourceToJsonService(name: fileChoice.files[0].name ,source:reader.result);});
  reader.readAsText(fileChoice.files[0]);
}

String getJavaSource(String url){
  String result;
  HttpRequest.getString(url).then((response) { 
  print(response);
  });
}

postSourceToJsonService({String name, String source}){
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
  
  req.open("POST", "$toJsonUrl/$name");
  req.setRequestHeader("Content-Type", "text/x-java");
  req.send(source);
}

void printEnv(){
  value.text = "${runner.lastValue != null ? runner.lastValue : "..."}";
  environment.children = [Printer.staticEnv(runner.environment), Printer.currentScopeToHtml(runner.environment)];
  
  memory.children = runner.environment.values.keys.map((key){
    TableRowElement row = new TableRowElement();
    TableCellElement addr = new TableCellElement();
    TableCellElement val = new TableCellElement();
    row.children = [addr, val];
    
    addr.text = "$key";
    val.text = "${runner.environment.values[key]}";
    
    return row;
  }).toList();
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