package macros;

#if macro
import haxe.macro.Printer;
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.TypeTools;

class AsyncAwait {
  public static final ASYNC_META = [":async", "async"]; 
  public static final AWAIT_META = [":await", "await"]; 

  public static final NO_INFER = Context.definedValue("await.hx-no-infer") == "1";

  static function meta_includes(metas: Metadata, what: Array<String>) {
    for(meta in metas) {
      final meta_name = meta.name;

      // trace(meta_name);
      for(w in what) {
        if(meta_name == w) return true;
      }
    }
    return false;
  }
  
  static function infer_return_type(func: Function, field: Field) {
    if(func.ret != null) return func.ret;

    try {
      var typed_expr = Context.typeExpr({
        expr: EFunction(FAnonymous, func),
        pos: field.pos
      });

      var type = typed_expr.t;
      switch type {
        case TFun(args, ret):
          return ret.toComplexType();
          
        case _: 
          throw Context.error('Not a function', func.expr.pos);
      }
    } catch(e) {
      throw Context.error('Function could not be inferred: ${e.toString()}', func.expr.pos);
    }
  }

  // todo
  static function parse_await_meta(e: Expr) {
    switch e.expr {
      // dumb traversing ast just to replace @await call() with call().await() lol 
      case EVars(vars):
        for(v in vars)
          parse_await_meta(v.expr);

      case ECall(e, params):
        parse_await_meta(e);
        for(param in params) {
          parse_await_meta(param);
          trace(param);
        }

      case EMeta(s, e2):
        if(AWAIT_META.contains(s.name))
          e.expr = (macro $e2.await()).expr;
      
      case _: null;
    }
    
  }

  static function asynchronize(func: Function, field: Field) {
    var printer = new Printer();
    // trace(printer.printFunction(func));

    final return_type = 
      if(NO_INFER)
        func.ret;
      else 
        infer_return_type(func, field);

    if(return_type == null)
      Context.error('Function is missing an explicit return type (have: ${func.ret})', field.pos);

    // todo: does this matter on interfaces?
    if(func.expr == null)
      Context.error('Function is missing it\'s body', field.pos);

    // change returns into resolve calls
    switch func.expr.expr {
      case EBlock(exprs): for(expr in exprs) switch expr.expr {
        case EReturn(e):
          // gotta fix this, no u cant just `expr = macro`
          exprs[exprs.indexOf(expr)] = macro resolve($e);

        case _: 
          parse_await_meta(expr);
      }

      case _: null;
    }
    trace(printer.printFunction(func));
          
    // we wrap a Promise around the current return type
    final promise_type = TPath({
      pack: [],
      name: "Promise",
      params: [TPType(return_type)]
    });
    func.ret = promise_type;

    // then we wrap it in a promise handler 
    var body = func.expr;
    final promise_body = macro 
      return new Promise((resolve, reject) -> 
        try $body 
        catch(e) reject(e)
      );
    
    func.expr = promise_body;
  }

  public static function build() {
    var fields = Context.getBuildFields();

    for(field in fields) {
      if(!meta_includes(field.meta, ASYNC_META)) continue;

      switch field.kind {
        case FFun(f):
          asynchronize(f, field);

        case _: null;
      }
    }
    
    return fields;
  }
}
#end