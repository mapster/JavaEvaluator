part of JavaEvaluator;

class Environment {
  final Runner _runner;
  int _counter = 1;
  final Map<ReferenceValue, dynamic> values = new Map<ReferenceValue, dynamic>();
  final List<ClassScope> instanceStack = new List<ClassScope>();
  final ReferenceValue defaultPackage = new ReferenceValue(0);
  final Map<Identifier, ReferenceValue> packages = new Map<Identifier, ReferenceValue>();
  Scope get currentScope => instanceStack.last.currentScope;
  
  Environment(this._runner){
    values[defaultPackage] = new Package(const Identifier.fixed(""));
  }
  
  void addBlock(List statements) => instanceStack.last.addBlock(new BlockScope(statements));
  
  dynamic popStatement(){
    while(!instanceStack.isEmpty && instanceStack.last.isDone)
      instanceStack.removeLast();
    return instanceStack.last.popStatement();
  }
  
  bool get isDone {
    if(instanceStack.isEmpty)
      return true;
    return instanceStack.every((ClassScope sc) => sc.isDone);
  }
  
  void newVariable(Identifier name, [Value value = ReferenceValue.invalid]){
    instanceStack.last.newVariable(name, value);
  }
  
  void assign(Identifier name, Value value){
    //only looking in current instance scope because memberselect assignments should load environment
    if(!instanceStack.last.assign(name, value))
      throw "Variable $name not declared in current scope!";
  }
  
  void arrayAssign(ReferenceValue array, int index, Value value) {
    (values[array] as Array)[index] = value;
  }

  Value getArrayValue(ReferenceValue array, int index){
    return values[array][index];
  }
  
  Value lookupVariable(Identifier name){
    //Check in current class instance for the variable (both static and instance)
    print("Lookin up: $name");
    return  instanceStack.last.lookupVariable(name);
  }
  
  Value lookupIn(Identifier name, ReferenceValue envRef){
    return values[envRef].lookupVariable(name);
  }
  
  ReferenceValue lookupContainer(Identifier name, {ReferenceValue inContainer}){
    print("looking up container: $name");
    var found = null;
    if(?inContainer){
      //lookup in specified container, must exist!
      found = values[inContainer].lookupContainer(name);
    }
    else if(name == Identifier.DEFAULT_PACKAGE){
      return defaultPackage;
    }
    else if(!instanceStack.isEmpty){
      //lookup in current namespace
      found = instanceStack.last.lookupContainer(name);
      //check classes in package
      if(found == null)
        found = values[instanceStack.last.package].lookupContainer(name);
    }
    
    if(found != null){
      print("found: $found");
      return found;
    }
    
    //check if package
    return packages[name];
  }
  
  ReferenceValue memberSelectContainer(MemberSelect select){
    ReferenceValue inCont;
    if(select.owner is MemberSelect)
      inCont = memberSelectContainer(select.owner);
    else
      inCont = lookupContainer(select.owner);
    
    return lookupContainer(select.member_id, inContainer:inCont);
  }
  
  ReferenceValue newObject(ReferenceValue staticRef, List<Value> constructorArgs){
    StaticClass clazz = values[staticRef];
    
    List<EvalTree> initializers = new List<EvalTree>();
    ClassInstance inst = new ClassInstance(clazz, initializers);
    //declare all variables and create assignments of the initializers
    clazz._declaration.instanceVariables.forEach((Variable v){
      Identifier id = new Identifier.fixed(v.name);
      inst.newVariable(id);
      if(v.initializer != null)
        initializers.add(new EvalTree(v, _runner, (List args) => assign(id, args.first), [v.initializer]));
    });
    
    //add method call to constructor
    initializers.add(new EvalTree(null, _runner, (List args){
      loadMethod(Identifier.CONSTRUCTOR, constructorArgs);
    }, []));
 
    return _newValue(inst);
  }

  ReferenceValue newArray(int size, Value value, TypeNode type) {
    return _newValue(new Array(size, value, type));
  }

  ReferenceValue _newValue(dynamic value){
    ReferenceValue addr = new ReferenceValue(++_counter);
    values[addr] = value;
    return addr;
  }

