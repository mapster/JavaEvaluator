part of JavaEvaluator;

typedef dynamic EvalMethod(List args);

class Runner {
  Environment environment;
  final Program program;

  ASTNode get current => environment._evaluator.current;
  dynamic get lastValue => environment._evaluator.lastValue;

  Runner(this.program) {
    environment = new Environment();
    ClassLoader loader = new ClassLoader(environment, environment._evaluator);
    program.compilationUnits.forEach((unit) => loader.loadUnit(unit));
    //perform static loading
    while(!isDone())
      step();
    
    if(!program.mainSelectors.isEmpty){
      MemberSelect main = program.mainSelectors.last;
      print("main selector: ${main}");
  
      StaticClass clazz = environment.lookupClass(main.owner);
      environment.loadMethod(main.member_id, 
          [environment.newArray(0, null, const TypeNode.fixed(TypeNode.STRING))], 
          inClass:clazz);
    }
  }
  
  bool isDone(){
    return environment.isDone;
  }
    
  void step(){
    var toEval = environment.popStatement();

    environment._evaluator.returnValues;
    print("preEvaluation: $current - id: ${current != null ? current.nodeId : "null"}");
    BlockScope currentBlock = environment.currentBlock;
    var result = environment._evaluator.eval(toEval);
    if(result is EvalTree){
      currentBlock.pushStatement(result);
    }
    if(current != null){
      print("step: ${current} - id: ${current.nodeId}");
    }
    print("=> ${environment._evaluator.lastValue}");
    print("-----");
  }

}

class EvalTree extends ASTNode {
  final List args;
  final List evaledArgs = [];
  final Evaluator evaluator;
  EvalMethod _method;
  final origExpr;
  
  EvalMethod get method => _method;
  set method(EvalMethod m) => _method = m;
  
  EvalTree(this.origExpr, this.evaluator, [this._method, this.args = const []]) : super();
  
  dynamic execute(){
    //evaluate arguments
    //
    
    //skip literals
    while(!args.isEmpty && args.first is Literal){
      evaledArgs.addLast(evaluator.eval(args.removeAt(0)));
    }
    
    if(!args.isEmpty){
      var evaledArg = evaluator.eval(args.first);
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
      evaluator.current = origExpr;
    
    var value = _method(evaledArgs);
    evaluator.lastValue = value;
    return value;
  }
  
  String toString() {
    return "evalTree [$origExpr ${evaledArgs.reduce("", (r,e) => "$r, $e")}${args.reduce("", (r,e) => "$r, $e")}]";
  }
}
