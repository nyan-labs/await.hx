package;

import haxe.EntryPoint;
import haxe.MainLoop;
// todo: dont alllow chaining on promises that have @await
//       add target-specific implementations of promise (as of right now it only works on sys targets)
//       fix errors sucking on @async
//       fix haxelib.json lol
class Main {
  @async static function test1(a: Int = 0) {
    // Sys.sleep(1);
    return 1;
  }
  @async static function test2(): Int {
    var test = @await test1(1);

    if(@await test1(@await test1()) == test) {
      trace("yope");
      return 4;
    } else trace("nope");

    // Sys.sleep(6);
    throw "erm";
    return 2;
  }

	@async static function buh():Int {
		final meow = @await Cat.speak();
    // Sys.sleep(5);
		trace(@await Cat.identify(meow));
	//	return 67;
	}

  @async static public function main() {
    trace("async test start");
    var p = new await.Promise((resolve, reject) -> {
      resolve("promise test");
    });
    trace(p);

    trace(@await p);

    buh();

    trace(@await test1());
    trace(@await test2());


    // trace("hi");
    // trace("hi2");
    // Sys.sleep(3);
    // trace("hi");
  }  
}

final class Cat {
	@async public static function speak():Bool {
		return true;
	};

	@async public static function identify(ae:Dynamic):String {
		return "qzip";
	};
}