  void loadMethod(Identifier name, List args, {ReferenceValue inContainer}) {
    if(?inContainer)
      loadEnv(inContainer);
    
    instanceStack.last.loadMethod(name, args, args.map(typeOf).toList());
  }
  
  void methodReturn(){
    instanceStack.last.methodReturn();
  }
  
  bool loadEnv(ReferenceValue env){
    print("loading environment $env => ${values[env]} ");
    instanceStack.addLast(values[env]);
    return true;
  }
  
  void unloadEnv(){
    instanceStack.removeLast();
  }
  
  TypeNode typeOf(dynamic val){
    if(val is ReferenceValue)
      val = values[val];
    
    if(val is ClassScope){
      return new TypeNode(new Identifier.fixed(val.clazz.name));
    }
    else if(val is PrimitiveValue){
      return new TypeNode(val.type);
    }
    else if(val is Array){
      return val.type;
    }
  }
}

class Array {
  final List _list;
  final TypeNode type;
  
  Array(int size, value, this.type) : _list = new List.fixedLength(size, fill:value);
  
  operator[](int index) => _list[index];
  void operator[]=(int index, value) { _list[index] = value; }
  
  String toString() => _list.toString();
}


abstract class Scope {
  final Map<Identifier, Value> _variables = new Map<Identifier, Value>();
  final List<dynamic> _statements;
  bool  get isDone;
  Scope get currentScope;
  bool  get _isDone => _statements.isEmpty;
  
  Scope(this._statements);
  
  void _newVariable(Identifier name, [Value value=ReferenceValue.invalid]){
    if(_variables.containsKey(name))
      throw "Cannot redeclare variable $name";
    
    _variables[name] = value;
  }
  
  bool _assign(Identifier name, Value value){
    if(!_variables.containsKey(name))
      return false;
    
    _variables[name] = value;
    return true;
  }
  
  Value _lookupVariable(Identifier name){
    return _variables[name];
  }
  
  dynamic _popStatement(){
    return _statements.removeAt(0);
  }
  
  void _pushStatement(dynamic statement){
    _statements.insertRange(0, 1, statement);
  }

  void addBlock(BlockScope block);
  void newVariable(Identifier name, [Value value=ReferenceValue.invalid]);
  bool assign(Identifier name, Value value);
  Value lookupVariable(Identifier name);
  dynamic popStatement();
  void pushStatement(dynamic statement);
}

abstract class ClassScope extends Scope {
  List<BlockScope> _methodStack = new List<BlockScope>();
  
  Identifier get name;
  List<MethodDecl> get methodDeclarations;
  Map<Identifier, ReferenceValue> get _namespaceClasses;
  ReferenceValue get package;
  bool  get isDone {
    if(_methodStack.any((sc) => !sc.isDone))
        return false;
    return super._isDone;
  }
  Scope get currentScope {
    if(_methodStack.isEmpty)
      return this;
    return _methodStack.last.currentScope;
  }
  
  ClassScope(List<dynamic> statements) : super(statements);
  
  void loadMethod(Identifier name, List<Value> args, List<TypeNode> argTypes){
    List<MethodDecl> methods = methodDeclarations;

    print("looking for $name: $argTypes in  $methods");
    MethodDecl method = methods.singleMatching((m) => m.name == name.name && _checkParamArgTypeMatch(m.type.parameters, argTypes));
    _methodStack.addLast(new BlockScope(method.body));
    for(int i = 0; i < method.parameters.length; i++){
      newVariable(new Identifier.fixed(method.parameters[i].name), args[i]);
    }
  }
  
  void methodReturn(){
    _methodStack.removeLast();
  }
  
  void addBlock(BlockScope block){
    if(_methodStack.isEmpty)
      throw "Can't add child block scope to a class scope!";
    
    _methodStack.last.addBlock(block);
  }
  
  void newVariable(Identifier name, [Value value=ReferenceValue.invalid]){
    if(!_methodStack.isEmpty)
      _methodStack.last.newVariable(name, value);
    else
      super._newVariable(name, value);
  }
  
  bool assign(Identifier name, Value value){
    //check if variable exists in inner scope
    if(!_methodStack.isEmpty && _methodStack.last.assign(name, value))
      return true;

    //if not, attempt to assign to this scope
    return super._assign(name, value);
  }
  
