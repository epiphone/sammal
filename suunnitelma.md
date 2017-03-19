# Suunnitelma

Aleksi Pekkala (alvianpe@student.jyu.fi)</br>19.3.2017

## Aihe

Harjoitustyön aiheena on yksinkertainen Lisp-kääntäjä. Kääntäjä toteutetaan
funktionaalisella [Elixir](http://elixir-lang.org/)-kielellä. Kielestä löytyy monia ML-kieliä vastaavia ominaisuuksia
kuten pattern matching, joten se sopinee hyvin isäntäkieleksi. Lisäksi [yecc](http://erlang.org/doc/man/yecc.html)- ja
[leex](http://erlang.org/doc/man/leex.html)-kirjastot tarjoavat `yacc`- ja `lex`-työkaluja  vastaavat toiminnot, joskin
pyrin ainakin aluksi välttämään näiden käyttöä. Kääntäjän työnimi on **sammal**.


## Vaatimukset

Lähdekieli tulee kattamaan jonkinlaisen osuuden [Scheme-kielestä](http://www.schemers.org/Documents/Standards/R5RS/HTML/):

- Tietotyypit: listat, [kokonais-ja liukuluvut, symbolit](http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-7.html#%_sec_4.1.2)
- Muuttujat: [`define`, `set!`, `let`](http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-8.html#%_sec_5.2)
- Tulostaminen: [`quote`](http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-7.html#%_sec_4.1.2)
- Ehtolauseet: [`if`, `and`, `or`](http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-7.html#%_sec_4.1.5)
- Funktiot: [`lambda`](http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-7.html#%_sec_4.1.4)
- Ajan salliessa muita ominaisuuksia:
  - [`case` ja `cond`-ehtolauseet](http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-7.html#%_sec_4.2.1)
  - [makrot](http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-7.html#%_sec_4.3)
  - [laiska laskenta](http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-7.html#%_sec_4.2.5)
  - [tail recursion](http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-6.html#%_sec_3.5)

Esimerkki lähdekielestä:
```scheme
; Fibonacci-sarja:
(define (fib-rec n)
  (if (< n 2)
      n
      (+ (fib-rec (- n 1))
         (fib-rec (- n 2)))))
```

## Testaus

Testaus hoidetaan toteutuksen edetessä yksikkötesteillä TDD-periaatteiden mukaisesti, sekä erikseen laajemmilla integraatiotesteillä.
