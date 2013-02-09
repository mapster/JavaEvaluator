part of JavaEvaluator;

class Environment {
  int _counter = 0;
  final Map<Address, dynamic> values = new Map<Address, dynamic>();
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
  
  void newVariable(Identifier name, [dynamic value = Address.invalid]){
    if(value is ClassScope)
      value = _newValue(value);
    
    else currentContext.newVariable(name, value);
  }
  
  void assign(Identifier name, dynamic value){
    if(value is ClassScope)
      value = _newValue(value);      
    
    if(!currentContext.assign(name, value))
      throw "Variable $name not declared in current scope!";
  }

  /**
   * Initializes a class instance, i.e. stores all fields with an initial value in memory and returns the class environment.
   */
  //TODO potential mess with primitive values
  ClassScope newClassInstance(ClassDecl clazz, [bool static = false]){
    ClassScope scope = new ClassScope(clazz, static);
    if(static)
      staticContext.newVariable(new Identifier(clazz.name),_newValue(scope));
    
    return scope;
  }
  
  dynamic _lookUpAddress(variable){
    bool loadedEnv = false;
    if(variable is MemberSelect){
      loadedEnv = loadEnv(lookUp(variable.owner));
      variable = variable.member_id;
    }
    
    if(variable is! Identifier)
      throw "Can't lookup value by using ${variable.runtimeType}";
    
    //TODO add static context! (may be added now)      
    var val = currentContext.lookUp(variable);
    
    if(val == null){
      if(loadedEnv)
        throw "Variable [${variable.name}] not declared.";
        
      val = staticContext.lookUp(variable);
    }
    
    if(loadedEnv)
      unloadEnv();
      
    return val;
  }
  
  dynamic lookUp(variable){
    var val = _lookUpAddress(variable);
    return val is Address ? values[val] : val;
  }
  
  bool isPrimitive(variable) => lookUp(variable) is! ClassScope;
  
  Address _newValue(ClassScope value){
    Address addr = new Address(++_counter);
    values[addr] = value;
    return addr;
  }
  
  callMemberMethod(select, List args) {
    if(select is MemberSelect){
      ClassScope env = lookUp(select.owner);
      loadEnv(env);
      select = select.member_id;
    }
    currentContext.loadMethod(select, args);
  }
  
  methodReturn(){
    currentContext.methodReturn();
  }
  
  bool loadEnv(Scope env){
    if(env is! ClassScope)
      throw "Can only load class scope as primary environment!";
    
    contextStack.addLast(env);
    return true;
  }
  
  unloadEnv(){
    contextStack.removeLast();
  }
}

class Address {
  final int addr;
  const Address(this.addr);
  static const invalid = const Address(-1);
  String toString() => "[$addr]";
  
  int get hashCode => 37 + addr;
  bool operator==(other){
    if(identical(other, this))
      return true;
    return addr == other.addr;
  }
}

class Scope {
  final Map<Identifier, dynamic> assignments = new Map<Identifier, dynamic>();
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
  
  void newVariable(Identifier name, [dynamic value = Address.invalid]){
    if(_subscope != null){
        _subscope.newVariable(name, value);
    }
    else {
      assignments[name] = value;
      print("declaring: $name ${value is Address ? " at [${value}]" : ""} with value $value of type ${value.runtimeType}");
    }
  }
  
  bool assign(Identifier name, dynamic value){
    if(_subscope != null && _subscope.assign(name, value))
      return true;
    
    if(!assignments.containsKey(name))
      return false;
        
    assignments[name] = value;
    return true;
  }
  
  dynamic lookUp(Identifier variable){
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
  
  void newVariable(Identifier name, [dynamic value = Address.invalid]){
    if(_subscopes.isEmpty)
      super.newVariable(name, value);
    else
    _subscopes.last.newVariable(name, value);
  }
  
  bool assign(Identifier name, dynamic value){
    if(!_subscopes.isEmpty && _subscopes.last.assign(name, value))
        return true;
    
    return super.assign(name, value);
  }
  
  dynamic lookUp(Identifier variable){
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