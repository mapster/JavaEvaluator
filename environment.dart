part of JavaEvaluator;

class Environment {
  int _counter = 0;
  Evaluator _evaluator;
  List<MethodScope> methodStack = new List<MethodScope>();
  Map<ReferenceValue, dynamic> values = new Map<ReferenceValue, dynamic>();
  Map<Identifier, Package> packages = new Map<Identifier, Package>();
  BlockScope get currentBlock => methodStack.last.currentBlock;
  
  Environment(){
    packages[Identifier.DEFAULT_PACKAGE] = new Package(Identifier.DEFAULT_PACKAGE);
    _evaluator = new Evaluator(this);
  }
  
  dynamic _lookup(final dynamic select){
    Identifier name;
    dynamic parent = methodStack.last;
    
    //recursive lookup
    if(select is MemberSelect){
      parent = _lookup(select.owner);
      if(parent is ReferenceValue)
        parent = values[parent];
      
      name = select.member_id;
    }
    else name = select;

    //lookup of class should only be allowed if parent is Package
    if(parent is Package){
      return parent.getMember(name);
    }
    
    //check if it is a variable, this must be the first lookup, since it trumps every other 
    Value val = parent.lookup(name);
    if(val != null)
      return val;
    
    //if this is the root of the lookup, i.e. ${select is Identifier}, then we can allow to look 
    //for imports in the parent (class it belongs to) of the current method scope and
    //in the list of root packages
    if(select is Identifier){
      StaticClass c = methodStack.last.lookupClass(select);
      if(c != null)
        return c;
      
      if(packages.containsKey(select))
        return packages[select];
    }
    
    if(parent is StaticClass){
      throw "Don't support lookup in inner classes yet!";
    }
    
    throw "Uncovered lookup case..."; 
  }
  
  Value lookup(name){
    print("Looking up: $name");
    if(name is Identifier)
      return methodStack.last.lookup(name);
    
    return _lookup(name);
  }
  
  dynamic _lookupClass(select){
    //if this is the root of the lookup, i.e. ${select is Identifier}, then we can allow to look 
    //for imports in the parent (class it belongs to) of the current method scope and
    //in the list of root packages
    if(select is Identifier){
      StaticClass c = methodStack.last.lookupClass(select);
      if(c != null)
        return c;
      
      if(packages.containsKey(select))
        return packages[select];
    }
    
    assert(select is MemberSelect);
    
    //recursive lookup
    var parent = _lookupClass(select.owner);
    assert(parent is StaticClass || parent is Package);
    Identifier name = select.member_id;

    if(parent is Package){
      return parent.getMember(name);
    }
    else if(parent is StaticClass){
      throw "Don't support lookup for inner classes yet!";
    }
    
    throw "Uncovered lookup case..."; 
  }
  
  StaticClass lookupClass(select){
    return _lookupClass(select); 
  }
  
  void assign(final dynamic select, Value value){
    print("assigning to: $select");
    if(select is Identifier){
      methodStack.last.assign(select, value);
    }
    else {
      assert(select is MemberSelect);
      var clazz = _lookup(select.owner);
      if(clazz is ReferenceValue)
        clazz = values[clazz];
      
      assert(clazz is ClassScope);
      clazz.assign(select.member_id, value);
    }
  }
  
  void newVariable(Identifier name, [Value value = ReferenceValue.invalid]){
    methodStack.last.newVariable(name, value);
  }
  
  ReferenceValue addLibraryObject(dynamic obj){
    ReferenceValue ref = new ReferenceValue(_counter++);
    values[ref] = obj;
    return ref;
  }
  
  ReferenceValue newObject(StaticClass clazz, List<Value> constructorArgs){
    List<EvalTree> initializers = new List<EvalTree>();
    ClassInstance inst = new ClassInstance(clazz);
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
 
    loadScope(new MethodScope(initializers, inst));
    
    return _newValue(inst);
  }
  
