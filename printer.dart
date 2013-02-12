part of JavaEvaluator;

class Printer {

  static Element _newElement({int nodeid, String text, bool newLine: false, bool keyword: false, bool indent: false}){
    Element ele;
    if(newLine || indent)
      ele = new DivElement();
    else 
      ele = new SpanElement();
    
    List classes = [];
    if(?nodeid)   ele.attributes['id'] = "node$nodeid";
    if(newLine)   classes.add("line");
    if(keyword)   classes.add("keyword");
    if(indent)    classes.add("indent");
    if(?text)     ele.text = text;
    if(!classes.isEmpty) ele.attributes['class'] = classes.reduce("", (r, e) => r.isEmpty ? e : "$r $e");
    
    return ele;
  }

  static Element toHtml(ASTNode node){
    DivElement root = new DivElement();
    root.attributes['id'] = "javasource";
    root.children.addAll(_toHtml(node, true));
    return root;
  } 
  
  static List<Element> _toHtml(ASTNode astNode, bool newLine){
    if(astNode is ArrayAccess){
      return _arrayAccessToHtml(astNode, newLine);
    }
    else if(astNode is Assignment){
      return _assignmentToHtml(astNode, newLine);
    }
    else if(astNode is BinaryOp){
      return _binaryOpToHtml(astNode, newLine);
    }
    else if(astNode is ClassDecl){
      return _classToHtml(astNode);
    }
    else if(astNode is Identifier){
      return _identifierToHtml(astNode, newLine);
    }
    else if(astNode is If){
      return _ifToHtml(astNode);
    }
    else if(astNode is Literal){
      return _literalToHtml(astNode, newLine);
    }
    else if(astNode is MemberSelect){
      return _memberSelectToHtml(astNode, newLine);
    }
    else if(astNode is MethodCall){
      return _methodCallToHtml(astNode, newLine);
    }
    else if(astNode is MethodDecl){
      return _methodDeclToHtml(astNode, newLine);
    }
    else if(astNode is NewArray){
      return _newArrayToHtml(astNode, newLine); 
    }
    else if(astNode is NewObject){
      return _newObjectToHtml(astNode, newLine);
    }
    else if(astNode is Return){
      return _returnToHtml(astNode, newLine);
    }
    else if(astNode is TypeNode){
      return _typeToHtml(astNode, newLine);
    }
    else if(astNode is Variable){
      return _variableToHtml(astNode, newLine);
    }
    else throw "Unknown node type, cannot print: ${astNode.runtimeType}";
  }

  static List<Element> _arrayAccessToHtml(ArrayAccess node, bool newLine) {
    Element element = _newElement(newLine:newLine, nodeid:node.nodeId);
    element.children.addAll(_toHtml(node.expr, false));
    element.children.add(_newElement(text:"["));
    element.children.addAll(_toHtml(node.index, false));
    element.children.add(_newElement(text:"]"));
    return [element];
  }

  static List<Element> _assignmentToHtml(Assignment node, bool newLine) {
    Element element = _newElement(newLine:newLine, nodeid:node.nodeId);
    element.children.addAll(_toHtml(node.id, false));
    element.children.add(_newElement(text:" = "));
    element.children.addAll(_toHtml(node.expr, false));
    if(newLine) element.children.add(_newElement(text:";"));
    return [element];
  }

  static List<Element> _binaryOpToHtml(BinaryOp node, bool newLine) {
    Element element = _newElement(newLine: newLine, nodeid: node.nodeId);
    element.children.addAll(_toHtml(node.left, false));
    element.children.add(_newElement(text: " ${BinaryOp.operatorToString(node.type)} "));
    element.children.addAll(_toHtml(node.right, false));
    if(newLine) element.children.add(_newElement(text:";"));
    return [element];
  }

  static List<Element> _classToHtml(ClassDecl node) {
    DivElement header = _newElement(nodeid: node.nodeId, newLine: true);
    header.children.addAll(node.modifiers.mappedBy((e) => _newElement(keyword: true, text: "$e ")).toList());
    header.children.add(_newElement(text: "class", keyword: true));
    header.children.add(_newElement(text: " ${node.name} {"));
    
    DivElement body = _newElement(indent: true);
    body.children = node.members.mappedBy((m) => _toHtml(m, true)).toList().reduce(new List<Element>(), _reduceLists);
    
    return [header, body, _newElement(newLine: true, text: "}")];
  }
  
  static List<Element> _identifierToHtml(Identifier node, bool newLine) => 
      [_newElement(nodeid:node.nodeId, newLine:newLine, text:"${node.name}${newLine ? ";" : ""}")];
  
  static List<Element> _ifToHtml(If node) {
    DivElement header = _newElement(newLine: true, nodeid: node.nodeId);
    header.children.addAll([_newElement(text: "if", keyword: true), _newElement(text: "(")]);
    header.children.addAll(_toHtml(node.condition, false));
    header.children.add(_newElement(text: ") {"));
    
    //the then-block
    DivElement then = _newElement(indent: true);
    then.children = node.then.mappedBy((e) => _toHtml(e, true)).toList().reduce(new List<Element>(), _reduceLists);
    
    List<Element> ifThen = [header, then, _newElement(text: "}")];
    if(node.elze == null)
      return ifThen;
    
    //the else-block  
    DivElement elseHeader = _newElement(newLine: true);
    elseHeader.children.addAll([_newElement(keyword: true, text: "else"), _newElement(text: " {")]);
    
    DivElement elseBody = _newElement(indent: true);
    elseBody.children = node.elze.mappedBy((e) => _toHtml(e, true)).toList().reduce(new List<Element>(), _reduceLists);

    ifThen.addAll([elseHeader, elseBody, _newElement(newLine:true, text:"}")]);
    return ifThen;
  }
  
