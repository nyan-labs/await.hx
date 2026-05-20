package tests;

enum Noise {
  Meow;
  Purr;
  Glorp;
}

@:build(await.macros.AsyncAwait.build())
class Cat {
  public function new() {};

  @async public function noise(): Noise {
    /// ... do some long operations
    var noises = [Meow, Purr, Glorp];
    final random_index = Math.floor(Math.random() * noises.length);

    return noises[random_index];
  }

  @async public function identify(noise: Noise) {
    // ... long operations again
    switch noise {
      case Glorp:
        throw "ALIEN DETECTED!!!";

      case _:
        return "cat";
    }
  }
}

@:build(await.macros.AsyncAwait.build())
class Meoaw {
  @async static public function main() {
    final cat = new Cat();
    
    final noise = @await cat.noise();
    // TODO: fix this becoming
    // what.then(value -> {
    // try {
    //         final what = cat.identify(noise);
    //         trace(what);
    //         trace(value);
    // } catch(e) {
    //         trace("error: ", e);
    // };
    // LIKELY DUE TO SCOPING/BEING A BLOCK, prob my lil "fix" (old_exprs) breaking it?
    try {
      final what = cat.identify(noise);
      trace(what);
      trace(@await what);
    } catch(e) {
      trace("error: ", e);
    }
  }
}