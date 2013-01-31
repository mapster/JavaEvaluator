part of JavaEvaluator;

class Runner {
  Environment environment = new Environment();
  Program program;
  List<dynamic> returnValues = [];
  ASTNode _current;
  
  ASTNode get current => _current;
          set current(node) {
            if(node is EvalTree)
              _current = node.origExpr;
            else
              _current = node;
          }
  
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
      
    print("step: $current - id: ${current.nodeId}");
    Scope currentScope = environment.currentScope;
    var result = _eval(toEval);
    if(result is EvalTree){
      currentScope._statements.insertRange(0, 1, result);
    }
  }
  
  bool isDone(){
    return environment.isDone;
  }
  
  dynamic _eval(statement){
    _current = statement;
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
    else if(statement is Literal)
      return statement.value;
    else throw "Statement type not supported yet: ${statement.runtimeType} '$statement'";
  }

  _evalMethodCall(MethodCall call) {
    EvalTree ret = new EvalTree(call, this, false, (List args){
      environment.callMemberMethod(call.select, args);
      var toReturn = new EvalTree(null, this, false);
      returnValues.addLast(toReturn);
      return toReturn;
    }, new List.from(call.arguments));

    return ret.execute();
  }
  
  _evalBinaryOp(BinaryOp binary) {
    var method;
    switch(binary.type){
      case BinaryOp.EQUAL:
        method = (List args) => args[0] == args[1];
        break;
      case BinaryOp.PLUS:
        method = (List args) {
          if(args[0] is String)
            return "${args[0]}${args[1]}";
          return args[0] + args[1];
        };
        break;
      default:
        throw "Binary operator not supported yet: ${binary.type}";
    }
    
    return new EvalTree(binary, this, true, method, [binary.left, binary.right]).execute();
  }

  _evalIf(If ifStat){
      return new EvalTree(ifStat, this, true, (List args){
        if(args[0])
          environment.addBlockScope(ifStat.then);
        else if(ifStat.elze != null){
          environment.addBlockScope(ifStat.elze);      
        }
      }, [ifStat.condition]).execute();
  }
  
  _evalAssignment(Assignment assign) => new EvalTree(assign, this, false, (List args){environment.assign(assign.id, args.first);}, [assign.expr]).execute();

  _evalVariable(Variable variable) {
    if(variable.initializer == null)
      return new EvalTree(variable, this, false, (List args){environment.newVariable(new Identifier(variable.name));}, []).execute();

    return new EvalTree(variable, this, false, (List args){environment.newVariable(new Identifier(variable.name), args.first);}, [variable.initializer]).execute();
  }
  
  _evalReturn(Return ret){
    return new EvalTree(ret, this, false, (List args){
      returnValues.removeLast().method = (List l) => args.first;
      environment.methodReturn();
    }, [ret.expr]).execute();
  }
}

class EvalTree extends ASTNode {
  final bool lookUpArguments;
  final List args;
  final List evaledArgs = [];
  final Runner runner;
  var _method;
  final origExpr;
  
  get method => _method;
  set method(m) => _method = m;
  
  EvalTree(this.origExpr, this.runner, this.lookUpArguments, [this._method, this.args = const []]) : super();
  
  dynamic execute(){
    //evaluate arguments
    if(!args.isEmpty){
      if(!lookUpArguments && (args.first is Identifier || args.first is MemberSelect) && !runner.environment.isPrimitive(args.first)){
        evaledArgs.addLast(args.removeAt(0));
        runner.current = evaledArgs.last;
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
    
    if(origExpr != null)
      runner._current = origExpr;
    
    return _method(evaledArgs);
  }
  
  String toString() {
    return "evalTree [$origExpr ${evaledArgs.reduce("", (r,e) => "$r, $e")}${args.reduce("", (r,e) => "$r, $e")}]";
  }
}
