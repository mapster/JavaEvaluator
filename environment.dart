part of JavaEvaluator;

class Environment {
  int _counter = 0;
  final Map<Address, dynamic> values = new Map<Address, dynamic>();
//  final List<Scope> programstack = [new Scope.block([])];
//  
//  void popScope(){ contextStack.removeLast(); }
  void addBlockScope(statements){ contextStack.addLast(new Scope.block(statements)); }
//  void addMethod(statements){ programstack.addLast(new Scope.block(statements)); }
//  
  Scope staticContext = new Scope.block([]);
  List<ClassScope> contextStack = [];
  ClassScope get currentContext => contextStack.last;
  Scope get currentScope => currentContext.currentScope;
  
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
  
//  void newStaticClass(ClassScope clazz){
//    staticContext.newVariable(new Identifier(clazz.clazz.name),_newValue(clazz));
//  }
  
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
    
//    List<Variable> variables = static ? clazz.staticVariables : clazz.instanceVariables;
//    Map<Identifier, dynamic> addr = new Map<Identifier, dynamic>();
//    print("new class with: ${variables.length}");
//    variables.forEach((v){
//      Identifier id = new Identifier(v.name);
//      addr[id] = _lookUpAddress(id);
//    });
//    
//    return new ClassScope(clazz, addr, static);
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
  
  Address _newValue(ClassScope value){
    Address addr = new Address(++_counter);
    values[addr] = value;
    return addr;
  }
  
//  Address _lookUpAddress(Identifier name){
//    Map<Identifier, dynamic> scope = _findScope(name);
//    if(scope != null)
//      return scope[name];
//    
//    throw "Variable [${name.name}] is not declared!";
//  }
//  
//  Map<Identifier, dynamic> _findScope(Identifier name){
//    for(int i = assignments.length-1; i >= 0; i--){
//      Map<Identifier, dynamic> scope = assignments[i];
//      if(scope.containsKey(name))
//        return scope;
//    }
//    return null;
//  }

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

//class ClassEnv {
//  final ClassDecl decl;
//  final Map<Identifier, dynamic> _variables = new Map<Identifier, dynamic>();
//  final bool _static;
//  
//  ClassEnv(this.decl, Map<Identifier, dynamic> initialValues, [this._static = false]){
//    initialValues.keys.forEach((name){
//      if((_static && !decl.staticVariables.where((e) => e.name == name.name).isEmpty) || 
//          (!_static && !decl.instanceVariables.where((e) => e.name == name.name).isEmpty))
//        _variables[name] = initialValues[name];
//      else
//        throw "Class ${decl.name} has no${_static ? " static" : ""} variable named ${name}";
//      });
//  }
//  
//  List<MethodDecl> getMethods() => (_static ? decl.staticMethods : decl.instanceMethods);
//  
//  /**
//   * Returns address or primitive value of named variable. 
//   */
//  dynamic lookUp(Identifier name){
//    return _variables[name];
//  }
//}

class Scope {
  final Map<Identifier, dynamic> assignments = new Map<Identifier, dynamic>();
  final List<dynamic> _statements = [];
  final bool isMethod;
  Scope _subscope;
  
  Scope get currentScope => _subscope != null ? _subscope.currentScope : this; 
  
  Scope.block(List statements) : isMethod = false { _statements.addAll(statements); }
  Scope.method(List statements) : isMethod = true { _statements.addAll(statements); }
  
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
  
//  bool methodReturn(){
//    if(_subscope == null)
//      return false;
//
//    //returned from method
//    if(_subscope.methodReturn())
//      return true;
//      
//
//    //Not return from method yet, so remove subscope
//    _subscope = null;
//    return isMethod;
//  }
}

class ClassScope extends Scope {
  final List<Scope> _subscopes = new List<Scope>();
  final ClassDecl clazz;
  final bool isStatic;
  
  Scope get currentScope => _subscopes.last.currentScope;
  
  ClassScope(this.clazz, this.isStatic) : super.block([]){
    if(isStatic){
      _statements.addAll(clazz.staticVariables);
    }
  }

  addSubScope(Scope s) => _subscopes.add(s);
  
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
  
  bool _checkParamArgTypeMatch(List<Type> parameters, List<dynamic> args) {
    if(parameters.length != args.length)
      return false;
    
    for(int i = 0; i < parameters.length; i++){
      Type p = parameters[i];
      var a = args[i];

      //both primitive
      if(p.isPrimitive && a is! ClassScope){
        if(p.id.toLowerCase() != "${a.runtimeType}".toLowerCase())
          return false;
      }
      //both declared
      else if(!p.isPrimitive && a is ClassScope){
        if(p.id != a.clazz.name)
          return false;
      }
    }
    return true;
  }
}