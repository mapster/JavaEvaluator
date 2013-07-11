library site;

import 'dart:html';
import 'dart:json';
import 'dart:math';
import '../Runner.dart';
import '../ast.dart';
import '../types.dart';
part '../printer.dart';

final int UIMODE_STARTING = 0;
final int UIMODE_NO_SOURCE = 1;
final int UIMODE_SOURCE_SELECTED = 2;
final int UIMODE_EVAL_STARTED = 3;
final int UIMODE_STEPPING = 4;
final int UIMODE_FINISHED = 5;
int uiMode = UIMODE_STARTING;

String exampleSource = "class StaticTest { static int tall0; static int tall2 = 4; static int tall3 = funksjon(fem()); static int tall4 = funksjon3(fem(), funksjon2(fem()), 3); static int funksjon(int tall){ tall0 = tall; return funksjon2(9); }static int funksjon2(int tall){ tall2 = 1; return tall; } static int fem(){ return 5; } static int funksjon3(int tall, int tall2, int tall3){ return tall2;}}";
String toJsonUrl = "/tojson";
String javaUrl = "/java";

DivElement value = query("#lastvalue");
DivElement javaSource = query("#javasource");
DivElement environment = query("#environment");
TableElement memory = query("#memory");
Program prog;
Runner runner;
InputElement stepBtn = query("#step");
InputElement selectBtn = query("#select");
InputElement srcInput = query("#srcinput");
ElementList components = queryAll(".component");
Element srcSelector = query("#srcselector");
ParagraphElement status = query("#status");
ParagraphElement helpline = query("#helpline");

void main() {
  InputElement bruk = query("#bruk");
  bruk.onClick.listen((Event e){readFile();});

  changeUiMode(UIMODE_NO_SOURCE);
  clearSrcInput();
  query("#clearsrc").onClick.listen((Event e) {clearSrcInput();});
  //  Parser.prog.root.map(f)
  stepBtn.onClick.listen((Event e){step();});
  selectBtn.onClick.listen((Event e){selectClicked();});
  selectBtn.size = selectBtn.children.length;
  
//  drawArrow(new Pos(), new Pos(), 7);
}

void changeUiMode(int newMode) {
  if(uiMode != newMode) {
    uiMode = newMode;
    if(uiMode == UIMODE_NO_SOURCE) {
      changeComponentMode("#srcselector", ".component", "");
      stepBtn.value = "Start";
      stepBtn.disabled = true;
      status.text = "Please input a program";
    }
    else if(uiMode == UIMODE_SOURCE_SELECTED) {
      changeComponentMode(".control", "", ".component");
      stepBtn.value = "Start";
      stepBtn.disabled = false;
      status.text = "Ready";
    }
    else if(uiMode == UIMODE_EVAL_STARTED) {
      changeComponentMode(".control", "", ".component");
      stepBtn.value = "Step";
      stepBtn.disabled = false;
      status.text = "Running";
    }
    else if(uiMode == UIMODE_STEPPING) {
      changeComponentMode("", "", ".component");
      stepBtn.value = "Step";
      stepBtn.disabled = false;
      status.text = "Running";
    }
    else if(uiMode == UIMODE_FINISHED) {
      changeComponentMode("", "", ".component");
      stepBtn.value = "Done";
      stepBtn.disabled = true;
      status.text = "Stopped";
    }
  }
}

void changeComponentMode(String highlightPat, String disablePat, String normalPat) {
  for(Element comp in components) {
    if(highlightPat != "" && comp.matches(highlightPat)) {
      comp.classes.remove("disabled");
      comp.classes.add("highlight");
    }
    else if(disablePat != "" && comp.matches(disablePat)) {
      comp.classes.add("disabled");
      comp.classes.remove("highlight");
    }
    else if(normalPat != "" && comp.matches(normalPat)) {
      comp.classes.remove("disabled");
      comp.classes.remove("highlight");
    }
  }
}

