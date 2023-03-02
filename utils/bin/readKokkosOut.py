#!/usr/bin/env python3

import json
import argparse
import typing
from datetime import datetime
from pathlib import Path

parser = argparse.ArgumentParser(prog='GoogleTest Unit Test Parser', description='Parses gTest results for AOMP CI output')
parser.add_argument('filename', help='The filename with the unit test results to parse')
parser.add_argument('outfilename', help='The filename to which append to the transformed info')
parser.add_argument('--snapshot', type=str, default='', help='Identifier to indicate which set of passing/failing tests to read from file')
parser.add_argument('--failfile', type=str, default='kokkos-fails.json', help='File holding expexted failure cases for one or more snapshot identifiers')


def createOrAppend(filename : str, line : str) -> None:
  with open(filename, "a") as theFile:
    # We simply append the content line to the existing (or created) file
    theFile.write(line)


def getToday() -> str:
  return datetime.today().strftime('%Y-%m-%d')


# The format of the openmp-tester files are as follows:
# Test|Group|Label|Dir|Data|Unit|Error|[Date]
# Kokkos | TestSuite | TestSuite Name | $KOKKOS_DIR | Value | Unit as string | ? | Date
def appendSuiteResultsToCODResultFile(RD, outfile : str) -> None:
  numErrors = RD['failures'] + RD['errors']
  numPasses = RD['tests'] - numErrors
  passRate = (float(numPasses) / RD['tests']) * 100
  line = 'Kokkos | TestSuite | '
  line += RD['testsuiteName'] + ' | '
  line += ' 1 | ' # TODO: Kokkos_DIR or some build info?
  line += "{:> 3.2f}".format(passRate) + ' | '
  line += ' % | ' # the unit as text, e.g., seconds
  line += ' Yes | ' if numErrors > 0 else ' | '
  line += getToday() + '\n'
  line = line.replace(' ', '')

  createOrAppend(outfile, line)


def appendSingleResultToCODResultFile(TCName : str, outfile : str, PassFailRegression : int) -> None:
  '''
  This function appends a line for each test case from the test suite to the extract file.
  It uses the PassFailRegression integer to indicate the status of the test's success.
  0 -- success
  1 -- expected failure
  2 -- regression
  '''
  line = 'Kokkos | TestCase | '
  line += TCName + ' | '
  line += str(PassFailRegression) + ' | '
  line += ' Yes ' if PassFailRegression > 0 else ' | '
  line += getToday() + '\n'
  line = line.replace(' ', '')

  createOrAppend(outfile, line)


def getExpectedFails(filename : str, snapshot : str):
  with open(filename, 'r') as theFile:
    cases = json.load(theFile)
    failingCases = cases[snapshot]
    return set(failingCases)


def compareFailsWithBaseline(JsonSuite, outfile : str, failfile: str, snapshot : str) -> None:
  expectedPassFails = getExpectedFails(failfile, snapshot)

  # Identify the exact tests that didn't work for the different reports
  for t in JsonSuite:
    PFR = 0
    qualName = t['classname'] + '.' + t['name']
    if 'failures' in t:
      # This test case did not succeed. Check if this is known, or a regression
      if not qualName in expectedPassFails:
        # Regression
        print('Found a regression')
        PFR = 2
      else:
        # We expeted this to fail
        print('This was expectedly not working')
        PFR = 1
      
    # No failure occured
    appendSingleResultToCODResultFile(qualName, outfile, PFR)


def transform(args) -> None:
  filename = args.filename
  outfilename = args.outfilename
  failfile = args.failfile
  snapshot = args.snapshot

  '''
  The function takes a filename to a gtest JSON output file as argument and transforms the content
  into the format that is used by the openmp-tester in their resports.
  '''
  with open(filename, "r") as theFile:
    jsonObj = json.load(theFile)

    # We iterate over the suites, as within an executable a user can define multiple suites
    for suite in jsonObj['testsuites']:
      print('Processing Kokkos unit test suite ' + suite['name'])

      # The format of the dict is:
      # 'testsuiteName': <Name>; 'tests': <NumTests>; 'failures': <NumFailures>; 'disabled': <NumDisabled>; 'errors': <NumErrors>; 'time': <RunTimeInSecs>
      results = {}

      # Google Test stores the number of 'tests' per test suite together with
      # number of 'failures', 'disabled' and 'errors', where disabled means
      # skipped and errors are hard errors (I assume the latter)
      print(str(suite['tests']) + ' with ' + str(suite['failures']) + '/' + str(suite['disabled']) + '/' + str(suite['errors']) + ' failures/disabled/errors')
      results['testsuiteName'] = suite['name']
      results['time'] = suite['time']
      results['tests'] = suite['tests']
      results['failures'] = suite['failures']
      results['disabled'] = suite['disabled']
      results['errors'] = suite['errors']

      # Append the results to the file that is used for email
      # This is the percentage overview of passing rate
      appendSuiteResultsToCODResultFile(results, outfilename)

      # Given that a snapshot identifier and a fail-file was given, perform a comparison of the results
      # w.r.t. that file and attach the test cases to the final ext result file.
      compareFailsWithBaseline(suite['testsuite'], outfilename, failfile, snapshot)


if __name__ == '__main__':
    args = parser.parse_args()
    transform(args)
