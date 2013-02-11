part of JavaEvaluator;

class Environment {
  int _counter = 0;
  final Map<ReferenceValue, dynamic> values = new Map<ReferenceValue, dynamic>();
  Scope staticContext = new Scope.block([]);
  List<ClassScope> contextStack = [];
  
  ClassScope get currentContext => contextStack.last;
  Scope get currentScope => currentContext.currentScope;
  
  void addBlockScope(statements) => currentContext.addSubBlock(new Scope.block(statements));
  
  dynamic popStatement(){
    while(currentContext.isDone)
      contextStack.removeLast();
    return currentContext.popStatement();
  }
  
  bool get isDone {
    if(contextStack.isEmpty)
      return true;
    return contextStack.every((s) => s.isDone);
  }
  
  String toString() => "$contextStack";
  
  void newVariable(Identifier name, [Value value = ReferenceValue.invalid]){
    currentContext.newVariable(name, value);
  }
  
  void assign(Identifier name, Value value){
    if(!currentContext.assign(name, value))
      throw "Variable $name not declared in current scope!";
  }
  
  void arrayAssign(ReferenceValue array, int index, Value value) {
    (values[array] as List)[index] = value;
  }

  Value getArrayValue(ReferenceValue array, int index){
    return values[array][index];
  }
  /**
   * Initializes a class instance, i.e. stores all fields with an initial value in memory and returns the class environment.
   */
  //TODO potential mess with primitive values
  ReferenceValue newClassInstance(ClassDecl clazz, [bool static = false]){
    ClassScope scope = new ClassScope(clazz, static);
    if(static)
      staticContext.newVariable(new Identifier(clazz.name),_newValue(scope));
    
    return _newValue(scope);
  }
  
  ReferenceValue newArray(int size, [Value value = null]) {
    return _newValue(new List.fixedLength(size, fill:value));
  }
  
  Value lookUpValue(variable){
    bool loadedEnv = false;
    if(variable is MemberSelect){
      loadedEnv = loadEnv(lookUpValue(variable.owner));
      variable = variable.member_id;
    }
    
    if(variable is! Identifier)
      throw "Can't lookup value by using ${variable.runtimeType}";
    
    //TODO add static context! (it may have been added?)      
    Value val = currentContext.lookUp(variable);
    
    if(val == null){
      if(loadedEnv)
        throw "Variable [${variable.name}] not declared.";
        
      val = staticContext.lookUp(variable);
    }
    
    if(loadedEnv)
      unloadEnv();
      
    return val;
  }
  
  ReferenceValue _newValue(dynamic value){
    ReferenceValue addr = new ReferenceValue(++_counter);
    values[addr] = value;
    return addr;
  }
  
  void loadMethod(select, List args) {
    if(select is MemberSelect){
      loadEnv(lookUpValue(select.owner));
      select = select.member_id;
    }
    currentContext.loadMethod(select, args);
  }
  
  void methodReturn(){
    currentContext.methodReturn();
  }
  
  bool loadEnv(dynamic env){
    if(env is ReferenceValue)
      env = values[env];
    
    if(env is! ClassScope)
      throw "Can only load class scope as primary environment!";
    
    contextStack.addLast(env);
    return true;
  }
  
  void unloadEnv(){
    contextStack.removeLast();
  }
}

class Scope {
  final Map<Identifier, Value> assignments = new Map<Identifier, Value>();
  final List<dynamic> _statements = [];
  final bool isMethod;
  Scope _subscope;
  
  Scope get currentScope => _subscope != null ? _subscope.currentScope : this; 
  
  Scope.block(List statements) : isMethod = false { _statements.addAll(statements); }
  Scope.method(List statements) : isMethod = true { _statements.addAll(statements); }
  
  String toString() {
    var local = "[${_statements.reduce("", (prev,e) => "$e${prev.length > 0 ? "," : ""} $prev")}]";
    return "$local${_subscope != null ? ", $_subscope" : ""}";
  }
  
