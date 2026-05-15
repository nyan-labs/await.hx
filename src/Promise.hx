package;

import haxe.Exception;
import types.Listener;
import types.State;
import types.IPromise;
import haxe.EntryPoint;
import sys.thread.Lock;
import sys.thread.Thread;

@:nullSafety(StrictThreaded)
class Promise<T> implements IPromise<T> {
  public var state = Pending;
  public var listeners = new Array();
	public final body: ResolverFunc<T>;

  #if (target.threaded)
  final thread: Thread;
  final lock = new Lock();
  #end

  public function new(resolver: ResolverFunc<T>) {
    body = resolver;

    #if (target.threaded)
    // trace('threaded');
    thread = Thread.create(() -> { 
      // add a prefix to these verbose traces? like: [await.hx]: thread initiated / threw / releasing
			#if await.hx_verbose trace("thread init'd"); #end
			try {
				body(resolve, reject);
			} catch (e) {
				#if await.hx_verbose trace("thread threw:" + e); #end
				reject(e);
			}

			#if await.hx_verbose trace("thread releasing"); #end
      lock.release(); // this never gets called if you `throw` in the handler, maybe try catch?
    });
    
    #else
    // uhhhhhh
    body(resolve, reject);
    thread = null;
    #end

    // don't let haxe quit before the promise completes
    EntryPoint.runInMainThread(() -> wait());
  }

  // TODO: one base function that does the switchin bs and stuff pleas
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

  // this sleep-based busy-waiting might still be kinda bad
  public function wait() {
    #if (target.threaded)
    if(state == Pending) lock.wait();
    #else
    while(state == Pending) { Sys.sleep(0); }
    #end
    return this;
  }

  inline public function await() {
    if(state == Pending) wait();

    switch state {
      case Fulfilled(v): 
        return v;
      case Rejected(e):
        throw e;
      
      // blah blah it's fine
      case Pending:
        return await();
    }
  }

  public function toString() {
    return 'Promise { <state>: $state }';
  }
}