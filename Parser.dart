library JavaEvaluator;

//import 'dart:io';
import 'dart:html';
import 'dart:json';
import 'dart:core';

part 'Nodes.dart';
part 'Runner.dart';
part 'printer.dart';
part 'environment.dart';

//var hello = JSON.parse(
////    '[{"NODE_TYPE":"class","startPos":31,"endPos":1307,"name":"Mains","members":[{"NODE_TYPE":"method","startPos":46,"endPos":89,"name":"funksjon","type":{"NODE_TYPE":"primitive","startPos":46,"endPos":50,"value":"VOID"},"parameters":[{"NODE_TYPE":"variable","startPos":60,"endPos":65,"name":"x","type":{"NODE_TYPE":"primitive","startPos":60,"endPos":63,"value":"INT"}},{"NODE_TYPE":"variable","startPos":67,"endPos":75,"name":"b","type":{"NODE_TYPE":"identifier","startPos":67,"endPos":73,"value":"String"}}],"body":{"NODE_TYPE":"block","startPos":76,"endPos":89,"statements":[{"NODE_TYPE":"assignment","startPos":80,"endPos":85,"variable":{"NODE_TYPE":"identifier","startPos":80,"endPos":81,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":84,"endPos":85,"type":"INT_LITERAL","value":"5"}}]}},{"NODE_TYPE":"method","startPos":93,"endPos":216,"modifiers":{"NODE_TYPE":"modifiers","startPos":93,"endPos":106,"modifiers":["public","static"]},"name":"main","type":{"NODE_TYPE":"primitive","startPos":107,"endPos":111,"value":"VOID"},"parameters":[{"NODE_TYPE":"variable","startPos":117,"endPos":128,"name":"args","type":{"NODE_TYPE":"identifier","startPos":117,"endPos":123,"value":"String"}}],"body":{"NODE_TYPE":"block","startPos":129,"endPos":216,"statements":[{"NODE_TYPE":"variable","startPos":133,"endPos":143,"name":"x","type":{"NODE_TYPE":"primitive","startPos":133,"endPos":136,"value":"INT"},"initializer":{"NODE_TYPE":"literal","startPos":141,"endPos":142,"type":"INT_LITERAL","value":"3"}},{"NODE_TYPE":"assignment","startPos":146,"endPos":151,"variable":{"NODE_TYPE":"identifier","startPos":146,"endPos":147,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":150,"endPos":151,"type":"INT_LITERAL","value":"5"}},{"NODE_TYPE":"assignment","startPos":155,"endPos":161,"variable":{"NODE_TYPE":"identifier","startPos":155,"endPos":156,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":159,"endPos":161,"type":"INT_LITERAL","value":"10"}},{"NODE_TYPE":"assignment","startPos":165,"endPos":171,"variable":{"NODE_TYPE":"identifier","startPos":165,"endPos":166,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":169,"endPos":171,"type":"INT_LITERAL","value":"21"}},{"NODE_TYPE":"if","startPos":175,"endPos":213,"condition":{"NODE_TYPE":"parenthesized","startPos":177,"endPos":186,"body":{"NODE_TYPE":"binary","startPos":178,"endPos":185,"type":"EQUAL_TO","left_op":{"NODE_TYPE":"identifier","startPos":178,"endPos":179,"value":"x"},"right_op":{"NODE_TYPE":"literal","startPos":183,"endPos":185,"type":"INT_LITERAL","value":"21"}}},"then":{"NODE_TYPE":"block","startPos":186,"endPos":213,"statements":[{"NODE_TYPE":"assignment","startPos":191,"endPos":197,"variable":{"NODE_TYPE":"identifier","startPos":191,"endPos":192,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":195,"endPos":197,"type":"INT_LITERAL","value":"13"}},{"NODE_TYPE":"assignment","startPos":202,"endPos":208,"variable":{"NODE_TYPE":"identifier","startPos":202,"endPos":203,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":206,"endPos":208,"type":"INT_LITERAL","value":"22"}}]}}]}}]},{"NODE_TYPE":"class","startPos":1309,"endPos":1323,"name":"Bla","members":[]}]'
//      '[{"NODE_TYPE":"class","startPos":31,"endPos":1301,"name":"Mains","members":[{"NODE_TYPE":"method","startPos":46,"endPos":89,"name":"funksjon","type":{"NODE_TYPE":"primitive","startPos":46,"endPos":50,"value":"VOID"},"parameters":[{"NODE_TYPE":"variable","startPos":60,"endPos":65,"name":"x","type":{"NODE_TYPE":"primitive","startPos":60,"endPos":63,"value":"INT"}},{"NODE_TYPE":"variable","startPos":67,"endPos":75,"name":"b","type":{"NODE_TYPE":"identifier","startPos":67,"endPos":73,"value":"String"}}],"body":{"NODE_TYPE":"block","startPos":76,"endPos":89,"statements":[{"NODE_TYPE":"assignment","startPos":80,"endPos":85,"variable":{"NODE_TYPE":"identifier","startPos":80,"endPos":81,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":84,"endPos":85,"type":"INT_LITERAL","value":"5"}}]}},{"NODE_TYPE":"method","startPos":93,"endPos":210,"modifiers":{"NODE_TYPE":"modifiers","startPos":93,"endPos":106,"modifiers":["public","static"]},"name":"main","type":{"NODE_TYPE":"primitive","startPos":107,"endPos":111,"value":"VOID"},"parameters":[{"NODE_TYPE":"variable","startPos":117,"endPos":128,"name":"args","type":{"NODE_TYPE":"identifier","startPos":117,"endPos":123,"value":"String"}}],"body":{"NODE_TYPE":"block","startPos":129,"endPos":210,"statements":[{"NODE_TYPE":"variable","startPos":133,"endPos":143,"name":"x","type":{"NODE_TYPE":"primitive","startPos":133,"endPos":136,"value":"INT"},"initializer":{"NODE_TYPE":"literal","startPos":141,"endPos":142,"type":"INT_LITERAL","value":"3"}},{"NODE_TYPE":"assignment","startPos":146,"endPos":151,"variable":{"NODE_TYPE":"identifier","startPos":146,"endPos":147,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":150,"endPos":151,"type":"INT_LITERAL","value":"5"}},{"NODE_TYPE":"assignment","startPos":155,"endPos":161,"variable":{"NODE_TYPE":"identifier","startPos":155,"endPos":156,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":159,"endPos":161,"type":"INT_LITERAL","value":"10"}},{"NODE_TYPE":"assignment","startPos":165,"endPos":171,"variable":{"NODE_TYPE":"identifier","startPos":165,"endPos":166,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":169,"endPos":171,"type":"INT_LITERAL","value":"21"}},{"NODE_TYPE":"if","startPos":175,"endPos":197,"condition":{"NODE_TYPE":"parenthesized","startPos":177,"endPos":186,"body":{"NODE_TYPE":"binary","startPos":178,"endPos":185,"type":"EQUAL_TO","left_op":{"NODE_TYPE":"identifier","startPos":178,"endPos":179,"value":"x"},"right_op":{"NODE_TYPE":"literal","startPos":183,"endPos":185,"type":"INT_LITERAL","value":"21"}}},"then":{"NODE_TYPE":"assignment","startPos":190,"endPos":196,"variable":{"NODE_TYPE":"identifier","startPos":190,"endPos":191,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":194,"endPos":196,"type":"INT_LITERAL","value":"13"}}},{"NODE_TYPE":"assignment","startPos":200,"endPos":206,"variable":{"NODE_TYPE":"identifier","startPos":200,"endPos":201,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":204,"endPos":206,"type":"INT_LITERAL","value":"22"}}]}}]},{"NODE_TYPE":"class","startPos":1303,"endPos":1317,"name":"Bla","members":[]}]'
//
//    );
var mains = parse(
    '[{"NODE_TYPE":"class","startPos":0,"endPos":160,"name":"Mains","members":[{"NODE_TYPE":"method","startPos":17,"endPos":159,"modifiers":{"NODE_TYPE":"modifiers","startPos":17,"endPos":30,"modifiers":["public","static"]},"name":"main","type":{"NODE_TYPE":"primitive","startPos":31,"endPos":35,"value":"VOID"},"parameters":[{"NODE_TYPE":"variable","startPos":41,"endPos":52,"name":"args","type":{"NODE_TYPE":"identifier","startPos":41,"endPos":47,"value":"String"}}],"body":{"NODE_TYPE":"block","startPos":53,"endPos":159,"statements":[{"NODE_TYPE":"variable","startPos":62,"endPos":72,"name":"x","type":{"NODE_TYPE":"primitive","startPos":62,"endPos":65,"value":"INT"},"initializer":{"NODE_TYPE":"literal","startPos":70,"endPos":71,"type":"INT_LITERAL","value":"3"}},{"NODE_TYPE":"assignment","startPos":80,"endPos":85,"variable":{"NODE_TYPE":"identifier","startPos":80,"endPos":81,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":84,"endPos":85,"type":"INT_LITERAL","value":"5"}},{"NODE_TYPE":"assignment","startPos":94,"endPos":100,"variable":{"NODE_TYPE":"identifier","startPos":94,"endPos":95,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":98,"endPos":100,"type":"INT_LITERAL","value":"10"}},{"NODE_TYPE":"assignment","startPos":109,"endPos":115,"variable":{"NODE_TYPE":"identifier","startPos":109,"endPos":110,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":113,"endPos":115,"type":"INT_LITERAL","value":"21"}},{"NODE_TYPE":"if","startPos":124,"endPos":154,"condition":{"NODE_TYPE":"parenthesized","startPos":126,"endPos":135,"body":{"NODE_TYPE":"binary","startPos":127,"endPos":134,"type":"EQUAL_TO","left_op":{"NODE_TYPE":"identifier","startPos":127,"endPos":128,"value":"x"},"right_op":{"NODE_TYPE":"literal","startPos":132,"endPos":134,"type":"INT_LITERAL","value":"21"}}},"then":{"NODE_TYPE":"assignment","startPos":147,"endPos":153,"variable":{"NODE_TYPE":"identifier","startPos":147,"endPos":148,"value":"x"},"expr":{"NODE_TYPE":"literal","startPos":151,"endPos":153,"type":"INT_LITERAL","value":"22"}}}]}}]}]'
    );