  void newVariable(Identifier name, [Value value = ReferenceValue.invalid]){
    if(_subscope != null){
        _subscope.newVariable(name, value);
    }
    else {
      assignments[name] = value;
      print("declaring: $name ${value is ReferenceValue ? " at [${value}]" : ""} with value $value of type ${value.runtimeType}");
    }
  }
  
  bool assign(Identifier name, Value value){
    if(_subscope != null && _subscope.assign(name, value))
      return true;
    
    if(!assignments.containsKey(name))
      return false;
        
    assignments[name] = value;
    return true;
  }
  
  Value lookUp(Identifier variable){
    if(_subscope != null){
      var val = _subscope.lookUp(variable);
      if(val != null)
        return val;
    }
  
    return assignments[variable];
  }
  
  dynamic popStatement(){
    if(_subscope != null && _subscope.isDone)
        _subscope = null;
    
    if(_subscope != null)
      return _subscope.popStatement();
    
    return _statements.removeAt(0);
  }
  
  bool get isDone {
    if(_subscope != null && !_subscope.isDone)
      return false;
    return _statements.isEmpty;
  }
  
  void addSubScope(Scope s){
    if(_subscope != null)
      _subscope.addSubScope(s);
    else
      _subscope = s;
  }
}

class ClassScope extends Scope {
  final List<Scope> _subscopes = new List<Scope>();
  final ClassDecl clazz;
  final bool isStatic;
  
  Scope get currentScope => _subscopes.isEmpty ? this : _subscopes.last.currentScope;
  
  ClassScope(this.clazz, this.isStatic) : super.block([]){
    if(isStatic){
      _statements.addAll(clazz.staticVariables);
    }
  }
  
  String toString() {
    var local = super.toString();
    return "$local${_subscopes.isEmpty ? "" : ", ${_subscopes.reduce("", (r, e) => "$r, $e")}"}";
  }
  

  addSubScope(Scope s) => _subscopes.add(s);
  addSubBlock(Scope s) => _subscopes.last.addSubScope(s);
  
  void newVariable(Identifier name, [Value value = ReferenceValue.invalid]){
    if(_subscopes.isEmpty)
      super.newVariable(name, value);
    else
    _subscopes.last.newVariable(name, value);
  }
  
  bool assign(Identifier name, Value value){
    if(!_subscopes.isEmpty && _subscopes.last.assign(name, value))
        return true;
    
    return super.assign(name, value);
  }
  
  Value lookUp(Identifier variable){
    if(!_subscopes.isEmpty){
      var val = _subscopes.last.lookUp(variable); 
      if(val != null)
        return val;
    }
    
    return super.lookUp(variable);
  }

  methodReturn(){
    _subscopes.removeLast();    
  }
  
  dynamic popStatement() {
    //remove subscopes untill either all are removed or one has statements
    while(!_subscopes.isEmpty && _subscopes.last.isDone)
      _subscopes.removeLast();
    
    //if there are still subscopes and the last is not done, pop statement
    if(!_subscopes.isEmpty && !_subscopes.last.isDone)
      return _subscopes.last.popStatement();
    
    //else pop own statement.
    if(!super.isDone)
      return super.popStatement();
  }
  
  bool get isDone {
    if(_subscopes.any((Scope sc) => !sc.isDone))
      return false;
    
    return super.isDone;
  }
  
  void loadMethod(Identifier name, List args) {
    List<MethodDecl> methods = isStatic ? clazz.staticMethods : clazz.instanceMethods;

    MethodDecl method = methods.singleMatching((m) => m.name == name.name && _checkParamArgTypeMatch(m.type.parameters, args));
    addSubScope(new Scope.method(method.body));
    for(int i = 0; i < method.parameters.length; i++){
      newVariable(new Identifier(method.parameters[i].name), args[i]);
    }
  }
  
  bool _checkParamArgTypeMatch(List<TypeNode> parameters, List<dynamic> args) {
    if(parameters.length != args.length)
      return false;
    
    for(int i = 0; i < parameters.length; i++){
      TypeNode p = parameters[i];
      var a = args[i];

      if(!p.sameType(a))
        return false;
    }
    return true;
  }
}