# await.hx
await.hx is a cross-platform library for doing asynchronous operations, using Haxe metadata to annotate functions with `@async`/`@:async` to transform them into a Promise with `.then` and `.except` callbacks

> [!TIP]
> to avoid the constant `@:build(await.AsyncAwait.build())`, we can put `--macro addGlobalMetadata('', '@:build(await.macros.AsyncAwait.build())')` inside `extraParams.hxml`

```haxe
enum Noise {
  Meow;
  Purr;
  Glorp;
}

class Cat {
  @async public function noise(): Array<Noise> {
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

class Main {
  static public function main() {
    final cat = new Cat();
    
    final noise = cat.noise();
    final what = cat.identify(noise);
    trace(what);
  }
}
```