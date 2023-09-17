import 'dart:io';
import 'package:xml/xml.dart';

Future<int> parseXML(List<String>? arguments) async {
  final currentDirectory = Directory.current.path;
  final filePath = arguments?.first??"";
  final file = File(filePath);
  final contents = file.readAsStringSync();
  final document = XmlDocument.parse(contents);
  int errors = 0;
  int failures = 0;
  int tests = 0;
  double time = 0;

  // get child element of "testsuite" as "testcase" loop over attributes called "name" "time"
  final root = document.rootElement;
  //get all elements names testsuite from root tag.
  final resultDetails = File('$currentDirectory/output/resultDetails.txt');
  final resultDetailsFile = await resultDetails.open(mode: FileMode.append);
  for (final testsuite in root.findElements("testsuite")) {
    //get all attributes of testsuite like [errors, skipped, failures, tests]
    String testSuiteName = "UnknownTest";
    int testSuiteErrors = 0;
    int testSuiteFailures = 0;
    int testSuiteTotals = 0;
    for (final attribute in testsuite.attributes) {
      //looping over testsuite to get counts for attributes "errors" "failures" "tests" to build table
      switch ("${attribute.name}") {
        case "errors":
          {
            testSuiteErrors = int.parse(attribute.value);
            errors = errors + testSuiteErrors;
          }
          break;
        case "failures":
          {
            testSuiteFailures = int.parse(attribute.value);
            failures = failures + testSuiteFailures;
          }
          break;
        case "tests":
          {
            testSuiteTotals = int.parse(attribute.value);
            tests = tests + testSuiteTotals;
          }
          break;
        case "name":
          {
            testSuiteName = "${attribute.value.replaceAll(".", "/").split("/").removeLast()}_test.dart";
          }
          break;
      }
    }

    final testSuiteDetails =
        " :white_check_mark: ${testSuiteTotals - testSuiteFailures - testSuiteErrors} - :red_circle: $testSuiteFailures - :warning: $testSuiteErrors";
    resultDetailsFile.writeStringSync(
        "\n<details><summary> ${(testSuiteErrors + testSuiteFailures > 0) ? ":red_square:" : ":green_square:"} $testSuiteName $testSuiteDetails </summary>\n");

    for (final testCase in testsuite.findElements("testcase")) {
      //inside test case now get name and time for that taste case with result.
      final testcaseName = testCase.getAttribute("name");
      final testCaseTime = testCase.getAttribute("time");
      time = time + double.parse(testCaseTime ?? "0");
      String testResultTypeEmoji = ":warning:";
      String testCaseOutput = "";

      if (testCase.findElements("system-out").isNotEmpty) {
        testResultTypeEmoji = ":white_check_mark:";
        testCaseOutput = testCase.findElements("system-out").first.text;
      } else if (testCase.findElements("failure").isNotEmpty) {
        testResultTypeEmoji = ":red_circle:";
        testCaseOutput = testCase.findElements("failure").first.text;
      } else if (testCase.findElements("error").isNotEmpty) {
        testCaseOutput = testCase.findElements("error").first.text;
        testResultTypeEmoji = ":warning:";
      } else if (testCase.children.isEmpty) {
        testResultTypeEmoji = ":white_check_mark:";
      }
      resultDetailsFile.writeStringSync("\n> $testResultTypeEmoji $testcaseName - :stopwatch: $testCaseTime ");
      if (testCaseOutput.isNotEmpty) {
        resultDetailsFile.writeStringSync("\n```\n $testCaseOutput \n```");
      }
    }

    resultDetailsFile.writeStringSync("\n</details>");
  }
  resultDetailsFile.closeSync();
  final fileTemplate = File('$currentDirectory/template/result_template.txt');
  final resultFile = File('$currentDirectory/output/result.txt');

  try {
    String content = fileTemplate.readAsStringSync();
    final resultDetailsContent = resultDetails.readAsStringSync();
    final minutes = time.toInt() ~/ 60;
    final seconds = time.toInt() % 60;
    content = content.replaceAll("{time}", "$minutes minutes $seconds seconds");
    content = content.replaceAll("{errors}", '$errors');
    content = content.replaceAll("{failures}", '$failures');
    content = content.replaceAll("{tests}", '$tests');
    content = content.replaceAll("{passed}", '${tests - failures - errors}');
    resultFile.writeAsStringSync(" $content \n $resultDetailsContent");
  } catch (e) {
    return 1;
  }
  return 0;
}