void clearSrcInput() {
  srcInput.text = "public class Test {\n  public static void main() {\n  // ...\n  }\n}";
}
void selectClicked() {
  switch(selectBtn.value) {
    case "*upload*":
      //query("#uploadFile").style.display = "block";
      query("#inputcode").style.display = "none";
      query("#javasource").style.display = "block";
//      selectBtn.size = 3;
      selectBtn.size = selectBtn.children.length;
      break;
    case "*input*":
      //query("#uploadFile").style.display = "none";
      query("#inputcode").style.display = "block";
      query("#javasource").style.display = "none";
//      selectBtn.size = 3;
      selectBtn.size = selectBtn.children.length;
      break;
    case "":
      //query("#uploadFile").style.display = "none";
      query("#inputcode").style.display = "none";
      query("#javasource").style.display = "block";
      selectBtn.size = selectBtn.children.length;
      break;
    default:
      //query("#uploadFile").style.display = "none";
      query("#inputcode").style.display = "none";
      query("#javasource").style.display = "block";
      selectBtn.size = selectBtn.children.length;
      String fileName = selectBtn.value;
      if(new RegExp(r"[a-zA-Z]+\.java$").matchAsPrefix(fileName) != null) {
        HttpRequest.getString(javaUrl + "/" + fileName)
          .then((result) { postSourceToJsonService(name:selectBtn.value, source:result); print(result); });
      }
      break;
  }
}

void step(){
  if(!runner.isDone()){
    changeUiMode(UIMODE_STEPPING);
    runner.step();
    printEnv();
    query("#stack").text = runner.environment.toString();
    selectCurrent();
    selectNext();
  }

  if(runner.isDone()) {
    changeUiMode(UIMODE_FINISHED);
  }
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

selectNext(){
  List<Element> prevs = queryAll(".next");
  if(prevs != null)
    prevs.forEach((e) => e.classes.remove("next"));
  
  if(runner.next != null){
    Element next = query("#node${runner.next.nodeId}");
    if(next != null)
      next.classes.add("next");
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
  
  status.text = "Loading program '$name'...";
  req.onReadyStateChange.listen((Event e){
      if(req.readyState == HttpRequest.DONE && (req.status == 200 || req.status == 0)){
        print("parsing");
        srcInput.text = source;
        prog = (new Program(parse(req.responseText)));
        print("intializing runner");
        runner = new Runner(prog);
        javaSource.children[0] = Printer.toHtml(prog.compilationUnits.first);
        stepBtn.disabled = false;
        stepBtn.value = "Start";
        environment.children.clear();
        printEnv();
        query("#stack").text = runner.environment.toString();
        changeUiMode(UIMODE_SOURCE_SELECTED);
        selectNext();
        status.text = "Program '$name' loaded";
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
    
    String addrTxt = key.toAddr();
    row.id = "mem$addrTxt";
    addr.classes.add("memaddr");
    addr.classes.add("memref$addrTxt");
    addr.text = "$key";
    addMouseOverMarkAll(addr, ".memref$addrTxt", "marked");
    val.classes.add("memval");
    var v = runner.environment.values[key];
    val.text = "$v";
    if(v is ReferenceValue) {
      val.classes.add("memref${v.toAddr()}");
      addMouseOverMarkAll(val, ".memref${v.toAddr()}", "mark");
    }
    
    return row;
  }).toList();
}

void addMouseOverMark(Element elt, String mark) {
  elt.onMouseOver.listen((Event e) {elt.classes.add(mark);});
  elt.onMouseOut.listen((Event e) {elt.classes.remove(mark);});
}

void addMouseOverMarkAndHelp(Element elt, String mark, String help) {
  elt.onMouseOver.listen((Event e) {
    elt.classes.add(mark);
    helpline.text = help;
  });
  elt.onMouseOut.listen((Event e) {
    elt.classes.remove(mark);
    helpline.text = "\u00a0";
  });
}

void addMouseOverMarkAll(Element elt, String selector, String mark) {
  elt.onMouseOver.listen((Event e) {queryAll(selector).classes.add(mark);});
  elt.onMouseOut.listen((Event e) {queryAll(selector).classes.remove(mark);});
}

void addAssertClick(Element elt, int nodeid) {
  elt.onClick.listen((Event e) {
    for(Element e in queryAll(".popup"))
      e.remove();
    Element popup = new FormElement();
    popup.classes.add("popup");
    LabelElement label = new LabelElement();
    label.text = "assert ";
    label.classes.add("keyword");
    label.attributes['for'] = "assertion"; 
    popup.append(label);

    InputElement input = new InputElement();
    input.type = "text";
    input.size = 10;
    input.id = "assertion";
    popup.append(input);

    InputElement add = new InputElement();
    add.type = "button";
    add.value = "Add";
    add.onClick.listen((Event e1) {popup.remove();});
    popup.append(add);

    InputElement cancel = new InputElement();
    cancel.type = "button";
    cancel.value = "Cancel";
    cancel.onClick.listen((Event e1) {popup.remove();});
    popup.append(cancel);
    
    popup.onSubmit.listen((Event e1) {popup.remove(); e1.preventDefault();});
    elt.parent.append(popup);
  });
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