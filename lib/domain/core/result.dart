import 'failure.dart';

sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T value) success,
    required R Function(Failure failure) error,
  }) {
    final self = this;
    return switch (self) {
      Success<T>() => success(self.value),
      Error<T>() => error(self.failure),
    };
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Error<T> extends Result<T> {
  const Error(this.failure);
  final Failure failure;
}