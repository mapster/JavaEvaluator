library JdkLib;

import '../Runner.dart';
import '../ast.dart' show Identifier, MethodDecl;
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
  
}

class JDKString implements ClassInstance {
  const Map<Identifier, dynamic> variables = null;  
  StaticClass lookupClass(Identifier name) => null;
  dynamic lookup(Identifier name) => null;
  
  const Identifier name = const Identifier.fixed("String");
  const List<MethodDecl> methods = const [];
  final String value;
  
  JDKString(String this.value); 
  
  void newVariable(Identifier name, [dynamic value]){
    if(name.name != "value")
      throw "Cannot declare field $name in object ${this.name}";
    if(?value)
      throw "Cannot assign value to an immutable object ${this.name}";
  }
  
  bool assign(Identifier name, dynamic value){
    throw "Cannot assign value to an immutable object ${this.name}";
  }
  
  String toString() => "\"$value\"";
  
}
