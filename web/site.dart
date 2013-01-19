library site;

import 'dart:html';
import 'dart:json';
import '../Parser.dart';

String exampleSource = "class Mains { public static void main(String args){ int x = 3; x = 5; x = 10; x = 21; if(x == 21) x = 22; } }";
String toJsonUrl = "/tojson";

DivElement tekst = query("#tekst");
DivElement environment = query("#environment");
Program prog;
Runner runner;
InputElement stepBtn = query("#step");

void main() {
  InputElement bruk = query("#bruk");

  //  Parser.prog.root.map(f)
  bruk.on.click.add((Event e){readFile();});
  stepBtn.on.click.add((Event e){step();});
  query("#example").on.click.add((Event e){postSourceToJsonService(exampleSource);});  
}

void step(){
  if(!runner.isDone()){
    runner.step();
    printEnv();
  }

  if(runner.isDone())
    stepBtn.disabled = true;
}

readFile(){
  InputElement fileChoice = query("#file");
  FileReader reader = new FileReader();
  reader.on.loadEnd.add((Event e){postSourceToJsonService(reader.result);});
  reader.readAsText(fileChoice.files[0]);
}

postSourceToJsonService(String data){
  HttpRequest req = new HttpRequest();
  
  req.on.readyStateChange.add((Event e){
      if(req.readyState == HttpRequest.DONE && (req.status == 200 || req.status == 0)){
        prog = (new Program(JSON.parse(req.responseText)));
        runner = new Runner(prog);
        tekst.children = [Printer.toHtml(prog.root.first)];
        stepBtn.disabled = false;
        environment.children.clear();
      }
  });
  
  req.open("POST", toJsonUrl);
  req.setRequestHeader("Content-Type", "text/x-java");
  req.send(data);
}

void printEnv(){
  HeadingElement hValues = new HeadingElement.h3();
  hValues.text = "Values";
  DivElement values = new DivElement();
  values.children = runner.environment.values.keys.map((key){
    DivElement val = new DivElement();
    val.text = "$key: ${runner.environment.values[key]}";
    return val;
  });

  HeadingElement hAssigns = new HeadingElement.h3();
  hAssigns.text = "Assignments";
  DivElement assigns = new DivElement();
  assigns.children = runner.environment.assignments.map((Map<Identifier, int> map){
    DivElement scope = new DivElement();
    scope.children = map.keys.map((key){
      DivElement assign = new DivElement();
      assign.text = "$key: ${map[key]}";
      return assign;
    });
    return scope;
  });

  environment.children = [hValues, values, hAssigns, assigns];
}