  void arrayAssign(ReferenceValue array, int index, Value value) {
    (values[array] as Array)[index] = value;
  }
  
  Value getArrayValue(ReferenceValue array, int index){
    return values[array][index];
  }
  
  ReferenceValue newArray(int size, Value value, TypeNode type) {
    return _newValue(new Array(size, value, type));
  }
  
  ReferenceValue _newValue(dynamic value){
    ReferenceValue addr = new ReferenceValue(++_counter);
    values[addr] = value;
    return addr;
  }
  
  bool get isDone {
    if(methodStack.any((MethodScope m) => !m.isDone))
      return false;
    
    return true;
  }
  
  dynamic popStatement(){
    while(!methodStack.isEmpty && methodStack.last.isDone)
      methodStack.removeLast();
    return methodStack.last.popStatement();
  }
  
  void loadMethod(Identifier name, List args, {StaticClass inClass}) {
    ClassScope parent = methodStack.last.parentScope;
    if(?inClass)
      parent = inClass;
    
    MethodDecl method = parent.methods.singleMatching((MethodDecl m) 
        => m.name == name.name && _checkParamArgTypeMatch(m.type.parameters, args.map(typeOf).toList()));
    
    methodStack.add(new MethodScope(method.body, parent));
    
    for(int i = 0; i < method.parameters.length; i++){
      newVariable(new Identifier.fixed(method.parameters[i].name), args[i]);
    }
    
    print("loading method: $name");
  }
  
  void addBlockScope(List statements){
    methodStack.last.addBlock(new BlockScope(statements));
  }
  
  void methodReturn() { methodStack.removeLast(); }
  void loadScope(MethodScope scope){ methodStack.add(scope); }
  
  TypeNode typeOf(dynamic val){
    if(val is ReferenceValue)
      val = values[val];
    
    if(val is ClassScope){
      return new TypeNode(new Identifier.fixed(val.name.name));
    }
    else if(val is PrimitiveValue){
      return new TypeNode(val.type);
    }
    else if(val is Array){
      return val.type;
    }
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
  Map<Identifier, Value> get variables => new Map.from(_variables); 
  
  Value _lookup(Identifier name) => _variables[name];
  void _newVariable(Identifier name, [Value value = ReferenceValue.invalid]){ _variables[name] = value; }
  bool _assign(Identifier name, Value value){
    if(_variables.containsKey(name)){
      _variables[name] = value;
      return true;
    }
    return false;
  }
  
  Value lookup(Identifier name);
  void newVariable(Identifier name, [Value value]);
  bool assign(Identifier name, Value value);
}

class BlockScope extends Scope {
  final List<dynamic> _statements; 
  BlockScope subScope;
  BlockScope get currentBlock => subScope == null ? this : subScope.currentBlock; 
  
  BlockScope(List<dynamic> statements) : this._statements = statements.toList();
  
  void addBlock(BlockScope block){
    if(subScope == null)
      subScope = block;
    else
      subScope.addBlock(block);
  }
  
  Value lookup(Identifier name){
    Value val;
    if(subScope != null)
      val = subScope.lookup(name);
    if(val != null)
      return val;
    
    return _lookup(name);
  }
  
  void newVariable(Identifier name, [Value value]){
    if(subScope != null)
      subScope.newVariable(name, value);
    else
      _newVariable(name, value);
  }
  
  bool assign(Identifier name, Value value){
    if(subScope != null && subScope.assign(name, value))
      return true;
    
    return _assign(name, value);
  }
  
  StaticClass lookupClass(Identifier name) => null;
  
  
  void pushStatement(dynamic statement) {
    if(subScope != null)
      subScope.pushStatement(statement);
    else
      _statements.insertRange(0, 1, statement);
  }
  
  dynamic popStatement() {
    //remove subScope if it is empty
    if(subScope != null && subScope.isDone)
      subScope = null;
    
    if(subScope != null){
      assert(!subScope.isDone);
      return subScope.popStatement();
    }
    
    return _statements.removeAt(0);
  }
  
