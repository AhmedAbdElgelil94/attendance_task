import '../error/failures.dart';

abstract class Result<T> {
  const Result();
  
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  });
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) => success(data);
}

class Error<T> extends Result<T> {
  final Failure failure;
  const Error(this.failure);

  @override
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) error,
  }) => error(failure);
} 