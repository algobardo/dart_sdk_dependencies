// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.analysis.reanalyze;

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:unittest/unittest.dart';

import '../analysis_abstract.dart';
import '../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(ReanalyzeTest);
}


@reflectiveTest
class ReanalyzeTest extends AbstractAnalysisTest {
  Map<String, List<AnalysisError>> filesErrors = {};

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_ERRORS) {
      var decoded = new AnalysisErrorsParams.fromNotification(notification);
      filesErrors[decoded.file] = decoded.errors;
    }
  }

  test_reanalyze() {
    createProject();
    List<AnalysisContext> contexts = server.folderMap.values.toList();
    expect(contexts, hasLength(1));
    AnalysisContext oldContext = contexts[0];
    // Reanalyze should cause a brand new context to be built.
    Request request = new Request("0", ANALYSIS_REANALYZE);
    handleSuccessfulRequest(request);
    contexts = server.folderMap.values.toList();
    expect(contexts, hasLength(1));
    AnalysisContext newContext = contexts[0];
    expect(newContext, isNot(same(oldContext)));
  }

  test_reanalyze_with_overlay() {
    createProject();
    resourceProvider.newFolder(testFolder);
    resourceProvider.newFile(testFile, 'main() {}');
    return waitForTasksFinished().then((_) {
      // Update the content with an overlay that contains a syntax error.
      server.updateContent('1', {
        testFile: new AddContentOverlay('main() {')
      });
      return waitForTasksFinished();
    }).then((_) {
      // Verify that the syntax error was detected.
      List<AnalysisError> errors = filesErrors[testFile];
      expect(errors, hasLength(1));
      // Remove testFile from filesErrors so that we'll notice when the file is
      // re-analyzed.
      filesErrors.remove(testFile);
      // Reanalyze.
      server.reanalyze();
      return waitForTasksFinished();
    }).then((_) {
      // The file should have been reanalyzed.
      expect(filesErrors, contains(testFile));
      // Verify that the syntax error is present (this indicates that the
      // content introduced by the call to updateContent is still in effect).
      List<AnalysisError> errors = filesErrors[testFile];
      expect(errors, hasLength(1));
    });
  }
}
