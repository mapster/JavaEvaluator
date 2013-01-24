part of JavaEvaluator;

class Environment {
  int _counter = 0;
  final Map<Address, dynamic> values = new Map<Address, dynamic>();
  final List<Map<Identifier, dynamic>> assignments = [new Map<Identifier, dynamic>()];
  
  void popScope(){ assignments.removeLast(); }
  void addScope(){ assignments.addLast(new Map<Identifier, dynamic>()); }
  
  void newVariable(Identifier name, [dynamic value]){
    assignments.last[name] = Address.invalid;
    
    if(?value){
      if(value is ClassEnv)
        value = _newValue(value);
      assign(name, value);
    }

    print("declaring: $name ${assignments.last[name] is Address ? " at [${assignments.last[name]}]" : ""} with value $value of type ${value.runtimeType}");
  }
  
  void assign(Identifier name, dynamic value){
    Map<Identifier, dynamic> scope = _findScope(name);
    if(scope != null){
      if(value is Identifier)
        scope[name] = _lookUpAddress(value);
      else
        scope[name] = value;
    }
    else throw "Variable [${name.name}] is not declared!";
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
    if(variable is Identifier){
      Map<Identifier, dynamic> scope = _findScope(variable);
      if(scope != null){
        if(scope[variable] is Address)
          return values[scope[variable]];
        else 
          return scope[variable];
      }
      
      throw "Variable [${variable.name}] not declared.";
    }
    else if(variable is MemberSelect){
      var owner = lookUp(variable.owner);
      if(owner is! ClassEnv)
        throw "Can't select member of a primitive value.";
      
      var member = owner.lookUp(variable.member_id);
      if(member is Address)
        return values[member]; 
      else
        return member;
    }
    else throw "Can't lookup value by using ${variable}";    
  }
  
  Address _newValue(dynamic value){
    Address addr = new Address(++_counter);
    values[addr] = value;
    return addr;
  }
  
  Address _lookUpAddress(Identifier name){
    Map<Identifier, dynamic> scope = _findScope(name);
    if(scope != null)
      return scope[name];
    
    throw "Variable [${name.name}] is not declared!";
  }
  
  Map<Identifier, dynamic> _findScope(Identifier name){
    for(int i = assignments.length-1; i >= 0; i--){
      Map<Identifier, dynamic> scope = assignments[i];
      if(scope.containsKey(name))
        return scope;
    }
    return null;
  }
}

class Address {
  final int addr;
  const Address(this.addr);
  static const invalid = const Address(-1);
  String toString() => "[$addr]";
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