Program prog = new Program(mains);

//void main() {
//  Runner r = new Runner(prog);
//  int steps = 0;
//  while(!r.isDone()){
//    print("step: ${++steps}");
//    r.step();
//  }
//}

class Program {
  List root;
  Map<String, ClassDecl> classDeclarations = {};
  MethodDecl main;
  
  Program(List<Map<String, dynamic>> ast) {
    root = ast.mappedBy(parseObject).toList();
  }
  
  parseObject(Map json){
    if(json == null)
      return;
    //TODO add support for block node
    switch(json['NODE_TYPE']){
      case 'class':
        return parseClass(json);
      case 'method':
        return parseMethod(json);
      case 'variable':
        return parseVar(json);
      case 'method_call':
        return parseMethodCall(json);
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
      case 'member_select':
        return new MemberSelect.fromJson(json, parseObject(json['expr']));
      case 'return':
        return new Return.fromJson(json, parseObject(json['expr']));
      default:
        throw "Object type not supported yet: ${json['NODE_TYPE']}";
    }
  }

  parseMethodCall(json) => new MethodCall.fromJson(json, parseObject(json['select']), json['arguments'].mappedBy(parseObject).toList());

  parseIf(json) => new If.fromJson(json, parseObject(json['condition']), 
                    json['then']['NODE_TYPE'] == 'block' ? json['then']['statements'].mappedBy(parseObject).toList() : [parseObject(json['then'])],
                    json['else'] == null ? null : (json['else']['NODE_TYPE'] == 'block' ? json['else']['statements'].mappedBy(parseObject).toList() : [parseObject(json['then'])]));

