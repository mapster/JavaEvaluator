library JavaEvaluator;

import 'dart:html';
import 'dart:json';
import 'dart:core';

part 'Nodes.dart';
part 'Runner.dart';
part 'printer.dart';
part 'environment.dart';
part 'types.dart';

class Program {
  List root;
  Map<String, ClassDecl> classDeclarations = {};
  MemberSelect mainSelector;
  
  Program(List<Map<String, dynamic>> ast) {
    root = ast.mappedBy(parseObject).toList();
  }
  
  parseObject(Map json){
    if(json == null)
      return;
    //TODO add support for block node
    switch(json['NODE_TYPE']){
      case 'array_access':
        return new ArrayAccess.fromJson(json, parseObject(json['index']), parseObject(json['expr']));
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
      case 'array':
        return new TypeNode(parseObject(json['value']));
      case 'primitive':
        return json['value'];
      case 'member_select':
        return new MemberSelect.fromJson(json, parseObject(json['expr']));
      case 'new_array':
        return new NewArray.fromJson(json, new TypeNode(parseObject(json['type'])), json['dimensions'].map(parseObject).toList());
      case 'new':
        return new NewObject.fromJson(json, parseObject(json['name']));
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

  parseLiteral(json) =>  new Literal.fromJson(json);

  parseAssignment(Map json) => new Assignment.fromJson(json, parseObject(json['variable']), parseObject(json['expr']));

  parseMethod(Map json) {
    MethodDecl method = new MethodDecl.fromJson(json, new TypeNode(parseObject(json['type'])), json['parameters'].mappedBy(parseObject).toList(), json['body']['statements'].mappedBy(parseObject).toList());
    return method;
  }
  
  ClassDecl parseClass(Map json){
    ClassDecl clazz = new ClassDecl.fromJson(json, json['members'].mappedBy(parseObject).toList());
    //if class has a main method, create a selector for it
    if(clazz.staticMethods.any((MethodDecl m) => m.name == "main" && m.type == MethodType.main))
      this.mainSelector = new MemberSelect.mainMethod(new Identifier(clazz.name));
    
    this.classDeclarations[clazz.name] = clazz;
    return clazz;  
  }

  Variable parseVar(Map json) {
    return new Variable.fromJson(json, new TypeNode(parseObject(json['type'])), parseObject(json['initializer']));
  }
}