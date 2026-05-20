package await.macros;

import haxe.macro.Context;

// gib better name
final class Analyzer {
    public static var BANNED_PACK_NAMES = ["hl", "haxe"];

    public static function init() {
        Context.onAfterInitMacros(()-> {
            Context.onAfterTyping(exprs -> {
                // find all class exprs & do thingy
                for(expr in exprs){
                    switch expr {
                        case TClassDecl(c):
                            final cls = c.get();

                            if(cls.isExtern)continue;
                            if (cls.pack.length > 0 && BANNED_PACK_NAMES.contains(cls.pack[0])) continue;

                            // get both static and instance-based fields
                            final fields = cls.fields.get().concat(cls.statics.get());

                            for(field in fields){

                                final field_expr = field.expr();
                                if(field_expr == null) continue;

								switch field_expr.expr {
									case TFunction(fun):
										var pass = false;
										final metas = field.meta.get();
										for (i in metas) {
											if (AsyncAwait.ASYNC_META.contains(i.name.toLowerCase())) {
												pass = true;
												trace('passes');
												break;
											}
										}

                                        if(!pass) continue;

                                        switch fun.expr.expr{
                                            case TBlock(be):
                                                
                                            case _:
                                        }
                                    case _:
                                }
                            }
                        case _:
                    }
                }
            });
        });
    } // ig i could use onAfterInitMacros & onAfterTyping
}