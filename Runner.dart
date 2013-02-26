part of JavaEvaluator;

typedef dynamic EvalMethod(List args);

class Runner {
  Environment environment;
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
    environment = new Environment(this);
    program.compilationUnits.forEach((unit) => loadUnit(unit));
    //perform static loading
    while(!isDone())
      step();
    
    print((environment.values[environment.defaultPackage] as Package)._members);
    if(program.mainSelector != null){
      print("loading main method: ${program.mainSelector}");

      ReferenceValue inContainer;
      if(program.mainSelector.owner is MemberSelect)
        inContainer = environment.memberSelectContainer(program.mainSelector.owner);
      else inContainer = environment.lookupContainer(program.mainSelector.owner);
      
      environment.loadMethod(program.mainSelector.member_id, 
          [environment.newArray(0, null, const TypeNode.fixed(TypeNode.STRING))], 
          inContainer:inContainer);
    }
  }
  
  List<ReferenceValue> loadUnit(CompilationUnit unit){
    print("loading unit...");
    ReferenceValue pkg = getOrCreatePackage(unit.package);
    
    //evaluate imports
    List<ReferenceValue> imports = unit.imports.mappedBy((sel){
      //get enclosing pkg
      ReferenceValue enclosing = getOrCreatePackage(sel.owner);
      ReferenceValue import = enclosing; //default to entire package (star imports)
      if(sel.member_id.name != "*"){
        //lookup in enclosing, if not star import
        environment.values[enclosing].lookupContainer(sel.member_id);
      }
      if(import == null)
        import = environment._newValue(null); //if not found, add a memory location for it
      return import;
    }).toList();
    
    //Create all the static scopes, add imports, and add them to associated packages
    List<ReferenceValue> staticScopes = unit.typeDeclarations.mappedBy((ClassDecl decl){
      print("loading class: ${decl.name}");
      List<EvalTree> initializers = new List<EvalTree>();
      StaticClass clazz = new StaticClass(pkg, decl, initializers);
      //declare static variables, and transform initializers into assignments
      decl.staticVariables.forEach((Variable v){
        Identifier id = new Identifier(v.name);
        clazz.newVariable(id);
        if(v.initializer != null)
          initializers.add(new EvalTree(v, this, (List args) => environment.assign(id, args.first),[v.initializer]));
      });
      
      //check if previously declared
      ReferenceValue ref = environment.lookupContainer(new Identifier(decl.name), inContainer:pkg);
      if(ref != null){
        //memory has already been allocated for class (due to import in another class. Store it at that location
        environment.values[ref] = clazz;
      }
      else {
        ref = environment._newValue(clazz);
      }
      environment.values[pkg].addMember(new Identifier(decl.name), ref);
      
      //add imports
      imports.forEach((ref) {
        clazz._namespaceClasses[environment.values[ref].name] = ref;
      });
      environment.loadEnv(ref);
      return ref;
    }).toList();
    return staticScopes;
  }
  
  ReferenceValue getOrCreatePackage(select){
    if(select is Identifier){
      //check if default package
      if(select == Identifier.DEFAULT_PACKAGE){
        print("returning default package");
        return environment.defaultPackage;
      }
      //Base case, get existing or create new root package
      ReferenceValue ref = environment.packages[select];
      if(ref == null){
        ref = environment._newValue(new Package(select));
        environment.packages[select] = ref;
      }
      return ref;
    }
    else if(select is MemberSelect){
      ReferenceValue owner = getOrCreatePackage(select.owner);
      ReferenceValue ref = environment.values[owner].lookupContainer(select.member_id);
      if(ref == null){
        ref = environment._newValue(new Package(select.member_id));
        environment.values[owner].addMember(select.member_id, ref);
      }
      return ref;
    }
    else throw "Can't get or create package using object of type ${select.runtimeType}";
  }
    
  void step(){
    var toEval = environment.popStatement();
    _current = toEval;
    if(toEval is EvalTree)
      _current = toEval.origExpr;
      
    print("root of step: ${_current}");
    Scope currentScope = environment.currentScope;
    var result = _eval(toEval);
    if(result is EvalTree){
      currentScope.pushStatement(result);
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
    else if(statement is NewObject)
      return _evalNewObject(statement);
    else if(statement is int)
      return statement;
    else if(statement is If)
      return _evalIf(statement);
    else if(statement is BinaryOp)
      return _evalBinaryOp(statement);
    else if(statement is Identifier)
      return environment.lookupVariable(statement);
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
     
      var value = null;
      if(type.isPrimitive)
        value = TypeNode.DEFAULT_VALUES[type.type];
      
      return _newArray(args.mappedBy((arg) => arg.value).toList(), value, 
          newArray.dimensions.reduce(type, (TypeNode r, e) => new TypeNode(r)));
    }, newArray.dimensions.toList());
  }
  
  _evalNewObject(NewObject newObject){
    return new EvalTree(newObject, this, (List args){
      ReferenceValue ref = environment.newObject(environment.lookupContainer(newObject.name), args);
      environment.loadEnv(ref);
      return ref;
    }, newObject.arguments).execute();
  }

  _evalMethodCall(MethodCall call) {
    return new EvalTree(call, this, (List args){
      environment.loadMethod(call.select, args);
      var toReturn = new EvalTree(call, this);
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
    throw "if wont work yet";
//      return new EvalTree(ifStat, this, (List args){
//        if(args[0])
//          environment.addBlockScope(ifStat.then);
//        else if(ifStat.elze != null){
//          environment.addBlockScope(ifStat.elze);      
//        }
//      }, [ifStat.condition]).execute();
  }
  
  _evalAssignment(Assignment assign){
    if(assign.id is ArrayAccess){
      ArrayAccess arr = assign.id;
      return new EvalTree(assign, this, (List args) => environment.arrayAssign(args[0], args[1].value, args[2]), [arr.expr, arr.index, assign.expr]).execute();
    }
    else if(assign.id is Identifier)
      return new EvalTree(assign, this, (List args) => environment.assign(assign.id, args.first),[assign.expr]).execute();
    else if(assign.id is MemberSelect){
      MemberSelect select = assign.id;
      return new EvalTree(assign, this, (List args){
        environment.loadEnv(args[1]);
        environment.assign(select.member_id, args[0]);
        environment.unloadEnv();
      }, [assign.expr, select.owner]).execute();
    }
    else
      throw "Don't know how to assign to ${assign.id.runtimeType}: ${assign.id.toString()}";
  }
  
  _evalMemberSelect(MemberSelect select){
    return new EvalTree(select, this, (List args){
      return environment.lookupIn(select.member_id, args[0]);
    }, [select.owner]).execute();
  }

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
  EvalMethod _method;
  final origExpr;
  
  EvalMethod get method => _method;
  set method(EvalMethod m) => _method = m;
  
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
