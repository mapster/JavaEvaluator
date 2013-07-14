library JavaEvaluator;

import 'ast.dart';
import 'types.dart';
import 'java/JavaLang.dart';
import 'web/site.dart';
part 'evaluator.dart';
part 'environment.dart';
part 'classloader.dart';

typedef dynamic EvalMethod(List args);

class Runner {
  Environment environment;
  final Program program;

  ASTNode get current => environment._evaluator.current;
  dynamic get lastValue => environment._evaluator.lastValue;
  dynamic get next => environment.topStatement();
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
    print("toEval: $toEval");
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
  final List _args;
  final List _evaledArgs = [];
  final Evaluator _evaluator;
  EvalMethod _method;
  final _origExpr;
  
  EvalTree(this._origExpr, this._evaluator, [this._method, this._args = const []]) : super();
  
  dynamic execute(){
    //evaluate arguments
    //
    
    //skip literals
    while(!_args.isEmpty && _args.first is Literal){
      _evaledArgs.add(_evaluator.eval(_args.removeAt(0)));
    }
    
    if(!_args.isEmpty){
      var evaledArg = _evaluator.eval(_args.first);
      if(evaledArg is EvalTree)
        _args[0] = evaledArg;
      else {
        _evaledArgs.add(evaledArg);
        _args.removeAt(0);
      }
      //return _this_ since it has now stepped one execution
      return this;
    }
    
    if(_origExpr != null)
      _evaluator.current = _origExpr;
    
    var value = _method(_evaledArgs);
    _evaluator.lastValue = value;
    return value;
  }
  
  String toString() {
    return "evalTree [$_origExpr ${_evaledArgs.isEmpty ? "" : _evaledArgs.reduce((r,e) => "$r, $e")}${_args.isEmpty ? "" : _args.reduce((r,e) => "$r, $e")}]";
  }
}
