part of JavaEvaluator;

class Environment {
  Evaluator _evaluator;
  int _counter = 1;
  final Map<ReferenceValue, dynamic> values = new Map<ReferenceValue, dynamic>();
  final List<ClassScope> instanceStack = new List<ClassScope>();
  Package get defaultPackage => packages[Identifier.DEFAULT_PACKAGE]; 
  final Map<Identifier, Package> packages = new Map<Identifier, Package>();
  Scope get currentScope => instanceStack.last.currentScope;
  
  Environment(){
    packages[Identifier.DEFAULT_PACKAGE] = new Package(Identifier.DEFAULT_PACKAGE);
    _evaluator = new Evaluator(this);
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
  
  Value lookupVariable(Identifier name, {parent}){
    //Check in current class instance for the variable (both static and instance)
    if(?parent){
      print("Looking up: $name in ${parent}");
      if(parent is ReferenceValue)
        return values[parent].lookupVariable(name);
      else
        throw "Can't lookup $name in a parent of type ${parent.runtimeType}";
    }
    
    print("Looking up: $name");
    return  instanceStack.last.lookupVariable(name);
  }
  
  StaticClass lookupClass(select){
    print("Looking up class: $select");
    StaticClass clazz = instanceStack.last.lookupClass(select);
    if(clazz != null)
      return clazz;
    
    if(select is MemberSelect){
      List<Identifier> selectTree = new List<Identifier>();
      while(select is MemberSelect){
        selectTree.add(select.member_id);
        select = select.owner;
      }

      Package root = packages[select as Identifier];
      //must exist a root package
      if(root == null)
        throw "Unable to find package '$select'!";
      
      //climb the package tree untill a class is found
      while(!selectTree.isEmpty && root != null){
        Identifier name = selectTree.removeLast();
        Package pkg = root.lookupPackage(name);
        if(pkg == null)
          clazz = root.lookupClass(name);
      }
      
      //then climb for subclasses, as a class cannot have child packages
      while(!selectTree.isEmpty){
        clazz = clazz.lookupClass(selectTree.removeLast());
      }
      
      if(clazz == null)
        throw "No class found!";
      
      return clazz;
    }
    
    throw "Unable to lookup class!";
  }
  
  ReferenceValue newObject(StaticClass clazz, List<Value> constructorArgs){
    List<EvalTree> initializers = new List<EvalTree>();
    ClassInstance inst = new ClassInstance(clazz, initializers);
    //declare all variables and create assignments of the initializers
    clazz._declaration.instanceVariables.forEach((Variable v){
      Identifier id = new Identifier.fixed(v.name);
      inst.newVariable(id);
      if(v.initializer != null)
        initializers.add(new EvalTree(v, _evaluator, (List args) => assign(id, args.first), [v.initializer]));
    });
    
    //add method call to constructor
    initializers.add(new EvalTree(null, _evaluator, (List args){
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

  void loadMethod(Identifier name, List args, {StaticClass inClass}) {
    if(?inClass)
      loadClassScope(inClass);
    
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
  
  void loadClassScope(StaticClass clazz){
    instanceStack.addLast(clazz);
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
  Map<Identifier, ClassScope> get _importedClasses;
  Map<Identifier, Package> get _importedPackages;
  Package get package;
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
  
  ClassScope lookupClass(select){
    //climb memberselect tree and add selectors in stack
    List<Identifier> selectStack = new List<Identifier>();
    if(select is MemberSelect){
      while(select is MemberSelect){
        selectStack.add(select.member_id);
        select = select.owner;
      }
    }
    
    //root, $select, of memberselect tree must be a class available through imports or in same package
    //if select is identifier, we now that is must be a class available either as an imported class or in the package
    StaticClass clazz;
    if(select is Identifier){
      clazz = package.lookupClass(select);
      
      if(clazz == null) //not in same package, look in imported classes
        clazz = _importedClasses[name];
      
      if(clazz == null){  //also not an imported class, check star imports
        //iterate over packages and check if it has class.
        _importedPackages.values.forEach((Package pkg){ 
          StaticClass tmp = pkg.lookupClass(name);
          if(tmp != null)
            clazz = tmp;
        });  
      }
    }

    //if null then no class can be found in imports or package, both when original select is identifier and memberselect
    if(clazz == null)
      return null;
    
    //look through the memberselect tree.
    while(!selectStack.isEmpty){
      clazz = clazz.lookupClass(selectStack.removeLast());
      if(clazz == null)//should not occur!
        throw "Error looking up class!!";
    }
    
    return clazz;
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
  ClassDecl _declaration;
//  final Map<Identifier, ReferenceValue> _localClasses = new Map<Identifier, ReferenceValue>();
  Package _package;
  List<MethodDecl> get methodDeclarations => _declaration.staticMethods;
  Map<Identifier, StaticClass> _importedClasses = new Map<Identifier, StaticClass>();
  Map<Identifier, Package> _importedPackages = new Map<Identifier, Package>();
  Identifier get name => _declaration.name;
  Package get package => _package;
  
  StaticClass(Package this._package, ClassDecl this._declaration, List<dynamic> statements) : super(statements);
  StaticClass.empty() : super(new List());
  
  String toString() => name.toString();
  
  void addImport(dynamic import) {
    if(import is StaticClass)
      _importedClasses[import.name] = import;
    else if(import is Package)
      _importedPackages[import.name] = import;
    else
      throw "Can't add object of type ${import.runtimeType} as import to class $name";
  }
}

class ClassInstance extends ClassScope {
  final StaticClass _static;
  Package get package => _static.package;
  Map<Identifier, StaticClass> get _importedClasses => _static._importedClasses;
  Map<Identifier, Package> get _importedPackages => _static._importedPackages;
  List<MethodDecl> get methodDeclarations => new List<MethodDecl>()
      ..addAll(_static._declaration.staticMethods)..addAll(_static._declaration.instanceMethods);
  Identifier get name => _static.name;
  
  ClassInstance(StaticClass this._static, List<dynamic> statements) : super(statements);
  
  String toString() => "${_variables}";
}

class Package {
  final Identifier name;
  final Map<Identifier, Package> _memberPackages = new Map<Identifier, Package>();
  final Map<Identifier, StaticClass> _memberClasses = new Map<Identifier, StaticClass>();
  
  Package(this.name);
  
  void addClass(StaticClass clazz) {
    if(_memberPackages.containsKey(clazz.name))
      throw "Can't add member class to the package ${this.name}, already a child package with the name ${clazz.name}.";
    if(_memberClasses.containsKey(clazz.name))
      throw "There already exist a member class with the name ${clazz.name} in the package ${this.name}";
    
    print("package ${this.name}: adding member class -> ${clazz.name}");
    _memberClasses[clazz.name] = clazz; 
  }
  
  void addPackage(Package package) {
    if(_memberClasses.containsKey(package.name))
      throw "Can't add member package to the package ${this.name}, already a child class with the name ${package.name}.";
    if(_memberPackages.containsKey(package.name))
      throw "There already exist a member package with the name ${package.name} in the package ${this.name}";
    
    print("package ${this.name}: adding member package -> ${package.name}");
    _memberPackages[package.name] = package; 
  } 
  
  StaticClass lookupClass(Identifier name) => _memberClasses[name];
  Package lookupPackage(Identifier name) => _memberPackages[name];
}