  bool get isDone {
    if(subScope != null && !subScope.isDone)
      return false;
    
    return _statements.isEmpty;
  }
}

class MethodScope extends BlockScope {
  final ClassScope parentScope;
  
  MethodScope(List<dynamic> statements, ClassScope this.parentScope) : super(statements);
  
  StaticClass lookupClass(Identifier name) => parentScope.lookupClass(name);
  
  Value lookup(Identifier name){
    Value val = super.lookup(name);
    if(val != null)
      return val;

    return parentScope.lookup(name);
  }
  
  bool assign(Identifier name, Value value){
    if(super.assign(name, value))
      return true;
    
    return parentScope.assign(name, value);
  }
}

abstract class ClassScope extends Scope {
  StaticClass lookupClass(Identifier name);
  List<MethodDecl> get methods;
  Identifier get name;
  
  String toString() => "${_variables}";
}

class StaticClass extends ClassScope {
  Package _package;
  ClassDecl _declaration;
  final Map<Identifier, StaticClass> _importedClasses = new Map<Identifier, StaticClass>();
  final Map<Identifier, Package> _importedPackages = new Map<Identifier, Package>();
  Package get package => _package;
  Identifier get name => _declaration.name;
  List<MethodDecl> get methods => _declaration.staticMethods;
  
  StaticClass(ClassDecl this._declaration, Package this._package);
  StaticClass.empty();
  
  void addImport(dynamic import) {
    if(import is StaticClass)
      _importedClasses[import.name] = import;
    else if(import is Package)
      _importedPackages[import.name] = import;
    else
      throw "Can't add object of type ${import.runtimeType} as import to class $name";
  }
  
  StaticClass lookupClass(Identifier name) {
    if(name == _declaration.name)
      return this;
    
    if(_importedClasses.containsKey(name))
      return _importedClasses[name];
    
    for(Package p in _importedPackages.values){
      StaticClass c = p.getClass(name);
      if(c != null)
        return c;
    }
    
    return package.getClass(name);
  }
  
  Value lookup(Identifier name){
    print("Looking for $name => ${_lookup(name)} in ${this.name}.");
    return _lookup(name);
  }
  
//  => _lookup(name);
  
  void newVariable(Identifier name, [Value value]){
    _newVariable(name, value);
  }
  
  bool assign(Identifier name, Value value) => _assign(name, value);
}

class ClassInstance extends ClassScope {
  final StaticClass _static;
  Identifier get name => _static.name;
  List<MethodDecl> get  methods => new List<MethodDecl>()
                                        ..addAll(_static._declaration.instanceMethods)
                                        ..addAll(_static._declaration.staticMethods);
  
  ClassInstance(StaticClass this._static);
  
  StaticClass lookupClass(Identifier name) => _static.lookupClass(name);
  
  Value lookup(Identifier name) {
    Value val = _lookup(name);
    if(val != null)
      return val;
    
    return _static.lookup(name);
  }

  void newVariable(Identifier name, [Value value]){
    _newVariable(name, value);
  }
  
  bool assign(Identifier name, Value value){
    if(_assign(name, value))
      return true;
    
    return _static.assign(name, value);
  }
}

class Package {
  final Identifier name;
  final Map<String, dynamic> _members;
  
  Package(this.name) : _members = new Map<String, dynamic>();
  const Package.fixed(this.name, this._members);
  
  void addMember(member){
    assert(member is Package || member is StaticClass);
    _members[member.name.name] = member;
  }
  
  dynamic getMember(Identifier name) => _members[name.name];
  StaticClass getClass(Identifier name) => _members[name.name];
  Package getPackage(Identifier name) => _members[name.name];
  
  List<Package> get getPackages => _members.values.where((m) => m is Package).toList();
  List<StaticClass> get getClasses => _members.values.where((c) => c is StaticClass).toList();
}