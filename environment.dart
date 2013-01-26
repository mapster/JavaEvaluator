part of JavaEvaluator;

class Environment {
  int _counter = 0;
  final Map<Address, dynamic> values = new Map<Address, dynamic>();
//  final List<Scope> programstack = [new Scope.block([])];
//  
  void popScope(){ contextStack.removeLast(); }
  void addBlockScope(statements){ contextStack.addLast(new Scope.block(statements)); }
//  void addMethod(statements){ programstack.addLast(new Scope.block(statements)); }
//  
  Scope staticContext = new Scope.block([]);
  List<Scope> contextStack = [];
  Scope get currentContext => contextStack.last;
  
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
  
  void newStaticClass(ClassScope clazz){
    staticContext.newVariable(new Identifier(clazz.clazz.name),_newValue(clazz));
  }
  
  void newVariable(Identifier name, [dynamic value = Address.invalid]){
    if(value is ClassScope)
      value = _newValue(value);
    
    else currentContext.newVariable(name, value);
  }
  
  void assign(Identifier name, dynamic value){
    if(value is ClassScope)
      value = _newValue(value);      
    
    currentContext.assign(name, value);
  }

  /**
   * Initializes a class instance, i.e. stores all fields with an initial value in memory and returns the class environment.
   */
  //TODO potential mess with primitive values
  ClassScope newClassInstance(ClassDecl clazz, [bool static = false]){
    List<Variable> variables = static ? clazz.staticVariables : clazz.instanceVariables;
    Map<Identifier, dynamic> addr = new Map<Identifier, dynamic>();
    print("new class with: ${variables.length}");
    variables.forEach((v){
      Identifier id = new Identifier(v.name);
      addr[id] = _lookUpAddress(id);
    });
    
    return new ClassScope(clazz, addr, static);
  }
  
  dynamic _lookUpAddress(variable){
    bool loadedEnv = false;
    if(variable is MemberSelect){
      loadedEnv = loadEnv(lookUp(variable.owner));
      variable = variable.member_id;
    }
    
    if(variable is! Identifier)
      throw "Can't lookup value by using ${variable.runtimeType}";
    
    //TODO add static context!      
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

  callMemberMethod(MemberSelect select, List<dynamic> args) {
    ClassScope env = lookUp(select.owner);
    loadEnv(env);
    env.loadMethod(select.member_id, args);
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
  
  Scope.block(List statements) : isMethod = false { _statements.addAll(statements); }
  Scope.method(List statements) : isMethod = true { _statements.addAll(statements); }
  
  void newVariable(Identifier name, [dynamic value = Address.invalid]){
    if(_subscope != null){
        _subscope.newVariable(name, value);
    }
    else {
      assignments[name] = value;
      print("declaring: $name ${assignments[name] is Address ? " at [${assignments[name]}]" : ""} with value $value of type ${value.runtimeType}");
    }
  }
  
  void assign(Identifier name, dynamic value){
    if(_subscope != null){
      _subscope.newVariable(name, value);
    }
    else {
      if(!assignments.containsKey(name))
        throw "Variable [${name.name}] is not declared!";
        
      assignments[name] = value;  
    }
  }
  
  dynamic lookUp(Identifier variable){
    if(_subscope != null){
      return _subscope.lookUp(variable);
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
}

class ClassScope extends Scope {
  final List<Scope> _subscopes = new List<Scope>();
  final ClassDecl clazz;
  final bool isStatic;
  
  ClassScope(this.clazz, Map<Identifier, dynamic> initialValues, this.isStatic) : super.block([]){
    initialValues.forEach((Identifier id, value){
      assignments[id] = value;
    });
  }

  addSubScope(Scope s) => _subscopes.add(s);
  
  void newVariable(Identifier name, [dynamic value = Address.invalid]){
    if(_subscopes.isEmpty)
      super.newVariable(name, value);
    _subscopes.last.newVariable(name, value);
  }
  
  void assign(Identifier name, dynamic value){
    if(_subscopes.isEmpty)
      super.assign(name, value);
    _subscopes.last.assign(name, value);
  }
  
  dynamic lookUp(Identifier variable){
    if(_subscopes.isEmpty)
      return super.lookUp(variable);
    _subscopes.last.lookUp(variable);    
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
        if(p.id.toLowerCase() != a.runtimeType.toLowerCase())
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