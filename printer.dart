part of JavaEvaluator;

class Printer {
  
  static DivElement _createLineDiv([String text]){
    DivElement div = new DivElement();
    div.attributes['class'] = "line";
    if(?text)
      div.text = text;
    return div;
  }
  
  static DivElement _createIndentDiv(){
    DivElement div = new DivElement();
    div.attributes['class'] = "indent";
    return div;
  }

  static SpanElement _span([String clazz, String text = ""]){
    SpanElement sp = new SpanElement();
    sp.attributes['class'] = clazz;
    sp.text = text;
    return sp;
  }
  
  static SpanElement _keyword(String keyword) => _span("keyword", keyword);
  
  static SpanElement _code(String code){
    SpanElement sp = _span("code");
    sp.text = code;
    return sp;
  }
  
  static Element toHtml(ASTNode node){
    DivElement root = new DivElement();
    root.attributes['id'] = "javasource";
    _toHtml(node, root);
    return root;
  } 
  
  
  static _toHtml(ASTNode astNode, DivElement root){
    DivElement div = _createLineDiv();
    div.attributes['id'] = "node${astNode.nodeId}";
    
    if(astNode is ClassDecl){
      ClassDecl node = astNode;
      
      div.children.addAll(node.modifiers.mappedBy((e) => "$e ").toList().mappedBy(_keyword).toList());
      div.children.add(_keyword("class"));
      div.children.add(_code(" ${node.name} {"));
      root.children.add(div);
      
      DivElement members = _createIndentDiv();
      node.members.forEach((e) => _toHtml(e, members));
      
      root.children.addAll([members, _createLineDiv("}")]);
    }
    else if(astNode is MethodDecl){
      MethodDecl node = astNode;
      
      div.children.addAll(node.modifiers.mappedBy((e) => "$e ").toList().mappedBy(_keyword).toList());
      div.children.addAll(_toElements(node.type.returnType));
      
      div.children.addAll([_span("id", " ${node.name}"), _span("", "(")]);
      div.children.addAll(node.parameters.mappedBy(_toElements).reduce(new List<Element>(), _addSeparators));
      div.children.add(_span("", ") {"));
      root.children.add(div);
      
      DivElement body = _createIndentDiv();
      node.body.forEach((e) => _toHtml(e, body));
      
      root.children.addAll([body, _createLineDiv("}")]);
    }
//    else if(astNode is MethodCall){
//     MethodCall node = astNode;
//     node.select
//    }
    else if(astNode is If){
      If node = astNode;

      div.children.addAll([_keyword("if"), _span("", "(")]);
      div.children.addAll(_toElements(node.condition));
      div.children.add(_span("", "){"));
      root.children.add(div);
      
      //add the then-block
      DivElement then = _createIndentDiv();
      node.then.forEach((e) => _toHtml(e, then));
      root.children.addAll([then, _createLineDiv("}")]);
      
      //add the else-block
      if(node.elze != null){
        DivElement elzeLine = _createLineDiv();
        elzeLine.children.addAll([_keyword("else"), _span("", "{")]);
        root.children.add(elzeLine);
        
        DivElement elze = _createIndentDiv();
        node.elze.forEach((e) => _toHtml(e, elze));
        root.children.addAll([elze, _createLineDiv("}")]);
      }
      
    }
//    else if(astNode is Assignment){
//      Assignment assign = astNode;
//      DivElement div = _createLineDiv();
//      div.children = "${_toElements(assign.id)} = ${_toElements(assign.expr)};";
//      root.children.add(div);
//    }
    else {
      div.children = _toElements(astNode);
      div.children.add(_span("", ";"));
      root.children.add(div);
    }
  }

  static List<Element> _toElements(dynamic node) {
    List<Element> els;
    if(node is Assignment){
      els = _toElements(node.id);
      els.add(_span("op", " = "));
      els.addAll(_toElements(node.expr));
    }
    else if(node is Identifier){
      SpanElement el = _span("id", node.name);
      el.attributes['id'] = "node${node.nodeId}";
      els = [el];
    }
    else if(node is MethodCall){
      MethodCall call = node;
      SpanElement el = _span("call", "${call.select}");
      el.attributes['id'] = "node${node.nodeId}";
      els = [el, _span("", "(")];
      els.addAll(call.arguments.mappedBy(_toElements).reduce(new List<Element>(), _addSeparators));
      els.add(_span("", ")"));
    }
    else if(node is Type){
      els = [_span("type${node.isPrimitive ? " keyword" : ""}", "$node")]; 
    }
    else if(node is Variable){
      els = _toElements(node.type);
      els.add(_span("id", " ${node.name}"));
      if(node.initializer != null){
        els.add(_span("op", " = "));
        els.addAll(_toElements(node.initializer));
      }
    }
    else if(node is BinaryOp){
      els = _toElements(node.left);
      els.add(_span("op", " ${BinaryOp.operatorToString(node.type)} "));
      els.addAll(_toElements(node.right));
    }
    else if(node is Return){
      els = [_span("keyword", "return ")];
      els.addAll(_toElements(node.expr));
    }
    else if(node is Literal){
      SpanElement s =_span("literal", "${node.value}");
      s.attributes['id'] = "node${node.nodeId}";
      els = [s];      
    }
    else if(node is int)
      els = [_span("literal", "$node")];
    else if(node is bool)
      els = [_span("literal", "$node")];
    else if(node is String)
      els = [_span("literal", "\"$node\"")];
    else throw "Not able to print: ${node.runtimeType} : \"${node}\"";
    
    return els.toList();
  }
  
  static List<Element> _addSeparators(List<Element> list, List<Element> e){
    if(!list.isEmpty)
      list.add(_span("", ", "));
    list.addAll(e);
    return list;
  }
  
  static String reduceList(String reduct, e){
    if(reduct.isEmpty)
      return "${_toElements(e)}";

    return "$reduct, ${_toElements(e)}";
  }
}
