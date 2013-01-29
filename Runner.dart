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
//    while(!environment.isDone){
//      step();
//    }
//    environment.unloadEnv();        
  }
    
  void step(){
    _current = environment.popStatement();
    print("step: $current");
    Scope currentScope = environment.currentScope;
    var result = _eval(current);
    if(result is EvalTree){
      print(currentScope.runtimeType);
      currentScope._statements.insertRange(0, 1, result);
    }
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
    if(statement is EvalTree){
      return statement.execute();
    }
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
    List evaledArgs = new List();
    EvalTree ret = new ArgumentListEvalTree(call, (select){
      environment.callMemberMethod(select, evaledArgs);
      var toReturn = new EvalTree(null);
      returnValues.addLast(toReturn);
      return toReturn;
    }, call.select, new List.from(call.arguments), evaledArgs, _eval);

    return ret.execute();
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
      return new EvalTree(assign, (arg1){environment.assign(assign.id, arg1);}, expr);
    }

    environment.assign(assign.id, expr);
  }

  _evalVariable(Variable variable) {
    if(variable.initializer == null){
      environment.newVariable(new Identifier(variable.name));
    }
    else {
      var init = _eval(variable.initializer);
      if(init is EvalTree){
        return new EvalTree(variable, (var arg){environment.newVariable(new Identifier(variable.name), arg);}, init);
      }
      else environment.newVariable(new Identifier(variable.name), init);
    }
  }
  
  _evalReturn(Return ret){
    var toReturn;
    if(ret.expr is Identifier || ret.expr is MemberSelect)
      toReturn = ret.expr;
     
    toReturn = _eval(ret.expr);
    if(toReturn is EvalTree){
      returnValues.removeLast().method = () {
        toReturn.execute();
        environment.methodReturn();
      };
    }
    else {
      returnValues.removeLast().method = () => toReturn;
      environment.methodReturn();
    }
  }

}

class EvalTree extends ASTNode {
  final arg1;
  final arg2;
  var _method;
  final origExpr;
  
  get method => _method;
  set method(m){
    print("setting method of returnTo: $m");
    _method = m;
  }
  
  EvalTree(this.origExpr, [this._method, this.arg1, this.arg2]) : super();
  
  dynamic execute(){
    if(arg1 != null){
      var arg1Evaled = arg1;
      if(arg1 is EvalTree){
        arg1Evaled = arg1.execute();
        if(arg1Evaled is EvalTree)
          return new EvalTree(origExpr, this.method, arg1Evaled, this.arg2);
      }
      
      if(arg2 != null){
        var arg2Evaled = arg2;
        if(arg2 is EvalTree){
          arg2Evaled = arg2.execute();
          if(arg2Evaled is EvalTree)
            return new EvalTree(origExpr, this.method, arg1Evaled, arg2Evaled);
        }
        return method(arg1Evaled, arg2Evaled);
      }
      else {
        return method(arg1Evaled);
      }
    }
    return method();
  }
  
  String toString() {
    return "evalTree [$origExpr ${arg1 != null ? ", $arg1" : ""}${arg2 != null ? ", $arg2" : ""}]";
  }
}

class ArgumentListEvalTree extends EvalTree {
  final List args;
  final List evaledArgs;
  final evalMethod;
  ArgumentListEvalTree(origExpr, method, arg1, this.args, this.evaledArgs, this.evalMethod) : super(origExpr, method, arg1);
  
  dynamic execute(){
    //evaluate arguments
    if(!args.isEmpty){
      var arg = args.first;
      if(arg is Identifier || arg is MemberSelect){
        evaledArgs.addLast(arg);
        args.removeAt(0);
      }
      else {
        var evaledArg = evalMethod(arg);
        if(evaledArg is EvalTree)
          args[0] = evaledArg;
        else {
          evaledArgs.addLast(evaledArg);
          args.removeAt(0);
        }
      }
    }
    
    //check if there still are arguments not finished evaluating
    if(!args.isEmpty){
      return this;
    }
    return super.execute();
  }
}
