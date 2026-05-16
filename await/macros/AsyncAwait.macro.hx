package await.macros;

import haxe.macro.ExprTools;
import haxe.macro.Printer;
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.TypeTools;

class AsyncAwait {
  public static final ASYNC_META = [":async", "async"]; 
  public static final AWAIT_META = [":await", "await"]; 

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
      // this is not that great of a way to get a type 
      var type = Context.typeof({
        expr: EFunction(FNamed("hi", false), func),
        pos: field.pos
      });

      switch type {
        case TFun(args, ret):
          return ret.toComplexType();
          
        case _: 
          throw Context.error('Not a function', func.expr.pos);
      }
    } catch(e) {
      // Context.warning('Function could not be inferred: ${e.toString()}', func.expr.pos);
      return TPath({
        pack: [],
        name: "Void",
        params: []
      });
    }
  }

  static function parse_await_meta(e: Expr): Expr {
    return switch e.expr {
      case EMeta({name: name}, inner) if(AWAIT_META.contains(name)):
        final p = parse_await_meta(inner);
        // check the type and see if its a promise ig
        macro @:privateAccess $p.await();
      case _:
        // exprtools.map basically walks the expr/ast-like tree, replacing @AWAit shit 
        ExprTools.map(e, parse_await_meta); // kms
    }
  }
  static function resolve_returns(e: Expr): Expr {
    return switch e.expr {
      case EReturn(e):
        macro return resolve($e);
        
      case _:
        ExprTools.map(e, resolve_returns);
    }
  }

  static function asynchronize(func: Function, field: Field) {
    final is_main = field.access.contains(AStatic) && field.name == "main";

    var printer = new Printer();
    // trace(printer.printFunction(func));

    final return_type = #if await_hx.no_infer func.ret; #else infer_return_type(func, field); #end

    if(return_type == null)
      Context.error('Function is missing an explicit return type (have: ${func.ret})', field.pos);

    // todo: does this matter on interfaces?
    if(func.expr == null)
      Context.error('Function is missing it\'s body', field.pos);

		// change returns into resolve calls
		switch func.expr.expr {
			case EBlock(exprs):
				for(i in 0...exprs.length) {
					exprs[i] = resolve_returns(exprs[i]);
					exprs[i] = parse_await_meta(exprs[i]);
				}

      case _: null; //parse_await_meta(expr);
    }
    
		#if await_hx.verbose
		trace(printer.printFunction(func));
		#end

    // we wrap a Promise around the current return type
    final promise_type = if(is_main) return_type else TPath({
      pack: ["await"],
      name: "Promise",
      params: [TPType(return_type)]
    });
    func.ret = promise_type;

    // then we wrap it in a promise handler 
    var body = func.expr;

    final promise_body = if(is_main) macro
      new await.Promise((resolve, reject) -> $body);
    else macro
      return new await.Promise((resolve, reject) -> $body);
    
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
