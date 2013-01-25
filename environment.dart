part of JavaEvaluator;

class Environment {
  int _counter = 0;
  final Map<Address, dynamic> values = new Map<Address, dynamic>();
//  final List<Scope> programstack = [new Scope.block([])];
//  
//  void popScope(){ programstack.removeLast(); }
//  void addBlock(statements){ programstack.addLast(new Scope.block(statements)); }
//  void addMethod(statements){ programstack.addLast(new Scope.block(statements)); }
//  
  Scope staticContext = new Scope.block([]);
  Scope currentContext;
  
  void newVariable(Identifier name, [dynamic value]){
    if(!?value)
      value = Address.invalid;
    else if(value is ClassScope)
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
  ClassEnv newClassInstance(ClassDecl clazz, List<Identifier> initialValues, [bool static = false]){
    Map<Identifier, dynamic> addr = new Map<Identifier, dynamic>();
    for(Identifier key in initialValues){
      addr[key] = _lookUpAddress(key);
    }
    return new ClassEnv(clazz, addr, static);
  }
  
  dynamic lookUp(variable){
    if(variable is! MemberSelect && variable is! Identifier)
      throw "Can't lookup value by using ${variable.runtimeType}";
    
    var val = null;
    if(variable is MemberSelect)
      val = staticContext.lookUp(variable);
    
    if(val == null)
        val = currentContext.lookUp(variable);
    
    if(val == null)
      throw "Variable [${variable.name}] not declared.";
    
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
  
  void loadEnv(Scope env){
    if(env is! ClassScope)
      throw "Can only load class scope as primary environment!";
    programstack.addLast(env);
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

class ClassEnv {
  final ClassDecl decl;
  final Map<Identifier, dynamic> _variables = new Map<Identifier, dynamic>();
  final bool _static;
  
  ClassEnv(this.decl, Map<Identifier, dynamic> initialValues, [this._static = false]){
    initialValues.keys.forEach((name){
      if((_static && !decl.staticVariables.where((e) => e.name == name.name).isEmpty) || 
          (!_static && !decl.instanceVariables.where((e) => e.name == name.name).isEmpty))
        _variables[name] = initialValues[name];
      else
        throw "Class ${decl.name} has no${_static ? " static" : ""} variable named ${name}";
      });
  }
  
  List<MethodDecl> getMethods() => (_static ? decl.staticMethods : decl.instanceMethods);
  
  /**
   * Returns address or primitive value of named variable. 
   */
  dynamic lookUp(Identifier name){
    return _variables[name];
  }
}

class Scope {
  final Map<Identifier, dynamic> assignments = new Map<Identifier, dynamic>();
  final List<dynamic> statements;
  final bool isMethod;
  
  Scope.block(this.statements) : isMethod = false;
  Scope.method(this.statements) : isMethod = true;
  
  void newVariable(Identifier name, [dynamic value]){
    assignments[name] = Address.invalid;
    
    if(?value){
      assign(name, value);
    }

    print("declaring: $name ${assignments[name] is Address ? " at [${assignments[name]}]" : ""} with value $value of type ${value.runtimeType}");
  }
  
  void assign(Identifier name, dynamic value){
    if(!assignments.containsKey(name))
      throw "Variable [${name.name}] is not declared!";
      
    assignments[name] = value;
  }
  
  dynamic lookUp(variable){
    
  }
}

class ClassScope extends Scope {
  final List<Scope> _subscopes = new List<Scope>();
  final ClassDecl clazz;
  final bool isStatic;
  
  ClassScope(this.clazz) : isStatic = false, super.block([]);
  ClassScope.static(this.clazz) : isStatic = true, super.block([]);

  addSubScope(Scope s) => _subscopes.add(s);
  
  void assign(Identifier name, dynamic value){
    if(_subscopes.isEmpty)
      super.assign(name, value);
    _subscopes.last.assign(name, value);
  }
  
  void newVariable(Identifier name, [dynamic value]){
    if(_subscopes.isEmpty)
      super.newVariable(name, value);
    _subscopes.last.assign(name, value);
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
      if(p.isPrimitive && a is! ClassEnv){
        if(p.id.toLowerCase() != a.runtimeType.toLowerCase())
          return false;
      }
      //both declared
      else if(!p.isPrimitive && a is ClassEnv){
        if(p.id != a.decl.name)
          return false;
      }
    }
    return true;
  }
}