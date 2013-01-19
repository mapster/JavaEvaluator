part of JavaEvaluator;

class Runner {
//  List<Map<Identifier, dynamic>> environment = new List<Map<Identifier, dynamic>>();
  Environment environment = new Environment();
  Program program;
  List<List<ASTNode>> programstack = [];
  
  Runner(this.program) {
    programstack.add([new MethodCall.main(["streng argument til main"])]);
    program.classDeclarations.values.map(loadClass);
  }
  
  void loadClass(ClassDecl clazz) {
    environment.addScope();
    Map<String, Identifier> initialValues = new Map<String, Identifier>();
    clazz.staticVariables.values.forEach((variable) {
      if(variable.initializer != null){
        Identifier id = new Identifier(variable.name);
        environment.newVariable(id, _eval(variable.initializer));
        initialValues[id.name] = id;
      }
    });
    ClassEnv static = environment.newClassInstance(clazz, initialValues, true);
    environment.popScope();
    environment.newVariable(new Identifier(clazz.name), static);
  }
    
  void step(){
    _eval(_popStatement());
  }
  
  bool isDone(){
    if(programstack.isEmpty)
      return true;
    
    return programstack.every((s) => s.isEmpty);
  }
  
  ASTNode _popStatement(){
    //execution complete
    if(programstack.isEmpty)
      return null;
    //if no more statement in current scope, remove it
    if(programstack.last.isEmpty){
      _popScope();
      return _popStatement();      
    }
    
    return programstack.last.removeAt(0);
  }
  
  void _newScope(List<ASTNode> statements){
    programstack.addLast(statements);
    environment.addScope();
  }
  
  void _popScope(){
    programstack.removeLast();
    environment.popScope();
  }
  
  _eval(statement){
    if(statement is MethodDecl)
      _evalMethod(statement);
    else if(statement is Variable)
      _evalVariable(statement);
    else if(statement is MethodCall)
      _evalMethodCall(statement);
    else if(statement is Assignment)
      _evalAssignment(statement);
    else if(statement is int)
      return statement;
    else if(statement is If)
      return _evalIf(statement);
    else if(statement is BinaryOp)
      return _evalBinaryOp(statement);
    else if(statement is Identifier)
      return environment.lookUp(statement);
    else if(statement is String)
      return statement;
    else if(statement is Return)
      return _evalReturn(statement);
    else throw "Statement type not supported yet: ${statement.runtimeType} '$statement'";
  }

  _evalMethodCall(MethodCall call) {
    List<dynamic> args = call.arguments.map(_eval); 
    
    if(call.select is MemberSelect){
      String name = (call.select as MemberSelect).member_id;
      ClassEnv inst = environment.lookUp((call.select as MemberSelect).owner);
    
      MethodDecl method = inst.getMethods().filter((MethodDecl m){
       if(m.name != name)
         return false;
       
        return _checkParamArgTypeMatch(m.type.parameters, args);        
      }).first;
      
      //add method body as a new scope
      _newScope(method.body);
      
      for(int i = 0; i < method.parameters.length; i++){
        Variable v = method.parameters[i];
        environment.newVariable(new Identifier(v.name), args[i]);
      }
    }
    else throw "Currently only support member select method calls";   
  }

  bool _checkParamArgTypeMatch(List<Type> parameters, List<dynamic> args) {
    if(parameters.length != args.length)
      return false;
    
    for(int i = 0; i < parameters.length; i++){
      Type p = parameters[i];
      var a = args[i];

      //both primitive
      if(p.isPrimitive() && a is! ClassEnv){
        if(p.type.toLowerCase() != a.runtimeType.toLowerCase())
          return false;
      }
      //both declared
      else if(!p.isPrimitive() && a is ClassEnv){
        if(p.type != a.decl.name)
          return false;
      }
    }
    return true;
  }
  
  
  _evalMethod(MethodDecl method){
    for(dynamic statement in method.body){
      _eval(statement);
    }
  }
  
  _evalBinaryOp(BinaryOp binary) {
    switch(binary.type){
      case BinaryOp.EQUAL:      
        return _eval(binary.left) == _eval(binary.right);
      default:
        throw "Binary operator not supported yet: ${binary.type}";
    }
  }

  _evalIf(If ifStat){
    if(_eval(ifStat.condition)){
      _newScope(ifStat.then);
    }
    else if(ifStat.elze != null){
      _newScope(ifStat.elze);      
    }
  }
  _evalAssignment(Assignment assign) {
    environment.assign(assign.id, _eval(assign.expr));
  }

  _evalVariable(Variable variable) {
    if(variable.initializer != null)
      environment.newVariable(new Identifier(variable.name), _eval(variable.initializer));
    else
      environment.newVariable(new Identifier(variable.name));
      
  }
  
  _evalReturn(Return ret){
    var toReturn = _eval(ret.expr);
    _popScope();
    print("return $toReturn");
    return toReturn;
  }
}
