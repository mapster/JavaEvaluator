part of JavaEvaluator;

class Evaluator {
  final Environment environment;
  
  final List<EvalTree> _returnValues = new List<EvalTree>();
  List<EvalTree> get returnValues {
    print("returnStack: ${_returnValues.length}");
    return _returnValues;
  }
  ASTNode _current;
  ASTNode get current => _current;
          set current(ASTNode n) {
            if(n != null && n.nodeId != ReferenceValue.invalid)
              _current = n;
          }
  var lastValue;

  Evaluator(this.environment){
    print("Initializing evaluator");
  }
  
  dynamic eval(statement){
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
    else if(statement is NewObject)
      return _evalNewObject(statement);
    else if(statement is If)
      return _evalIf(statement);
    else if(statement is BinaryOp)
      return _evalBinaryOp(statement);
    else if(statement is Identifier){
      //no further evaluation, setting current
      current = statement;
      return environment.lookup(statement);
    }
    else if(statement is Return)
      return _evalReturn(statement);
    else if(statement is Literal){
      //no further evaluation, setting current
      current = statement;
      
      if(statement.isString){
        return environment.addLibraryObject(new JDKString(statement.value));
      }
      
      return statement.value;
    }
    else if(statement is ArrayAccess)
      return _evalArrayAccess(statement);
    else if(statement is MemberSelect)
      return _evalMemberSelect(statement);
    else throw "Statement type not supported yet: ${statement.runtimeType} '$statement'";
  }
  
  _evalArrayAccess(ArrayAccess access){
    return new EvalTree(access, this, (List args){
      return environment.getArrayValue(args.first, args[1].value);
    }, [access.expr, access.index]);
  }
  
  _newArray(List dimensions, final value, TypeNode type){
    if(dimensions.length == 1)
      return environment.newArray(dimensions.first, value, type);
    else {
      ReferenceValue arr = environment.newArray(dimensions.first, null, type);
      List dims = dimensions.getRange(1, dimensions.length-1); 
      for(int i=0; i < dimensions.first; i++){
        environment.arrayAssign(arr, i, _newArray(dims, value, type.type));
      }
      return arr;
    }
  }

  _evalNewArray(NewArray newArray) {
    return new EvalTree(newArray, this, (List args){
      TypeNode type = newArray.type;
      TypeNode rootType = type;
      while(rootType.isArray) rootType = rootType.type;

      var value = null; 
      print(rootType.type);
      if(rootType.isPrimitive)
        value = TypeNode.DEFAULT_VALUES[rootType.type];
      else
        throw "Don't support object arrays yet!";
      
      return _newArray(args.map((arg) => arg.value).toList(), value, 
          newArray.dimensions.reduce(type, (TypeNode r, e) => new TypeNode(r)));
      
    }, newArray.dimensions.toList());
  }
  
  _evalNewObject(NewObject newObject){
    return new EvalTree(newObject, this, (List args) => environment.newObject(environment.lookupClass(newObject.name), args),
                        newObject.arguments).execute();
  }

  _evalMethodCall(MethodCall call) {
    return new EvalTree(call, this, (List args){
      var toReturn = new EvalTree(call, this);
      returnValues.add(toReturn);
      environment.loadMethod(call.select, args);
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
      case BinaryOp.AND:
        method = (List args) => args[0].and(args[1]);
        break;
      case BinaryOp.OR:
        method = (List args) => args[0].or(args[1]);
        break;
      default:
        throw "Binary operator not supported yet: ${binary.type}";
    }
    
    return new EvalTree(binary, this, method, [binary.left, binary.right]).execute();
  }

  _evalIf(If ifStat){
      return new EvalTree(ifStat, this, (List args){
        if(args[0] is! BooleanValue)
          throw "If condition must evaluate to a Boolean value! (: ${args[0].runtimeType})";
          
        if(args[0].value)
          environment.addBlockScope(ifStat.then);
        else if(ifStat.elze != null){
          environment.addBlockScope(ifStat.elze);      
        }
      }, [ifStat.condition]).execute();
  }
  
  _evalAssignment(Assignment assign){
    if(assign.id is ArrayAccess){
      ArrayAccess arr = assign.id;
      return new EvalTree(assign, this, (List args) => environment.arrayAssign(args[0], args[1].value, args[2]), [arr.expr, arr.index, assign.expr]).execute();
    }
    
    assert(assign.id is Identifier || assign.id is MemberSelect);
    return new EvalTree(assign, this, (List args) => environment.assign(assign.id, args.first),[assign.expr]).execute();
  }
  
  _evalMemberSelect(MemberSelect select){
    return new EvalTree(select, this, (List args){
      return environment.lookup(select);
    }, []).execute();
  }

  _evalVariable(Variable variable) {
    if(variable.initializer == null)
      return new EvalTree(variable, this, (List args){environment.newVariable(new Identifier.fixed(variable.name));}, []).execute();

    return new EvalTree(variable, this, (List args){environment.newVariable(new Identifier.fixed(variable.name), args.first);}, [variable.initializer]).execute();
  }
  
  _evalReturn(Return ret){
    return new EvalTree(ret, this, (List args){
      returnValues.removeLast().method = (List l) => args.first;
      environment.methodReturn();
    }, [ret.expr]).execute();
  }  
  
}

class ForgivingEvaluator extends Evaluator {
  
  ForgivingEvaluator(Environment environment) : super(environment);
  
  
}
