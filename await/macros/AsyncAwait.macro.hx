package await.macros;

import haxe.macro.ExprTools;
import haxe.macro.Printer;
import haxe.macro.Expr;
import haxe.macro.Context;

using haxe.macro.TypeTools;

// TODO: give this type a better name
private typedef ExtractedAwait = {rebuilt_expr:Expr, promise_expr:Expr}; // i like paws & types

class AsyncAwait {
	public static final ASYNC_META = [":async", "async"];
	public static final AWAIT_META = [":await", "await"];

	static function meta_includes(metas:Metadata, what:Array<String>) {
		for (meta in metas) {
			final meta_name = meta.name;

			// trace(meta_name);
			for (w in what) {
				if (meta_name == w)
					return true;
			}
		}
		return false;
	}

	static function infer_return_type(func:Function, field:Field) {
		if (func.ret != null)
			return func.ret;

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
		} catch (e) {
			// Context.warning('Function could not be inferred: ${e.toString()}', func.expr.pos);
			return TPath({
				pack: [],
				name: "Void",
				params: []
			});
		}
	}

	inline static function make_then(promise:Expr, continuation:Expr):Expr {
		return macro $promise.then(value -> $continuation).except((e) -> throw e);
	}

	// the `.except` thingy ensures any unhandled errors nested in .`next()` bubble up
	// to the outer promises `reject` func, instead of dying silently...
	static function build_continuation(exprs:Array<Expr>, pos:Position):Expr {
		for (i => e in exprs) {
			switch e.expr {
				// i'm honestly just typing random shit now
				// i think this'll work... idk tho
				// note from future self: yes, it did work
				case EVars([
					{
						name: name,
						expr: {expr: EMeta({name: name2}, promise_expr)}
					}
				]) if (AWAIT_META.contains(name2)):
					// unwrap any nested `@await`'s inside the promise expr itself
					final inner:Null<ExtractedAwait> = extract_first_await(promise_expr);

					if (inner != null) {
						// re-process this whole statement with the inner `@await` shit omitted
						var new_exprs:Array<Expr> = [{expr: EVars([{name: name, type: null, expr: inner.rebuilt_expr}]), pos: e.pos}];
        
            final old_exprs = new_exprs.slice(0, i);

						// i forgor `.concat(...)` makes a new array, and doesn't modify the original
						new_exprs = new_exprs.concat(exprs.slice(i + 1));

						final then_exprs = make_then(inner.promise_expr, build_continuation(new_exprs, pos));

						old_exprs.push(then_exprs);

						return {
							expr: EBlock(old_exprs),
							pos: pos
						};
					}

          final old_exprs = exprs.slice(0, i);
						trace(i, (new Printer()).printExprs(old_exprs, "; "));
					final then_exprs = make_then(promise_expr, macro {var $name = value; ${build_continuation(exprs.slice(i + 1), pos)};}); // iykyk

					old_exprs.push(then_exprs);

					return {
						expr: EBlock(old_exprs),
						pos: pos
					};

				// for stuff like: `@await meow()`ike: `@await meow()` or `if(@await purr() == x)`
				case _:
					final found:Null<ExtractedAwait> = extract_first_await(e);
					if (found != null) {
						// trace((new Printer()).printExprs(exprs, "; "));
						// trace(i, exprs[i]);
						// replace current expr with a fixed/rebuilt version
						final old_exprs = exprs.slice(0, i);
						// trace((new Printer()).printExprs(old_exprs, ";1 "));

						final new_exprs = [found.rebuilt_expr].concat(exprs.slice(i + 1));
						// trace((new Printer()).printExprs(new_exprs, ";2 "));

						final then_exprs = make_then(found.promise_expr, build_continuation(new_exprs, pos));

						old_exprs.push(then_exprs);

						return {
							expr: EBlock(old_exprs),
							pos: pos
						};
					}
			}
		}

    // qzip: orbl next time plz put more informative comments !!!
		// watafak am i even doing QwQ
		return resolve_returns(({expr: EBlock(exprs), pos: pos} : Expr));
	}

	// idk wat to name dis QwQ
	static function extract_first_await(e:Expr):Null<ExtractedAwait> {
		var found_promise:Null<Expr> = null;

		// exprtools.map basically walks the expr/ast-like tree, replacing @AWAit shit
		final rebuilt_expr:Expr = ExprTools.map(e, inner -> {
			if (found_promise != null)
				return inner;

			final r:Null<ExtractedAwait> = extract_first_await(inner);
			if (r != null) {
				found_promise = r.promise_expr;
				return r.rebuilt_expr;
			}

			return inner;
		});

		if (found_promise != null) {
			return {rebuilt_expr: rebuilt_expr, promise_expr: found_promise};
		}

		return switch e.expr {
			case EMeta({name: name}, inner) if (AWAIT_META.contains(name)):
				{rebuilt_expr: macro value, promise_expr: inner};
			case _: null;
		}
	}

	static function resolve_returns(e:Expr):Expr {
		return switch e.expr {
			case EReturn(e):
				macro return resolve($e);

			case _:
				ExprTools.map(e, resolve_returns);
		}
	}

	static function asynchronize(func:Function, field:Field) {
		final is_main = field.access.contains(AStatic) && field.name == "main";

		#if await_hx.verbose
		var printer = new Printer();
		// trace(printer.printFunction(func));
		#end

		final return_type = #if await_hx.no_infer func.ret; #else infer_return_type(func, field); #end

		if (return_type == null)
			Context.error('Function is missing an explicit return type (have: ${func.ret})', field.pos);

		// todo: does this matter on interfaces?
		if (func.expr == null)
			Context.error('Function is missing it\'s body', field.pos);

		// change returns into resolve calls
		switch func.expr.expr {
			case EBlock(exprs):
				// ensures the lock gets released
				exprs.push(macro return cast null);
				func.expr = build_continuation(exprs, func.expr.pos);

			case _:
				null; // parse_await_meta(expr);
		}

		#if await_hx.verbose
		trace('${field.name}:', printer.printFunction(func));
		#end

		// we wrap a Promise around the current return type
		final promise_type = if (is_main) return_type else TPath({
			pack: ["await"],
			name: "Promise",
			params: [TPType(return_type)]
		});
		func.ret = promise_type;

		// then we wrap it in a promise handler
		var body = func.expr;

		final promise_body = if (is_main) 
      macro new await.Promise(await.Promise.transform((resolve, reject) -> $body)); 
    else 
      macro return new await.Promise(await.Promise.transform((resolve, reject) -> $body));

		func.expr = promise_body;
	}

	public static function build() {
		var fields = Context.getBuildFields();

		for (field in fields) {
			if (!meta_includes(field.meta, ASYNC_META))
				continue;

			switch field.kind {
				case FFun(f):
					asynchronize(f, field);

				case _:
					null;
			}
		}

		return fields;
	}
}
