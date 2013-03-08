part of JavaEvaluator;

const Package javaPkg = const Package.fixed(PkgIds.java, const {"lang": javaLangPkg});
const Package javaLangPkg = const Package.fixed(PkgIds.lang, const {"String": bla});

const bla = "";

class LibraryClass {
  final Map<Identifier, Value> variables = new Map<Identifier, Value>();
  
  lookup(Identifier name) => variables[name];
}

class PkgIds {
  static const Identifier java = const Identifier.fixed("java");
  static const Identifier lang = const Identifier.fixed("lang");
}

class LibraryMethodDecl implements MethodDecl {
  const int startPos = -1;
  const int endPos = -1;
  const int nodeId = -1;
  
  List<EvalTree> _body;
  List<EvalTree> get body => _body;
  bool isStatic() => modifiers.contains("static");
  bool isConstructor;
  String name;
  String publicName;
  MethodType type;
  List<Variable> parameters;
  List<String> modifiers;
}

class JDKString implements ClassInstance {
  const Identifier name = const Identifier.fixed("String");
  StaticClass lookupClass(Identifier name) => null;
  StaticClass get _static => null;
  Value lookup(Identifier name) => null;
  Value _lookup(Identifier name) => null;
  const Map<Identifier, Value> _variables = null;
  void _newVariable(Identifier name, [Value value = ReferenceValue.invalid]) => newVariable(name, value);
  void newVariable(Identifier name, [Value value]){
    if(name.name != "value")
      throw "Cannot declare field $name in object ${this.name}";
    if(?value)
      this.value = value._value;
  }
  
  bool _assign(Identifier name, Value value) => assign(name, value);
  bool assign(Identifier name, Value value){
    if(name.name != "value")
      throw "Cannot assign to field $name in object ${this.name}";
    this.value = value._value;
  }
  
  String value;
  
  List<MethodDecl> methods = [];
  
  JDKString(String this.value); 
  String toString() => "\"$value\""; 
}

