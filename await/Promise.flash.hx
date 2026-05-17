package await;

import haxe.Rest;
import await.types.Listener;
import await.types.State;
import await.types.IPromise;

class Promise<T> implements IPromise<T> {
  static var EVENT_ID = 0;

  public var state: State<T> = Pending;
  public var listeners: Array<Listener<T>> = new Array();

  public final body: ResolverFunc<T>;
  
  public function new(body: ResolverFunc<T>) {
    this.body = body;

    final promise_event_name = '__promise_${EVENT_ID++}';
    var promise_event = new flash.events.Event(promise_event_name);
    var promise_event_listener = (event) -> body(this.resolve, this.reject);

    flash.Lib.current.stage.addEventListener(promise_event_name, promise_event_listener);
    flash.Lib.current.stage.dispatchEvent(promise_event);
    flash.Lib.current.stage.removeEventListener(promise_event_name, promise_event_listener);
  }

  extern inline static public function transform<T>(body: ResolverFunc<T>): ResolverFunc<T>
    return body;

  // todo: use a util class? or smth to not have to reimplement this every single damn time
  // or @:build??
  public function resolve(value: T) {
    if(state != Pending) return;

    state = Fulfilled(value);

    for(listener in listeners) {
      switch listener {
        case Resolve(cb): 
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
    trace("HI");

    return;
    // return js.Syntax.code("await this.js_promise");
  }


  // haxe:
  // public static function run() : void
  //     {
  //        Lib.current.stage.addEventListener(Event.ENTER_FRAME,function(param1:*):void
  //        {
  //           EntryPoint.processEvents();
  //        });
      // }

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