library JdkLib;

import '../Runner.dart';
import '../types.dart';
import '../ast.dart' show Identifier, MethodDecl, Variable, MethodType, TypeNode;
//const Package javaPkg = const Package.fixed(PkgIds.java, const {"lang": javaLangPkg});
//const Package javaLangPkg = const Package.fixed(PkgIds.lang, const {"String": bla});
//
//const bla = "";

//class LibraryClass {
//  final Map<Identifier, Value> variables = new Map<Identifier, Value>();
//  
//  lookup(Identifier name) => variables[name];
//}

//class PkgIds {
//  static const Identifier java = const Identifier.fixed("java");
//  static const Identifier lang = const Identifier.fixed("lang");
//}

//class LibraryMethodDecl implements MethodDecl {
//  const int startPos = -1;
//  const int endPos = -1;
//  const int nodeId = -1;
//  
//  List<EvalTree> _body;
//  List<EvalTree> get body => _body;
//  bool isStatic() => modifiers.contains("static");
//  bool isConstructor;
//  String name;
//  String publicName;
//  MethodType type;
//  List<Variable> parameters;
//  List<String> modifiers;
//}

class LibraryMethodDecl implements MethodDecl {
  final List<String> modifiers;
  final List<Variable> parameters;
  final MethodType type;
  final List<EvalTree> body;
  final bool isConstructor;
  final bool isStatic;
  final String name;
  final String publicName;
  
  const LibraryMethodDecl({this.modifiers, this.parameters, this.type, this.body, this.isConstructor, this.isStatic, 
                          this.name, this.publicName});
}

//class LibMethodBody implements EvalTree {
//  const int startPos = -1;
//  const int endPos = -1;
//  const int nodeId = -1;
//  const bool isStatic = false;
//  const List modifiers = const [];
//  
//  final method;
//  const LibMethodBody(this.method);
//  
//  dynamic execute() => method();
//}

class JDKString implements ClassInstance {
  final Map<Identifier, dynamic> variables = new Map();  
  StaticClass lookupClass(Identifier name) => null;
  dynamic lookup(Identifier name) => null;
  
  final Identifier name = const Identifier.fixed("String");
  final List<LibraryMethodDecl> methods = new List<LibraryMethodDecl>();
  final String value;
  String val() => value;
  
  JDKString(String this.value) {
//    methods.add(new LibraryMethodDecl(modifiers: const ["public"], 
//        parameters: const [const Variable("index", TypeNode.INT, null)], 
//        type: const MethodType(TypeNode.CHAR, const [TypeNode.INT]), 
//        body: [new LibMethodBody((List args){
//          print(args);
//          print(val().codeUnits);
//          return val().codeUnits[args[0]];})], 
//        isConstructor: false, 
//        isStatic: false, 
//        name: "charAt", publicName: "charAt"));
  }
  
  void newVariable(Identifier name, [dynamic value]){
    if(name.name != "value")
      throw "Cannot declare field $name in object ${this.name}";
    if(value == null)
      throw "Cannot assign value to an immutable object ${this.name}";
  }
  
  bool assign(Identifier name, dynamic value){
    throw "Cannot assign value to an immutable object ${this.name}";
  }
  
  CharValue charAt(IntegerValue index) => new CharValue(value.codeUnitAt(index.value));
  
  String toString() => "\"$value\"";
  
  
  //Methods
//  LibraryMethodDecl charAt = new LibraryMethodDecl(modifiers: const ["public"], 
//        parameters: const [const Variable("index", TypeNode.INT, null)], 
//        type: const MethodType(TypeNode.CHAR, const [TypeNode.INT]), 
//        body: [new LibMethodBody((List args) => this.val().codeUnits[args[0]])], 
//        isConstructor: false, 
//        isStatic: false, 
//        name: "charAt", publicName: "charAt");
}
