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
    values[defaultPackage] = new Package(const Identifier(""));
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
    return values[envRef].lookup(name);
  }
  
  ReferenceValue lookupContainer(Identifier name, {ReferenceValue inContainer}){
    print("looking up container: $name");
    var found = null;
    if(?inContainer){
      //lookup in specified container, must exist!
      found = values[inContainer].lookupContainer(name);
    }
    else if(!instanceStack.isEmpty){
      //lookup in current namespace
      found = instanceStack.last.lookupContainer(name);
      //check classes in package
      if(found == null)
        found = values[instanceStack.last.package].lookupContainer(name);
    }
    
    if(found != null)
      return found;
    
    //if not found, check if default package
    if(name == Identifier.CONSTRUCTOR)
      return defaultPackage;
    
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
  
  
//  ReferenceValue createPackage(Identifier name, {ReferenceValue inContainer}){
//    Package addTo = defaultPackage;
//    if(?inContainer)
//      addTo = values[inContainer];
//    
//    ReferenceValue ref = _newValue(new Package(name));
//    addTo.addMember(name, ref);
//    return ref;
//  }
  
  /**
   * Initializes a class instance, i.e. stores all fields with an initial value in memory and returns the class environment.
   */
  //TODO potential mess with primitive values
//  ReferenceValue newClassInstance(ClassDecl clazz, [bool static = false]){
//    ClassScope scope = new ClassScope(clazz, static);
//    if(static)
//      staticContext.newVariable(new Identifier(clazz.name),_newValue(scope));
//    
//    return _newValue(scope);
//  }
//  
  ReferenceValue newObject(ReferenceValue staticRef, List<Value> constructorArgs){
    print("type: ${staticRef.runtimeType}");
    StaticClass clazz = values[staticRef];
    
    List<EvalTree> initializers = new List<EvalTree>();
    ClassInstance inst = new ClassInstance(clazz, initializers);
    //declare all variables and create assignments of the initializers
    clazz._declaration.instanceVariables.forEach((Variable v){
      Identifier id = new Identifier(v.name);
      inst.newVariable(id);
      if(v.initializer != null)
        initializers.add(new EvalTree(v, _runner, (List args) => assign(id, args.first), [v.initializer]));
    });
    
    //add method call to constructor
    initializers.add(new EvalTree(null, _runner, (List args){
      loadMethod(Identifier.CONSTRUCTOR, constructorArgs);
      var toReturn = new EvalTree(null, _runner, (List args) => inst, []);
      _runner.returnValues.addLast(toReturn);
      return toReturn;
    }, []));
 
    return _newValue(inst);
  }
//  
//  ClassDecl lookUpClass(name){
//    if(name is Identifier){
//      return values[staticContext.lookUp(name)].clazz;
//    }
//    else throw "Don't know how to look up class using ${name.runtimeType}."; 
//  }
//  
  ReferenceValue newArray(int size, Value value, TypeNode type) {
    return _newValue(new Array(size, value, type));
  }
//  
//  Value lookUpValue(variable){
//    bool loadedEnv = false;
//    if(variable is MemberSelect){
//      loadedEnv = loadEnv(lookUpValue(variable.owner));
//      variable = variable.member_id;
//    }
//    
//    if(variable is! Identifier)
//      throw "Can't lookup value by using ${variable.runtimeType}";
//    
//    //TODO add static context! (it may have been added?)      
//    Value val = currentContext.lookUp(variable);
//    
//    if(val == null){
//      if(loadedEnv)
//        throw "Variable [${variable.name}] not declared.";
//        
//      val = staticContext.lookUp(variable);
//    }
//    
//    if(loadedEnv)
//      unloadEnv();
//      
//    return val;
//  }
//  
  ReferenceValue _newValue(dynamic value){
    ReferenceValue addr = new ReferenceValue(++_counter);
    values[addr] = value;
    return addr;
  }
//  
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
      return new TypeNode(new Identifier(val.clazz.name));
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

//class Scope {
//  final Map<Identifier, Value> assignments = new Map<Identifier, Value>();
//  final List<dynamic> _statements = [];
//  final bool isMethod;
//  Scope _subscope;
//  
//  Scope get currentScope => _subscope != null ? _subscope.currentScope : this; 
//  
//  Scope.block(List statements) : isMethod = false { _statements.addAll(statements); }
//  Scope.method(List statements) : isMethod = true { _statements.addAll(statements); }
//  
//  String toString() {
//    var local = "[${_statements.reduce("", (prev,e) => "$e${prev.length > 0 ? "," : ""} $prev")}]";
//    return "$local${_subscope != null ? ", $_subscope" : ""}";
//  }
//  
//  void newVariable(Identifier name, [Value value = ReferenceValue.invalid]){
//    if(_subscope != null){
//        _subscope.newVariable(name, value);
//    }
//    else {
//      assignments[name] = value;
//      print("declaring: $name ${value is ReferenceValue ? " at [${value}]" : ""} with value $value of type ${value.runtimeType}");
//    }
//  }
//  
//  bool assign(Identifier name, Value value){
//    if(_subscope != null && _subscope.assign(name, value))
//      return true;
//    
//    if(!assignments.containsKey(name))
//      return false;
//        
//    assignments[name] = value;
//    return true;
//  }
//  
//  Value lookUp(Identifier variable){
//    if(_subscope != null){
//      var val = _subscope.lookUp(variable);
//      if(val != null)
//        return val;
//    }
//  
//    return assignments[variable];
//  }
//  
//  dynamic popStatement(){
//    if(_subscope != null && _subscope.isDone)
//        _subscope = null;
//    
//    if(_subscope != null)
//      return _subscope.popStatement();
//    
//    return _statements.removeAt(0);
//  }
//  
//  bool get isDone {
//    if(_subscope != null && !_subscope.isDone)
//      return false;
//    return _statements.isEmpty;
//  }
//  
//  void addSubScope(Scope s){
//    if(_subscope != null)
//      _subscope.addSubScope(s);
//    else
//      _subscope = s;
//  }
//}
//
//class ClassScope extends Scope {
//  Scope _constructor;
//  final List<Scope> _subscopes = new List<Scope>();
//  final ClassDecl clazz;
//  final bool isStatic;
//  
//  Scope get currentScope => _subscopes.isEmpty ? this : _subscopes.last.currentScope;
//  
//  ClassScope(this.clazz, this.isStatic) : super.block([]){
//    if(isStatic)
//      _statements.addAll(clazz.staticVariables);
//  }
//  
//  String toString() {
////    var local = super.toString();
////    return "$local${_subscopes.isEmpty ? "" : ", ${_subscopes.reduce("", (r, e) => "$r, $e")}"}";
//    return "$assignments";
//  }
//  
//  addSubScope(Scope s) => _subscopes.add(s);
//  addSubBlock(Scope s) => _subscopes.last.addSubScope(s);
//  
//  void newVariable(Identifier name, [Value value = ReferenceValue.invalid]){
//    if(_subscopes.isEmpty)
//      super.newVariable(name, value);
//    else
//    _subscopes.last.newVariable(name, value);
//  }
//  
//  bool assign(Identifier name, Value value){
//    if(!_subscopes.isEmpty && _subscopes.last.assign(name, value))
//        return true;
//    
//    return super.assign(name, value);
//  }
//  
//  Value lookUp(Identifier variable){
//    if(!_subscopes.isEmpty){
//      var val = _subscopes.last.lookUp(variable); 
//      if(val != null)
//        return val;
//    }
//    
//    return super.lookUp(variable);
//  }
//
//  methodReturn(){
//    _subscopes.removeLast();    
//  }
//  
//  dynamic popStatement() {
//    //remove subscopes untill either all are removed or one has statements
//    while(!_subscopes.isEmpty && _subscopes.last.isDone)
//      _subscopes.removeLast();
//    
//    //if there are still subscopes and the last is not done, pop statement
//    if(!_subscopes.isEmpty && !_subscopes.last.isDone)
//      return _subscopes.last.popStatement();
//    
//    //else pop own statement.
//    if(!super.isDone)
//      return super.popStatement();
//    
//    //check if constructor is still running
//    if(!_constructor.isDone)
//      return _constructor.popStatement();
//  }
//  
//  bool get isDone {
//    if(_subscopes.any((Scope sc) => !sc.isDone))
//      return false;
//    
//    if(_constructor != null && !_constructor.isDone)
//      return false;
//    
//    return super.isDone;
//  }
//  
//  void loadMethod(Identifier name, List args, List<TypeNode> argTypes) {
//    List<MethodDecl> methods = isStatic ? clazz.staticMethods : clazz.instanceMethods;
//
//    MethodDecl method = methods.singleMatching((m) => m.name == name.name && _checkParamArgTypeMatch(m.type.parameters, argTypes));
//    addSubScope(new Scope.method(method.body));
//    for(int i = 0; i < method.parameters.length; i++){
//      newVariable(new Identifier(method.parameters[i].name), args[i]);
//    }
//  }
//  
//  void loadConstructor(List<Value> args, List<TypeNode> argTypes){
//    if(args.isEmpty){
//      if(!clazz.constructors.isEmpty)
//        throw "The empty constructor is undefined!";
//      return;
//    }
//      
//    MethodDecl method = clazz.constructors.singleMatching((m) => _checkParamArgTypeMatch(m.type.parameters, argTypes));
//    _constructor = new Scope.method(method.body);
//    for(int i = 0; i < method.parameters.length; i++){
//      _constructor.newVariable(new Identifier(method.parameters[i].name), args[i]);
//    }
//  }
//  
//  bool _checkParamArgTypeMatch(List<TypeNode> parameters, List<TypeNode> args) {
//    if(parameters.length != args.length)
//      return false;
//    
//    for(int i = 0; i < parameters.length; i++){
//      TypeNode p = parameters[i];
//      TypeNode a = args[i];
//
//      if(p != a)
//        return false;
//    }
//    return true;
//  }
//}


// new class structure
//
//
//

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
      newVariable(new Identifier(method.parameters[i].name), args[i]);
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
    if(!_methodStack.isEmpty)
      return _methodStack.last.assign(name, value);
    else
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
  Identifier get name => new Identifier(_declaration.name);
  
  StaticClass(ReferenceValue this.package, ClassDecl this._declaration, List<dynamic> statements) : super(statements);
  
  String toString() => name.toString();
}

class ClassInstance extends ClassScope {
  final StaticClass _static;
  ReferenceValue get package => _static.package;
  Map<Identifier, dynamic> get _namespaceClasses => _static._namespaceClasses; 
  List<MethodDecl> get methodDeclarations => new List<MethodDecl>()
      ..addAll(_static._declaration.staticMethods)..addAll(_static._declaration.instanceMethods);
  
  ClassInstance(StaticClass this._static, List<dynamic> statements) : super(statements);
  
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
