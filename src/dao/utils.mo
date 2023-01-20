import Text "mo:base/Text";
import Char "mo:base/Char";

module Utils {
   public func number_of_words(t : Text) : Nat {
    var n : Nat = 0;
    let te = Text.split(t, #char(' '));
      for (e in te) {
        if (Text.contains(e, #predicate( func(x) {Char.isDigit(x)} ))) {
          // do nothing
          } else { n += 1 };
      };
    return n;
  };
}