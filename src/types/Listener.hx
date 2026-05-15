package types;

import types.State;

typedef ResolveFunc<T> = (value: T) -> Void; 
typedef RejectFunc = (value: Any) -> Void; 
typedef ResolverFunc<T> = (resolve: ResolveFunc<T>, reject: RejectFunc) -> Void;

enum Listener<T> {
  Resolve(cb: ResolveFunc<T>);
  Reject(cb: RejectFunc);
} 