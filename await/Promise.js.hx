package await;

import haxe.Rest;
import await.types.Listener;
import await.types.State;
import await.types.IPromise;

@:native("AwaitPromise") 
class Promise<T> implements IPromise<T> {
  var js_resolve: (v: Dynamic) -> Void;
  var js_reject: (reason: Dynamic) -> Void;
  var js_promise: js.lib.Promise<T>;

  public var state: State<T> = Pending;
  public var listeners: Array<Listener<T>> = new Array();

  public final body: ResolverFunc<T>;
  
  public function new(body: ResolverFunc<T>) {
    this.body = body;

    js_promise = new js.lib.Promise((resolve, reject) -> {
      this.js_resolve = resolve;
      this.js_reject = reject;

      body(this.resolve, this.reject);
    });
  }

  extern inline static public function transform<T>(body: ResolverFunc<T>): ResolverFunc<T>
    return js.Syntax.code("async {0}", body);

  public function resolve(value: T) {
    if(state != Pending) return;

    state = Fulfilled(value);

    for(listener in listeners) {
      switch listener {
        case Resolve(cb): 
          js_resolve(value);
          cb(value);

        case _: null;
      }
    }
  }
  public function reject(value: Any) {
    if(state != Pending) return;

    state = Rejected(value);
    
    for(listener in listeners) {
      switch listener {
        case Reject(cb): 
          js_reject(value);
          cb(value);

        case _: null;
      }
    }
  }

  public function except(callback: RejectFunc) {
    switch state {
      case Rejected(value):
        callback(value);
        
      case Pending:
        listeners.push(Reject(callback));
      
      case _: null;
    }
    
    return this;
  }

  public function then(callback: ResolveFunc<T>) {
    switch state {
      case Fulfilled(value):
        callback(value);
        
      case Pending:
        listeners.push(Resolve(callback));
      
      case _: null;
    }
    
    return this;
  }

  public function toString(): String
    return 'Promise { <state>: $state }';

  // yes i am evil
  extern inline private function wait() {
    return js.Syntax.code("await this.js_promise");
  }

  extern inline private function await(): T {
    switch state {
      case Fulfilled(v): 
        return v;
      case Rejected(e):
        throw e;
      
      // blah blah it's fine
      case Pending:
        wait();

        return await();
    }
  }
}