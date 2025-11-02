import 'package:dartz/dartz.dart';
import '../error_handler/failure.dart';

abstract class BaseUseCase<In, Out>{
  Future<Either<Failure,Out>> execute(In request);
}

abstract class BaseGetUseCase<Out>{
  Future<Either<Failure,Out>> execute();
}