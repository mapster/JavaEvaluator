part of JavaEvaluator;

class Runner {
//  List<Map<Identifier, dynamic>> environment = new List<Map<Identifier, dynamic>>();
  Environment environment = new Environment();
  Program program;
  List<List<dynamic>> programstack = [];
  List<dynamic> returnValues = [];
  ASTNode _current;
  
  ASTNode get current => _current;
  
  Runner(this.program) {
    programstack.add([new MethodCall.main(["streng argument til main"])]);
    program.classDeclarations.values.forEach(loadClass);
  }
  
  void loadClass(ClassDecl clazz) {
    environment.addScope();
    List<Identifier> initialValues = new List<Identifier>();
    clazz.staticVariables.forEach((variable) {
      if(variable.initializer != null){
        Identifier id = new Identifier(variable.name);
        environment.newVariable(id, _eval(variable.initializer));
        initialValues.add(id);
      }
    });
    ClassEnv static = environment.newClassInstance(clazz, initialValues, true);
    environment.popScope();
    environment.newVariable(new Identifier(clazz.name), static);
  }
    
  void step(){
    _current = _popStatement();
    var result = _eval(current);
    if(result is EvalTree)
      programstack[programstack.length-2].insertRange(0, 1, result);
  }
  
  bool isDone(){
    if(programstack.isEmpty)
      return true;
    
    return programstack.every((s) => s.isEmpty);
  }
  
  dynamic _popStatement(){
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
  
  dynamic _eval(statement){
    if(statement is EvalTree)
      return statement.execute();
//    else if(statement is MethodDecl)
//      return _evalMethod(statement);
    else if(statement is Variable)
      return _evalVariable(statement);
    else if(statement is MethodCall)
      return _evalMethodCall(statement);
    else if(statement is Assignment)
      return _evalAssignment(statement);
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
    //TODO arguments may contain methodcall, fix to support this.
    List<dynamic> args = call.arguments.mappedBy(_eval).toList(); 
    
    if(call.select is MemberSelect){
      Identifier name = (call.select as MemberSelect).member_id;
      ClassEnv inst = environment.lookUp((call.select as MemberSelect).owner);
    
      MethodDecl method = inst.getMethods().where((MethodDecl m){
       if(m.name != name.name)
         return false;
       
        return _checkParamArgTypeMatch(m.type.parameters, args);        
      }).first;
      
      //add method body as a new scope
      _newScope(method.body);
      
      for(int i = 0; i < method.parameters.length; i++){
        Variable v = method.parameters[i];
        environment.newVariable(new Identifier(v.name), args[i]);
      }
      
      returnValues.addLast(new EvalTree());
      return returnValues.last;
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
  
//  _evalMethod(MethodDecl method){
//    for(dynamic statement in method.body){
//      _eval(statement);
//    }
//  }
  
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
    var expr = _eval(assign.expr);
    if(expr is EvalTree){
      return new EvalTree((arg1){environment.assign(assign.id, arg1);}, expr);
    }

    environment.assign(assign.id, expr);
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
    returnValues.removeLast().method = () => toReturn;    
  }

}

class EvalTree extends ASTNode {
  final arg1;
  final arg2;
  var method;
  
  EvalTree([this.method, this.arg1, this.arg2]) : super();
  
  execute(){
    if(arg1 != null){
      var arg1Evaled = arg1;
      if(arg1 is EvalTree)
        arg1Evaled = arg1.execute();
      
      if(arg2 != null){
        var arg2Evaled = arg2;
        if(arg2 is EvalTree)
          arg2Evaled = arg2.execute();
        return method(arg1Evaled, arg2Evaled);
      }
      else {
        return method(arg1Evaled);
      }
    }
    return method();
  }
}
