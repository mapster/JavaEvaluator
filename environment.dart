part of JavaEvaluator;

class Environment {
  int _counter = 0;
  final Map<int, dynamic> values = new Map<int, dynamic>();
  final List<Map<Identifier, int>> assignments = [new Map<Identifier, int>()];
  
  void popScope(){ assignments.removeLast(); }
  void addScope(){ assignments.addLast(new Map<Identifier, int>()); }
  
  void newVariable(Identifier name, [dynamic value]){
    if(?value)
      assignments.last[name] = _getAddress(value);
    else
      assignments.last[name] = -1;
    print("declaring: $name at [${assignments.last[name]}] with value $value of type ${value.runtimeType}");
  }
  
  void assign(Identifier name, dynamic value){
    Map<Identifier, int> scope = _findScope(name);
    if(scope != null){
      scope[name] = _getAddress(value);
      return;
    }
    throw "Variable [${name.name}] does not exist!";
  }

  /**
   * Initializes a class instance, i.e. stores all fields with an initial value in memory and returns the class environment.
   */
  ClassEnv newClassInstance(ClassDecl clazz, Map<String, Identifier> initialValues, [bool static = false]){
    Map<String, int> addr = new Map<String, int>();
    for(String key in initialValues.keys){
      addr[key] = _lookUpAddress(initialValues[key]);
    }
    return new ClassEnv(clazz, addr, static);
  }
  
  dynamic lookUp(variable){
    if(variable is Identifier){
      Map<Identifier, int> scope = _findScope(variable);
      if(scope != null){
        return values[scope[variable]];
      }
      
      throw "Variable [${variable.name}] not declared.";
    }
    else if(variable is MemberSelect){
      return values[lookUp(variable.owner).lookUpAdress(variable.member_id)];
    }
    else throw "Can't lookup value by using ${variable}";    
  }
  
  /**
   * Will return the address of value if it is an Identifier, or allocate it in memory and return the address.
   */
  int _getAddress(dynamic value){
    if(value is Identifier)
      return _lookUpAddress(value);
    else
      return _newValue(value);
  }
  
  int _newValue(dynamic value){
    values[++ _counter] = value;
    return _counter;
  }
  
  int _lookUpAddress(Identifier name){
    Map<Identifier, int> scope = _findScope(name);
    if(scope != null)
      return scope[name];
    
    throw "Variable [${name.name}] not currently assigned!";
  }
  
  Map<Identifier, int> _findScope(Identifier name){
    for(int i = assignments.length-1; i >= 0; i--){
      Map<Identifier, int> scope = assignments[i];
      if(scope.containsKey(name))
        return scope;
    }
    return null;
  }
}

class ClassEnv {
  final ClassDecl decl;
  final Map<String, int> _variables = new Map<String, int>();
  final bool _static;
  
  ClassEnv(this.decl, Map<String, int> initialValues, [this._static = false]){
    initialValues.keys.forEach((name){
      if((_static && decl.staticVariables.containsKey(name)) || !_static && decl.instanceVariables.containsKey(name))
        _variables[name] = initialValues[name];
      else
        throw "Class ${decl.name} has no${_static ? " static" : ""} variable named ${name}";
      });
  }
  
  List<MethodDecl> getMethods() => (_static ? decl.staticMethods : decl.instanceMethods);
  
  int lookUpAdress(String name){
    return _variables[name];
  }
}
