// ignore_for_file: unnecessary_new

part of dartz;

typedef Free<F, A> _FreeF<F, A>(dynamic x);

abstract class Free<F, A> implements MonadOps<Free<F, dynamic>, A> {

  @override Free<F, B> map<B>(B f(A a)) => bind((a) => new Pure(f(a)));

  @override Free<F, B> bind<B>(Function1<A, Free<F, B>> f) => new Bind(this, (a) => f(cast(a)));

  @override Free<F, B> replace<B>(B replacement) => map((_) => replacement);

  R fold<R>(R ifPure(A a), R ifSuspend(F fa), R ifBind(Free<F, dynamic> ffb, _FreeF<F, A> f));
/*
  Free<F, A> step() {
    Free<F, A> current = this;
    while(current is Bind) {
      final currentBind = cast<Bind<F, A, dynamic>>(current);
      current = currentBind.ffb.fold((a) => cast(currentBind.f(a)), (fa) => currentBind, (ffb, f) => ffb.bind((a) => f(a).bind((a2) => cast(currentBind.f(a2)))));
      if (identical(current, currentBind)) {
        return current;
      }
    }
    return current;
  }
*/

  MA foldMap<M, MA extends M>(Monad<M> m, M f(F fa)) =>
      cast(/*step().*/fold((a) => m.pure(a), (fa) => f(fa), (ffb, f2) => m.bind(ffb.foldMap(m, f), (c) => f2(c).foldMap(m, f))));


  Future<A> foldMapFuture(Future f(F fa)) =>
    /*step().*/ fold((a) => new Future.microtask(() => a), (fa) => f(fa).then((a) => cast<A>(a)), (ffb, f2) => ffb.foldMapFuture(f).then((c) => f2(c).foldMapFuture(f)));

  Evaluation<E, R, W, S, A> foldMapEvaluation<E, R, W, S>(EvaluationMonad<E, R, W, S> m, Evaluation<E, R, W, S, dynamic> f(F fa)) =>
    /*step().*/ fold((a) => m.pure(a), (fa) => f(fa).map((a) => cast<A>(a)), (ffb, f2) => ffb.foldMapEvaluation(m, f).bind((c) => f2(c).foldMapEvaluation(m, f)));


  @override Free<F, B> flatMap<B>(Function1<A, Free<F, B>> f) => new Bind(this, (a) => f(cast(a)));

  @override Free<F, B> andThen<B>(Free<F, B> next) => bind((_) => next);

  static Free<F, C> map2<F, A, A2 extends A, B, B2 extends B, C>(Free<F, A2> fa, Free<F, B2> fb, C fun(A a, B b)) =>
    fa.flatMap((a) => fb.map((b) => fun(a, b)));

  static Free<F, D> map3<F, A, A2 extends A, B, B2 extends B, C, C2 extends C, D>(Free<F, A2> fa, Free<F, B2> fb, Free<F, C2> fc, D fun(A a, B b, C c)) =>
    fa.flatMap((a) => fb.flatMap((b) => fc.map((c) => fun(a, b, c))));

  static Free<F, E> map4<F, A, A2 extends A, B, B2 extends B, C, C2 extends C, D, D2 extends D, E>(Free<F, A2> fa, Free<F, B2> fb, Free<F, C2> fc, Free<F, D2> fd, E fun(A a, B b, C c, D d)) =>
    fa.flatMap((a) => fb.flatMap((b) => fc.flatMap((c) => fd.map((d) => fun(a, b, c, d)))));

  static Free<F, FF> map5<F, A, A2 extends A, B, B2 extends B, C, C2 extends C, D, D2 extends D, E, E2 extends E, FF>(Free<F, A2> fa, Free<F, B2> fb, Free<F, C2> fc, Free<F, D2> fd, Free<F, E2> fe, FF fun(A a, B b, C c, D d, E e)) =>
    fa.flatMap((a) => fb.flatMap((b) => fc.flatMap((c) => fd.flatMap((d) => fe.map((e) => fun(a, b, c, d, e))))));

  static Free<F, G> map6<F, A, A2 extends A, B, B2 extends B, C, C2 extends C, D, D2 extends D, E, E2 extends E, FF, F2 extends FF, G>(Free<F, A2> fa, Free<F, B2> fb, Free<F, C2> fc, Free<F, D2> fd, Free<F, E2> fe, Free<F, F2> ff, G fun(A a, B b, C c, D d, E e, FF f)) =>
    fa.flatMap((a) => fb.flatMap((b) => fc.flatMap((c) => fd.flatMap((d) => fe.flatMap((e) => ff.map((f) => fun(a, b, c, d, e, f)))))));

  static Free<F, Unit> ifM<F>(Free<F, bool> fbool, Free<F, Unit> ifTrue) => fbool.flatMap((bool b) => b ? ifTrue : new Pure(unit));

  @override Free<F, B> ap<B>(Free<F, Function1<A, B>> ff) => ff.bind((f) => map(f)); // TODO: optimize

  @override Free<F, Tuple2<B, A>> strengthL<B>(B b) => map((a) => tuple2(b, a));

  @override Free<F, Tuple2<A, B>> strengthR<B>(B b) => map((a) => tuple2(a, b));
}

class Pure<F, A> extends Free<F, A> {
  final A a;
  Pure(this.a);
  R fold<R>(R ifPure(A a), R ifSuspend(F fa), R ifBind(Free<F, dynamic> ffb, _FreeF<F, A> f)) => ifPure(a);
}

class Suspend<F, A> extends Free<F, A> {
  final F/**<A>**/ fa;
  Suspend(this.fa);
  R fold<R>(R ifPure(A a), R ifSuspend(F fa), R ifBind(Free<F, dynamic> ffb, _FreeF<F, A> f)) => ifSuspend(fa);
}

class Bind<F, A, B> extends Free<F, A> {
  final Free<F, B> ffb;
  final _FreeF<F, A> f;
  Bind(this.ffb, this.f);
  R fold<R>(R ifPure(A a), R ifSuspend(F fa), R ifBind(Free<F, dynamic> ffb, _FreeF<F, A> f)) => ifBind(ffb, cast(f));
}

class FreeMonad<F> extends Functor<Free<F, dynamic>> with Applicative<Free<F, dynamic>>, Monad<Free<F, dynamic>> {

  @override Free<F, A> pure<A>(A a) => new Pure(a);

  @override Free<F, B> bind<A, B>(covariant Free<F, A> fa, covariant Function1<A, Free<F, B>> f) => fa.bind(f);

}

final FreeMonad FreeM = new FreeMonad();
FreeMonad<F> freeM<F>() => new FreeMonad();

Free<F, A> liftF<F, A>(F fa) => new Suspend(fa);