  static List<Element> _literalToHtml(Literal node, bool newLine) => [_newElement(newLine:newLine, nodeid:node.nodeId, text:"${node}")];

  static List<Element> _memberSelectToHtml(MemberSelect node, bool newLine){
    Element element = _newElement(nodeid:node.nodeId, newLine:newLine);
    element.children.addAll(_toHtml(node.owner, false));
    element.children.add(_newElement(text:"."));
    element.children.addAll(_toHtml(node.member_id, false));
    return [element];
  }

  static List<Element> _methodCallToHtml(MethodCall node, bool newLine) {
    Element element = _newElement(nodeid:node.nodeId, newLine:newLine);
    element.children.add(_newElement(text:"${node.select.toString()}("));
    element.children.addAll(node.arguments.mappedBy((arg) => _toHtml(arg, false)).toList().reduce(new List<Element>(), _reduceCommaSeparated));    
    element.children.add(_newElement(text:")"));
    if(newLine) element.children.add(_newElement(text:";"));
    return [element];
  }

  static List<Element> _methodDeclToHtml(MethodDecl node, bool newLine) {
    DivElement header = _newElement(newLine:newLine, nodeid:node.nodeId);
    header.children.addAll(node.modifiers.mappedBy((m) => _newElement(text:"$m ", keyword: true)).toList());
    header.children.addAll(_toHtml(node.type.returnType, false));
    header.children.add(_newElement(text:" ${node.name}("));
    header.children.addAll(node.parameters.mappedBy((p) => _toHtml(p, false)).toList().reduce(new List<Element>(), _reduceCommaSeparated));
    header.children.add(_newElement(text:") {"));
    
    DivElement body = _newElement(indent:true);
    body.children = node.body.mappedBy((e) => _toHtml(e, true)).toList().reduce(new List<Element>(), _reduceLists);
    
    return [header, body, _newElement(newLine:true, text:"}")];
  }
  
  static List<Element> _newArrayToHtml(NewArray node, bool newLine){
    Element element = _newElement(nodeid:node.nodeId, newLine:newLine);
    element.children.add(_newElement(keyword:true, text:"new "));
    
    //find base type of array
    TypeNode baseType = node.type;
    while(baseType.isArray)
      baseType = baseType.type;
    
    element.children.addAll(_toHtml(baseType, false));
    node.dimensions.forEach((dim){
      element.children.add(_newElement(text:"["));
      element.children.addAll(_toHtml(dim, false));
      element.children.add(_newElement(text:"]"));
    });
    
    //add uninitialized part of array
    String arr = "";
    TypeNode t = node.type;
    while(t.isArray){
      t = t.type;
      arr = "$arr[]";
    }
    element.children.add(_newElement(text:arr));
    
    return [element];
  }
  
  static List<Element> _newObjectToHtml(NewObject node, bool newLine){
    Element element = _newElement(nodeid:node.nodeId, newLine:newLine);
    element.children.add(_newElement(keyword:true, text:"new "));
    element.children.addAll(_toHtml(node.name, false));
    element.children.add(_newElement(text:"()"));
    return [element];
  }

  static List<Element> _returnToHtml(Return node, bool newLine) {
    Element element = _newElement(nodeid:node.nodeId, newLine:newLine);
    element.children.add(_newElement(keyword:true, text:"return "));
    element.children.addAll(_toHtml(node.expr, false));
    if(newLine) element.children.add(_newElement(text:";"));
    return [element];
  }

  static List<Element> _typeToHtml(TypeNode node, bool newLine){
    List<Element> els = new List<Element>();
    if(node.isArray)
      els.addAll(_typeToHtml(node.type, false));
    
    els.add(_newElement(nodeid:node.nodeId, keyword:node.isPrimitive, text:(node.isArray ? "[]" : node.toString())));
    return els;
  }

  static List<Element> _variableToHtml(Variable node, bool newLine) {
    Element element = _newElement(nodeid:node.nodeId, newLine:newLine);
    element.children.addAll(_toHtml(node.type, false));
    element.children.add(_newElement(text:" ${node.name}"));
    if(node.initializer != null){
      element.children.add(_newElement(text:" = "));
      element.children.addAll(_toHtml(node.initializer, false));
    }
    if(newLine) element.children.add(_newElement(text:";"));
    return [element];
  }
  
  static List _reduceCommaSeparated(List r, List e){
    if(!r.isEmpty) 
      r.add(_newElement(text:", "));
    r.addAll(e);
    return r;
  }
  
  static _reduceLists(List r, e) {
    r.addAll(e);
    return r;
  }
  
  static scopeToHtml(Scope sc){
    DivElement root = new DivElement();
    root.classes.add("scope");
    if(sc is ClassScope){
      HeadingElement title = new HeadingElement.h4();
      title.text = "${sc.clazz.name}";
      root.children.add(title);
      root.children.addAll(sc.assignments.keys.map((id) => _envAssignToHtml(id, sc)).toList());
      DivElement subscopes = new DivElement();
      subscopes.children.addAll(sc._subscopes.map(scopeToHtml).toList());
      root.children.add(subscopes);
    }
    else {
      root.children.addAll(sc.assignments.keys.map((id) => _envAssignToHtml(id, sc)).toList());
      if(sc._subscope != null)
        root.children.add(scopeToHtml(sc._subscope));
    }
    return root;
  }
  
  static _envAssignToHtml(Identifier id, Scope sc){
    DivElement assign = new DivElement();
    assign.text = "$id: ${sc.assignments[id]}";
    return assign;
  }
}
