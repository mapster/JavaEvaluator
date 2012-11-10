library JavaEvaluator;

import 'dart:json';
import 'dart:coreimpl';
part 'Nodes.dart';
part 'Runner.dart';

void main() {
  var hello = JSON.parse('[{"NODE_TYPE":"class","startPos":31,"endPos":1291,"name":"Mains","members":[{"NODE_TYPE":"method","startPos":46,"endPos":89,"name":"funksjon","type":{"NODE_TYPE":"primitive","startPos":46,"endPos":50,"value":"VOID"},"parameters":[{"NODE_TYPE":"variable","startPos":60,"endPos":65,"name":"x","type":{"NODE_TYPE":"primitive","startPos":60,"endPos":63,"value":"INT"}},{"NODE_TYPE":"variable","startPos":67,"endPos":75,"name":"b","type":{"NODE_TYPE":"identifier","startPos":67,"endPos":73,"value":"String"}}],"body":{"NODE_TYPE":"block","startPos":76,"endPos":89,"statements":[{"NODE_TYPE":"assignment","startPos":80,"endPos":85,"variable":{"NODE_TYPE":"identifier","startPos":80,"endPos":81,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":84,"endPos":85,"type":"INT_LITERAL","value":"5"}}]}},{"NODE_TYPE":"method","startPos":93,"endPos":200,"modifiers":{"NODE_TYPE":"modifiers","startPos":93,"endPos":106,"modifiers":["public","static"]},"name":"main","type":{"NODE_TYPE":"primitive","startPos":107,"endPos":111,"value":"VOID"},"parameters":[{"NODE_TYPE":"variable","startPos":117,"endPos":128,"name":"args","type":{"NODE_TYPE":"identifier","startPos":117,"endPos":123,"value":"String"}}],"body":{"NODE_TYPE":"block","startPos":129,"endPos":200,"statements":[{"NODE_TYPE":"variable","startPos":133,"endPos":143,"name":"x","type":{"NODE_TYPE":"primitive","startPos":133,"endPos":136,"value":"INT"},"initializer":{"NODE_TYPE":"literal","startPos":141,"endPos":142,"type":"INT_LITERAL","value":"3"}},{"NODE_TYPE":"assignment","startPos":146,"endPos":151,"variable":{"NODE_TYPE":"identifier","startPos":146,"endPos":147,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":150,"endPos":151,"type":"INT_LITERAL","value":"5"}},{"NODE_TYPE":"assignment","startPos":155,"endPos":161,"variable":{"NODE_TYPE":"identifier","startPos":155,"endPos":156,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":159,"endPos":161,"type":"INT_LITERAL","value":"10"}},{"NODE_TYPE":"assignment","startPos":165,"endPos":171,"variable":{"NODE_TYPE":"identifier","startPos":165,"endPos":166,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":169,"endPos":171,"type":"INT_LITERAL","value":"21"}},{"NODE_TYPE":"if","startPos":175,"endPos":197,"condition":{"NODE_TYPE":"parenthesized","startPos":177,"endPos":186,"body":{"NODE_TYPE":"binary","startPos":178,"endPos":185,"type":"EQUAL_TO","left_op":{"NODE_TYPE":"identifier","startPos":178,"endPos":179,"value":"x"},"right_op":{"NODE_TYPE":"literal","startPos":183,"endPos":185,"type":"INT_LITERAL","value":"21"}}},"then":{"NODE_TYPE":"assignment","startPos":190,"endPos":196,"variable":{"NODE_TYPE":"identifier","startPos":190,"endPos":191,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":194,"endPos":196,"type":"INT_LITERAL","value":"22"}}}]}}]},{"NODE_TYPE":"class","startPos":1293,"endPos":1307,"name":"Bla","members":[]}]');

  Program prog = new Program(hello);
  prog.root.map(print);
  print("main ${prog.main}");
  
  Runner r = new Runner(prog);
  r.run();
}

class Program {
  List root;
  List<ClassDecl> classDeclarations = [];
  MethodDecl main;
  
  Program(List<Map<String, dynamic>> ast) {
    root = ast.map(parseObject);
  }
  
  parseObject(Map json){
    if(json == null)
      return;
    
    switch(json['NODE_TYPE']){
      case 'class':
        return parseClass(json);
      case 'method':
        return parseMethod(json);
      case 'variable':
        return parseVar(json);
      case 'assignment':
        return parseAssignment(json);
      case 'literal':
        return parseLiteral(json);
      case 'if':
        return parseIf(json);
      case 'parenthesized':
        return parseObject(json['body']);
      case 'binary':
        return new BinaryOp.fromJson(json, parseObject(json['left_op']), parseObject(json['right_op']));
      case 'identifier':
        return new Identifier.fromJson(json); 
      default:
        throw "Object type not supported yet: ${json['NODE_TYPE']}";
    }
  }

  parseIf(json) => new If.fromJson(json, parseObject(json['condition']), parseObject(json['then']));

  parseLiteral(json) {
    switch(json['type']){
      case 'INT_LITERAL':
        return int.parse(json['value']);
      default:
        throw "Literal type not supported yet: ${json['type']}";
    }
  }

  parseAssignment(Map json) => new Assignment(parseObject(json['variable']), parseObject(json['expr']));

  parseMethod(Map json) {
    MethodDecl method = new MethodDecl(json['name'], parseType(json['type']), json['parameters'].map(parseObject), json['body']['statements'].map(parseObject));
    
    if(method.name == "main" && method.type == MethodType.main)
      this.main = method;
    
    return method;
  }
  
  ClassDecl parseClass(Map json){
    ClassDecl clazz = new ClassDecl(json['name']);
    clazz.addMembers(json['members'].map(parseObject));
    this.classDeclarations.add(clazz);
    return clazz;  
  }
  
  Variable parseVar(Map json) => new Variable.fromJson(json, parseType(json['type']), parseObject(json['initializer']));
  
  Type parseType(Map json){
    switch(json['NODE_TYPE']){
      case 'primitive':
        return new Type.primitive(json['value']);
      case 'identifier':
        return new Type.declared(json['value']);
      default:
        throw "Type declaration not supported yet: ${json['NODE_TYPE']}";
    }
  }
}