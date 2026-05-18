package await;

import haxe.Exception;
import await.types.Listener;
import await.types.State;
import await.types.IPromise;
import haxe.EntryPoint;

#if !sys
#error "This class is not available on this target"
#end

@:nullSafety(StrictThreaded)
class Promise<T> implements IPromise<T> {
  #if (target.threaded)
  final thread: sys.thread.Thread;
  final lock = new sys.thread.Lock();
  #end

  public var state: State<T> = Pending;
  public var listeners: Array<Listener<T>> = new Array();

  public final body: ResolverFunc<T>;

  public function new(body: ResolverFunc<T>) {
    this.body = body;

    #if (target.threaded)
    // trace('threaded');
    thread = sys.thread.Thread.create(() -> { 
      // add a prefix to these verbose traces? like: [await.hx]: thread initiated / threw / releasing
			#if await_hx.verbose trace("thread init'd"); #end
			try {
				body(resolve, reject);
			} catch (e) {
				#if await_hx.verbose trace("thread threw:" + e); #end
				reject(e);
			}

      // this was throwing null access errors for some reason
      // so we're going to release inside of `resolve` and `reject` instead
      //lock.release(); // this never gets called if you `throw` in the handler, maybe try catch?
    });

    // don't let haxe quit before the promise completes
    EntryPoint.runInMainThread(wait);
    #elseif lua
    lua.Coroutine.wrap(() -> body(resolve, reject))();
    #else
    haxe.Timer.delay(() -> body(resolve, reject), 0);
    #end
  }

  @:noCompletion
  inline function release_lock():Void {
    #if await_hx.verbose trace("thread releasing"); #end
    lock.release();
  }

  inline static public function transform<T>(body: ResolverFunc<T>)
    return body;

  // TODO: one base function that does the switchin bs and stuff pleas
  public function resolve(value: T) {
    if(state != Pending) return;

    state = Fulfilled(value);

    #if (target.threaded) release_lock(); #end

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

    #if (target.threaded) release_lock(); #end
    
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
  @:deprecated
  private function wait() {
    #if (target.threaded)
    if(state == Pending) lock.wait();
    #else
    while(state == Pending) { Sys.sleep(0); }
    #end
  }

  @:deprecated
  private inline function await() {
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

  public function toString(): String
    return 'Promise { <state>: $state }';
}