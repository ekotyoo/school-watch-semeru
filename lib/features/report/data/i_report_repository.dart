import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../common/error/failure.dart';
import '../domain/comment.dart';
import '../domain/report.dart';
import '../domain/report_detail.dart';
import '../domain/report_query.dart';

abstract class IReportRepository {
  Future<List<Report>> getReports({
    required ReportQuery query,
    CancelToken? cancelToken,
  });

  Future<ReportDetail> getReport({
    required String reportId,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, Comment>> postComment({
    required String reportId,
    required String comment,
    CancelToken? cancelToken,
  });
}
