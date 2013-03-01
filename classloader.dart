part of JavaEvaluator;

class ClassLoader {
  final Environment environment;
  final Runner runner;
  
  ClassLoader(this.environment, this.runner);
  
  List<ReferenceValue> loadUnit(CompilationUnit unit){
    print("loading unit...");
    Package pkg = getPackage(unit.package);
    
    //evaluate imports
    List<dynamic> imports = unit.imports.map((sel){
      //get enclosing pkg
      Package importParent = getPackage(sel.owner);
      if(sel.member_id.name == "*"){ 
        return importParent;
      }

      //lookup in parent package
      StaticClass import = importParent.lookupClass(sel.member_id);
      if(import == null){
        //if not found, add it
        import = new StaticClass.empty(); 
        importParent.addClass(import);
      }
        
      return import;
    }).toList();
    
    //Load all the classes and create static instances, add imports, and add them to associated packages
    unit.typeDeclarations.forEach((ClassDecl decl){
      print("loading class: ${decl.name}");
      List<EvalTree> initializers = new List<EvalTree>();
      
      //check if class already exists (due to import in some other class)
      StaticClass clazz = pkg.lookupClass(decl.name);
      //if it exists, setup correct contents
      if(clazz != null){
        clazz._declaration = decl;
        clazz._package = pkg;
        initializers = clazz._statements;
      }
      //if it didn't, create it and add it to its parent package
      else {
        clazz = new StaticClass(pkg, decl, initializers);
        pkg.addClass(clazz);
      }
      
      //declare static variables, and transform initializers into assignments
      decl.staticVariables.forEach((Variable v){
        Identifier id = new Identifier.fixed(v.name);
        clazz.newVariable(id);
        if(v.initializer != null)
          initializers.add(new EvalTree(v, this.runner, (List args) => environment.assign(id, args.first),[v.initializer]));
      });
      
      //add imports
      imports.forEach((import) => clazz.addImport(import));
      
      //add class to evaluation stack, to evaluate initializers of static variables
      environment.loadClassScope(clazz);
    });
  }
  
  Package getPackage(select){
    if(select is Identifier){
      //check if default package
      if(select == Identifier.DEFAULT_PACKAGE){
        return environment.defaultPackage;
      }
      //Base case, get existing or create new root package
      Package pkg = environment.packages[select];
      if(pkg == null){
        pkg = new Package(select);
        environment.packages[select] = pkg;
      }
      return pkg;
    }
    else if(select is MemberSelect){
      Package parent = getPackage(select.owner); //recursively fetch parent package
      Package current = parent.lookupPackage(select.member_id); //fetch current package
      //if it doesn't exist, create it
      if(current == null){
         current = new Package(select.member_id);
         parent.addPackage(current);
      }
      return current;
    }
    else throw "Can't get or create package using object of type ${select.runtimeType}";
  }
}