  Value lookupVariable(Identifier name){
    if(!_methodStack.isEmpty){
      Value val = _methodStack.last.lookupVariable(name);
      if(val != null)
        return val;
    }
    
    return super._lookupVariable(name);
  }
  
  ReferenceValue lookupContainer(Identifier name){
    print("namespace classes: ${_namespaceClasses.keys.reduce("", (r, c) => "$r, $c")}");
    return _namespaceClasses[name];
  }
  
  dynamic popStatement(){
    //pop complete method scopes
    while(!_methodStack.isEmpty && _methodStack.last.isDone)
      _methodStack.removeLast();
    
    if(!_methodStack.isEmpty)
      return _methodStack.last.popStatement();

    return super._popStatement();
  }
  
  void pushStatement(dynamic statement){
    if(!_methodStack.isEmpty)
      _methodStack.last.pushStatement(statement);
    else
      super._pushStatement(statement);
  }
  
  static bool _checkParamArgTypeMatch(List<TypeNode> parameters, List<TypeNode> args) {
    if(parameters.length != args.length)
      return false;
    
    for(int i = 0; i < parameters.length; i++){
      if(parameters[i] != args[i])
        return false;
    }
    return true;
  }
}

class BlockScope extends Scope {
  Scope _subBlock;
  Scope get currentScope => _subBlock == null ? this : _subBlock.currentScope;
  bool get isDone => _subBlock == null ? _statements.isEmpty : _subBlock.isDone && _statements.isEmpty;
  
  BlockScope(List<dynamic> statements) : super(statements);
  
  void addBlock(BlockScope block){
    if(_subBlock != null)
      _subBlock.addBlock(block);
    else
      _subBlock = block;
  }
  
  void newVariable(Identifier name, [Value value=ReferenceValue.invalid]){
    if(_subBlock != null)
      _subBlock.newVariable(name, value);
    else 
      super._newVariable(name, value);
  }
  
  bool assign(Identifier name, Value value){
    if(_subBlock != null && _subBlock.assign(name, value))
      return true;
    
    return super._assign(name, value);
  }
  
  Value lookupVariable(Identifier name){
    if(_subBlock != null){
      Value val = _subBlock.lookupVariable(name);
      if(val != null)
        return val;
    }
    
    return super._lookupVariable(name);
  }
  
  dynamic popStatement(){
    //pop block if empty
    if(_subBlock != null && _subBlock.isDone)
      _subBlock = null;
    
    if(_subBlock != null && !_subBlock.isDone)
      return _subBlock.popStatement();
    
    return super._popStatement();
  }
  
  void pushStatement(dynamic statement){
    if(_subBlock != null)
      _subBlock.pushStatement(statement);
    else
      super._pushStatement(statement);    
  }
}

class StaticClass extends ClassScope {
  final ClassDecl _declaration;
  final Map<Identifier, ReferenceValue> _localClasses = new Map<Identifier, ReferenceValue>();
  final ReferenceValue package;
  List<MethodDecl> get methodDeclarations => _declaration.staticMethods;
  Map<Identifier, ReferenceValue> _namespaceClasses = new Map<Identifier, ReferenceValue>();
  Identifier get name => new Identifier.fixed(_declaration.name);
  
  StaticClass(ReferenceValue this.package, ClassDecl this._declaration, List<dynamic> statements) : super(statements);
  
  String toString() => name.toString();
}

class ClassInstance extends ClassScope {
  final StaticClass _static;
  ReferenceValue get package => _static.package;
  Map<Identifier, dynamic> get _namespaceClasses => _static._namespaceClasses; 
  List<MethodDecl> get methodDeclarations => new List<MethodDecl>()
      ..addAll(_static._declaration.staticMethods)..addAll(_static._declaration.instanceMethods);
  Identifier get name => _static.name;
  
  ClassInstance(StaticClass this._static, List<dynamic> statements) : super(statements);
  
  String toString() => "${_variables}";
}

class Package {
  final Identifier name;
  final Map<Identifier, ReferenceValue> _members = new Map<Identifier, ReferenceValue>();
  
  Package(this.name);
  
  void addMember(Identifier name, ReferenceValue pkgRef) {
    print("$name: adding member -> $name");
    _members[name] = pkgRef; 
  }
  
  ReferenceValue lookupContainer(Identifier name) => _members[name];
}