  parseLiteral(json) {
    switch(json['type']){
      case 'INT_LITERAL':
        return int.parse(json['value']);
      case 'STRING_LITERAL':
        return json['value'];
      case 'BOOLEAN_LITERAL':
        return json['value'] == 'true';
      default:
        throw "Literal type not supported yet: ${json['type']}";
    }
  }

  parseAssignment(Map json) => new Assignment.fromJson(json, parseObject(json['variable']), parseObject(json['expr']));

  parseMethod(Map json) {
    MethodDecl method = new MethodDecl.fromJson(json, new Type.fromJson(json['type']), json['parameters'].mappedBy(parseObject).toList(), json['body']['statements'].mappedBy(parseObject).toList());
    
    if(method.name == "main" && method.type == MethodType.main){
      this.main = method;
    }
    
    return method;
  }
  
  ClassDecl parseClass(Map json){
    ClassDecl clazz = new ClassDecl.fromJson(json, json['members'].mappedBy(parseObject).toList());
    this.classDeclarations[clazz.name] = clazz;
    return clazz;  
  }

  Variable parseVar(Map json) {
    return new Variable.fromJson(json, new Type.fromJson(json['type']), parseObject(json['initializer']));
  }
  
//  Variable parseVar(Map json) => new Variable.fromJson(json, new Type.fromJson(json['type']), parseObject(json['initializer']));
  
//  parseType(Map json){
//    switch(json['NODE_TYPE']){
//      case 'primitive':
//        return new Type.primitive(json['value']);
//      case 'identifier':
//        return new Type.declared(json['value']);
//      default:
//        throw "Type declaration not supported yet: ${json['NODE_TYPE']}";
//    }
//  }
}