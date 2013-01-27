part of JavaEvaluator;

class Runner {
//  List<Map<Identifier, dynamic>> environment = new List<Map<Identifier, dynamic>>();
  Environment environment = new Environment();
  Program program;
//  List<List<dynamic>> programstack = [];
  List<dynamic> returnValues = [];
  ASTNode _current;
  
  ASTNode get current => _current;
  
  Runner(this.program) {
//    programstack.add([new MethodCall.main(["streng argument til main"])]);
    program.classDeclarations.values.forEach(loadClass);
  }
  
  void loadClass(ClassDecl clazz) {
    ClassScope staticClass = environment.newClassInstance(clazz, true);
    environment.loadEnv(staticClass);
    
    //TODO extract functionality for step-by-step view of static variable evaluation
    while(!environment.currentContext.isDone){
      var stat = environment.currentContext.popStatement();
      _eval(stat);
    }
    environment.unloadEnv();        
  }
    
  void step(){
    Scope currentScope = environment.currentScope;
    _current = environment.popStatement();
    var result = _eval(current);
    if(result is EvalTree)
      currentScope._statements.insertRange(0, 1, result);
  }
  
  bool isDone(){
    return environment.isDone;
  }
  
//  dynamic _popStatement(){
//    //execution complete
//    if(programstack.isEmpty)
//      return null;
//    //if no more statement in current scope, remove it
//    if(programstack.last.isEmpty){
//      _popScope();
//      return _popStatement();      
//    }
//    
//    return programstack.last.removeAt(0);
//  }
  
//  void _newScope(List<ASTNode> statements){
//    programstack.addLast(statements);
//    environment.addScope();
//  }
//  
//  void _popScope(){
//    programstack.removeLast();
//    environment.popScope();
//  }
  
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
    List<dynamic> args = call.arguments.mappedBy((arg){
      if(arg is Identifier || arg is MemberSelect)
        return arg;
      if(arg is MethodCall);
        throw "Don't support method calls as arguments yet";
      
      return _eval(arg);
    }).toList(); 

    environment.callMemberMethod(call.select, args);
    
    returnValues.addLast(new EvalTree());
    return returnValues.last;
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
    var toReturn;
    if(ret.expr is Identifier || ret.expr is MemberSelect)
      toReturn = ret.expr;
    else if(ret.expr is MethodCall)
      throw "don't support method calls as return expressions yet!";
     
    toReturn = _eval(ret.expr);
    returnValues.removeLast().method = () => toReturn;
    environment.methodReturn();
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
