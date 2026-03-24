final class Box<T> {
    let value: T
    init(_ value: T) { self.value = value }
}

struct Bar {
  let x: MyFile_Foo_skir
}

enum MyFile_Foo_skir {
  struct Foo {
    let x: Int
    let y: String
    let z: Box<Bar>
    struct Bar {
      let foo: Foo
    }
    static let defaultInstance: Foo = Foo(
      x: 0,
      y: "",
      z: Box(Bar(foo: Foo.defaultInstance)),
    )
  }
}

struct Foo {

}

print("Hello, world!")
