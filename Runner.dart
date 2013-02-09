part of JavaEvaluator;

class Runner {
  Environment environment = new Environment();
  Program program;
  List<dynamic> returnValues = [];
  ASTNode _current;
  bool _extraStep;
  
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
    ReferenceValue instanceAddr = environment.newClassInstance(clazz, true);
    environment.loadEnv(environment.values[instanceAddr]);
  }
    
  void step(){
    var toEval = environment.popStatement();
    _current = toEval;
    if(toEval is EvalTree)
      _current = toEval.origExpr;
      
    Scope currentScope = environment.currentScope;
    var result = _eval(toEval);
    if(result is EvalTree){
      currentScope._statements.insertRange(0, 1, result);
    }
    print("step: $current - id: ${current.nodeId}");
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
    else if(statement is NewArray)
      return _evalNewArray(statement);
    else if(statement is int)
      return statement;
    else if(statement is If)
      return _evalIf(statement);
    else if(statement is BinaryOp)
      return _evalBinaryOp(statement);
    else if(statement is Identifier)
      return environment.lookUpValue(statement);
    else if(statement is String)
      return statement;
    else if(statement is bool)
      return statement;
    else if(statement is Return)
      return _evalReturn(statement);
    else if(statement is Literal)
      return statement.value;
    else if(statement is ArrayAccess)
      return _evalArrayAccess(statement);
    else throw "Statement type not supported yet: ${statement.runtimeType} '$statement'";
  }
  
  _evalArrayAccess(ArrayAccess access){
    return new EvalTree(access, this, (List args){
      return args.first[args[1].value];
    }, [access.expr, access.index]);
  }
  
  _newArray(List dimensions, final value){
    if(dimensions.length == 1)
      return new List.fixedLength(dimensions.first, fill:value);
    else {
      List l = new List.fixedLength(dimensions.first);
      List dims = dimensions.getRange(1, dimensions.length-1); 
      for(int i=0; i < l.length; i++){
        l[i] = _newArray(dims, value);
      }
      return l;
    }
  }

  _evalNewArray(NewArray newArray) {
    return new EvalTree(newArray, this, (List args){
      TypeNode t = newArray.type;
      while(t.isArray)
        t = t.type;
      
      var value = null;
      if(t.isPrimitive)
        value = TypeNode.DEFAULT_VALUES[t.type.toLowerCase()];
      
      return _newArray(args.mappedBy((arg) => arg.value), value);
    }, newArray.dimensions);
  }

  _evalMethodCall(MethodCall call) {
    return new EvalTree(call, this, (List args){
      environment.loadMethod(call.select, args);
      var toReturn = new EvalTree(call, this, false);
      returnValues.addLast(toReturn);
      return toReturn;
    }, new List.from(call.arguments)).execute();
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
      case BinaryOp.MINUS:
        method = (List args) => args[0] - args[1];
        break;
      case BinaryOp.MULT:
        method = (List args) => args[0] * args[1];
        break;
      case BinaryOp.DIV:
        method = (List args) => args[0] / args[1];
        break;
      default:
        throw "Binary operator not supported yet: ${binary.type}";
    }
    
    return new EvalTree(binary, this, method, [binary.left, binary.right]).execute();
  }

  _evalIf(If ifStat){
      return new EvalTree(ifStat, this, (List args){
        if(args[0])
          environment.addBlockScope(ifStat.then);
        else if(ifStat.elze != null){
          environment.addBlockScope(ifStat.elze);      
        }
      }, [ifStat.condition]).execute();
  }
  
  _evalAssignment(Assignment assign) => new EvalTree(assign, this, (List args){environment.assign(assign.id, args.first);}, [assign.expr]).execute();

  _evalVariable(Variable variable) {
    if(variable.initializer == null)
      return new EvalTree(variable, this, (List args){environment.newVariable(new Identifier(variable.name));}, []).execute();

    return new EvalTree(variable, this, (List args){environment.newVariable(new Identifier(variable.name), args.first);}, [variable.initializer]).execute();
  }
  
  _evalReturn(Return ret){
    return new EvalTree(ret, this, (List args){
      returnValues.removeLast().method = (List l) => args.first;
      environment.methodReturn();
      _extraStep = true;
    }, [ret.expr]).execute();
  }
}

class EvalTree extends ASTNode {
  final List args;
  final List evaledArgs = [];
  final Runner runner;
  var _method;
  final origExpr;
  
  get method => _method;
  set method(m) => _method = m;
  
  EvalTree(this.origExpr, this.runner, [this._method, this.args = const []]) : super();
  
  dynamic execute(){
    //evaluate arguments
    if(!args.isEmpty){
      var evaledArg = runner._eval(args.first);
      if(evaledArg is EvalTree)
        args[0] = evaledArg;
      else {
        evaledArgs.addLast(evaledArg);
        args.removeAt(0);
      }
      //return _this_ since it has now stepped one execution
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
