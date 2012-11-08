import 'dart:json';
import 'dart:coreimpl';
part 'Nodes.dart';

void main() {
  var hello = JSON.parse('[{"NODE_TYPE":"class","startPos":31,"endPos":1227,"name":"Mains","members":[{"NODE_TYPE":"method","startPos":46,"endPos":89,"name":"funksjon","type":{"NODE_TYPE":"primitive","startPos":46,"endPos":50,"value":"VOID"},"parameters":[{"NODE_TYPE":"variable","startPos":60,"endPos":65,"name":"x","type":{"NODE_TYPE":"primitive","startPos":60,"endPos":63,"value":"INT"}},{"NODE_TYPE":"variable","startPos":67,"endPos":75,"name":"b","type":{"NODE_TYPE":"identifier","startPos":67,"endPos":73,"value":"String"}}],"body":{"NODE_TYPE":"block","startPos":76,"endPos":89,"statements":[{"NODE_TYPE":"assignment","startPos":80,"endPos":85,"variable":{"NODE_TYPE":"identifier","startPos":80,"endPos":81,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":84,"endPos":85,"type":"INT_LITERAL","value":"5"}}]}},{"NODE_TYPE":"method","startPos":93,"endPos":136,"modifiers":{"NODE_TYPE":"modifiers","startPos":93,"endPos":106,"modifiers":["public","static"]},"name":"main","type":{"NODE_TYPE":"primitive","startPos":107,"endPos":111,"value":"VOID"},"parameters":[{"NODE_TYPE":"variable","startPos":117,"endPos":128,"name":"args","type":{"NODE_TYPE":"identifier","startPos":117,"endPos":123,"value":"String"}}],"body":{"NODE_TYPE":"block","startPos":129,"endPos":136,"statements":[]}}]},{"NODE_TYPE":"class","startPos":1229,"endPos":1243,"name":"Bla","members":[]}]');

  Program prog = new Program(hello);
  prog.root.map(print);
  print("main ${prog.main}");
}

class Program {
  List root;
  List<ClassDecl> classDeclarations = [];
  MethodDecl main;
  
  Program(List<Map<String, dynamic>> ast) {
    root = ast.map(parseObject);
  }
  
  parseObject(Map obj){
    switch(obj['NODE_TYPE']){
      case 'class':
        return parseClass(obj);
      case 'method':
        return evalMethod(obj);
      case 'variable':
        return parseVar(obj);
      default:
        throw "Object type not supported yet: ${obj['NODE_TYPE']}";
    }
  }
  
  evalMethod(Map obj) {
    MethodDecl method = new MethodDecl(obj['name'], parseType(obj['type']), obj['parameters'].map(parseObject), obj['body']);
    
    if(method.name == "main" && method.type == MethodType.main)
      this.main = method;
    
    return method;
  }
  
  ClassDecl parseClass(Map obj){
    ClassDecl clazz = new ClassDecl(obj['name']);
    clazz.addMembers(obj['members'].map(parseObject));
    this.classDeclarations.add(clazz);
    return clazz;  
  }
  
  Variable parseVar(obj){
    return new Variable(obj['name'], parseType(obj['type']));
  }
  
  Type parseType(obj){
    if(obj['NODE_TYPE'] == "primitive")
      return new Type.primitive(obj['value']);
    else if(obj['NODE_TYPE'] == "identifier")
      return new Type.declared(obj['value']);
    else
      throw "Type declaration not supported yet: ${obj['NODE_TYPE']}";
  }
}