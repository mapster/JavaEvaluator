part of JavaEvaluator;

class Runner {
  Map<Identifier, dynamic> environment = new Map<Identifier, dynamic>();
  Program program;
  
  Runner(this.program);
    
  void run(){
    _evalMain(program.main);
  }
  
  _evalMain(MethodDecl method){
    for(dynamic statement in method.body){
      _eval(statement);
    }

    environment.forEach((k, v){print("$k: $v");});
  }
  
  _eval(statement){
    if(statement is Variable)
        _evalVariable(statement);
    else if(statement is Assignment)
      _evalAssignment(statement);
    else if(statement is int)
      return statement;
    else if(statement is If)
      return _evalIf(statement);
    else if(statement is BinaryOp)
      return _evalBinaryOp(statement);
    else if(statement is Identifier)
      return environment[statement];
    else throw "Statement type not supported yet: ${statement.runtimeType}";
  }

  _evalBinaryOp(BinaryOp binary) {
    if(binary == BinaryOp.Equal){
      return _eval(binary.left) == _eval(binary.right);
    }
    else throw "Binary operator not supported yet: ${binary.type}";
  }

  _evalIf(If ifStat){
    if(_eval(ifStat.condition))
      _eval(ifStat.then);
  }
  _evalAssignment(Assignment assign) {
    environment[assign.id] = _eval(assign.expr);
  }

  _evalVariable(Variable variable) {
    environment[new Identifier(variable.name)] = variable.initializer;
  }
}
