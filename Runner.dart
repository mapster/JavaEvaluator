part of JavaEvaluator;

class Runner {
  Environment environment = new Environment();
  Program program;
  List<dynamic> returnValues = [];
  ASTNode _current;
  
  ASTNode get current => _current;
  
  Runner(this.program) {
    program.classDeclarations.values.forEach(loadClass);
  }
  
  void loadClass(ClassDecl clazz) {
    ClassScope staticClass = environment.newClassInstance(clazz, true);
    environment.loadEnv(staticClass);
  }
    
  void step(){
    var toEval = environment.popStatement();
    _current = toEval;
    if(toEval is EvalTree)
      _current = toEval.origExpr;
      
    print("step: $current");
    Scope currentScope = environment.currentScope;
    var result = _eval(toEval);
    if(result is EvalTree){
      print(currentScope.runtimeType);
      currentScope._statements.insertRange(0, 1, result);
    }
  }
  
  bool isDone(){
    return environment.isDone;
  }
  
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
    else if(statement is bool)
      return statement;
    else if(statement is Return)
      return _evalReturn(statement);
    else throw "Statement type not supported yet: ${statement.runtimeType} '$statement'";
  }

  _evalMethodCall(MethodCall call) {
    EvalTree ret = new EvalTree(call, this, (List args){
      environment.callMemberMethod(call.select, args);
      var toReturn = new EvalTree(null, this);
      returnValues.addLast(toReturn);
      return toReturn;
    }, new List.from(call.arguments));

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
    var cond = _eval(ifStat.condition);
    if(cond is EvalTree){
      return new EvalTree(ifStat, this, (var condition){
        if(condition)
          environment.addBlockScope(ifStat.then);
        else if(ifStat.elze != null){
          environment.addBlockScope(ifStat.elze);      
        }
      }, [cond]);
    }
    
    if(cond){
      environment.addBlockScope(ifStat.then);
    }
    else if(ifStat.elze != null){
      environment.addBlockScope(ifStat.elze);      
    }
  }
  
  _evalAssignment(Assignment assign) {
    var expr = _eval(assign.expr);
    if(expr is EvalTree){
      return new EvalTree(assign, this, (List args){environment.assign(assign.id, args.first);}, [expr]);
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
        return new EvalTree(variable, this, (List args){environment.newVariable(new Identifier(variable.name), args.first);}, [init]);
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
      returnValues.removeLast().method = (List l) {
        var ret = toReturn.execute();
        if(ret is EvalTree)
          return ret;
        
        environment.methodReturn();
        return ret;
      };
    }
    else {
      returnValues.removeLast().method = (List l) => toReturn;
      environment.methodReturn();
    }
  }
}

class EvalTree extends ASTNode {
  final List args;
  final List evaledArgs = [];
  final Runner runner;
  var _method;
  final origExpr;
  
  get method => _method;
  set method(m){
    print("setting method of returnTo: $m");
    _method = m;
  }
  
  EvalTree(this.origExpr, this.runner, [this._method, this.args = const []]) : super();
  
  dynamic execute(){
    if(origExpr != null)
      runner._current = origExpr;
    //evaluate arguments
    if(!args.isEmpty){
      if(args.first is Identifier || args.first is MemberSelect){
        evaledArgs.addLast(args.removeAt(0));
      }
      else {
        var evaledArg = runner._eval(args.first);
        if(evaledArg is EvalTree)
          args[0] = evaledArg;
        else {
          evaledArgs.addLast(evaledArg);
          args.removeAt(0);
        }
      }
      
      //return this since it has now stepped one execution
      return this;
    }
    
    return _method(evaledArgs);
  }
  
  String toString() {
    return "evalTree [$origExpr ${evaledArgs.reduce("", (r,e) => "$r, $e")}${args.reduce("", (r,e) => "$r, $e")}]";
  }
}
