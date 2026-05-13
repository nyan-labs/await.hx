package promises;

import sys.thread.Lock;
import sys.thread.Thread;

typedef ResolveFunc<T> = (value: T) -> Void; 
typedef RejectFunc = (reason: String) -> Void; 
typedef ResolverFunc<T> = (resolve: ResolveFunc<T>, reject: RejectFunc) -> Void;

enum Listener<T> {
  Resolve(cb: ResolveFunc<T>);
  Reject(cb: RejectFunc);
} 

enum State<T> {
  Fulfilled(value: T);
  Rejected(reason: String);
  Pending;
}

@:nullSafety(StrictThreaded)
class Promise<T> {
  var state: State<T> = Pending;
  var listeners: Array<Listener<T>> = new Array();

  #if (target.threaded)
  final lock: Lock = new Lock();
  #end

  final body: ResolverFunc<T>;
  final thread: Thread;

  public function new(resolver: ResolverFunc<T>) {
    body = resolver;

    #if (target.threaded)
    trace('threaded');
    // final main = Thread.current();

    thread = Thread.create(() -> { 
      body(resolve, reject);
      
      #if (target.threaded)
      lock.release();
      #end
    });
    
    // trace(thread.events.wait(5));

    // defer this
    // Thread.readMessage(true);
    #else
    body(resolve, reject);
    thread = null;
    #end
  }

  function resolve(value: T) {
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
  function reject(reason: String) {
    if(state != Pending) return;

    state = Rejected(reason);
    
    for(listener in listeners) {
      switch listener {
        case Reject(cb): 
          cb(reason);

        case _: null;
      }
    }
  }

  public function except(callback: RejectFunc) {
    switch state {
      case Rejected(reason):
        callback(reason);
        
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

  // this sleep-based busy-waiting might still be kinda bad
  public function wait() {
    #if (target.threaded)
    lock.wait();
    #else
    while(state == Pending) { Sys.sleep(0); }
    #end
    return this;
  }
}