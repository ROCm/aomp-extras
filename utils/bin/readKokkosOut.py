#!/usr/bin/env python3

import json
import argparse
import typing
from datetime import datetime
from pathlib import Path

parser = argparse.ArgumentParser(prog='GoogleTest Unit Test Parser', description='Parses gTest results for AOMP CI output')
parser.add_argument('filename', help='The filename with the unit test results to parse')
parser.add_argument('outfilename', help='The filename to which append to the transformed info')


def createOrAppend(filename : str, line : str) -> None:
  with open(filename, "a") as theFile:
    # We simply append the content line to the existing (or created) file
    theFile.write(line)


def getToday() -> str:
  return datetime.today().strftime('%Y-%m-%d')


# The format of the openmp-tester files are as follows:
# Test|Group|Label|Dir|Data|Unit|Error|[Date]
# Kokkos | UnitTest | TestSuite Name | $KOKKOS_DIR | Value | Unit as string | ? | Date
def appendResultsToCODResultFile(RD, outfile : str) -> None:
  numErrors = RD['failures'] + RD['errors']
  numPasses = RD['tests'] - numErrors
  passRate = (float(numPasses) / RD['tests']) * 100
  line = 'Kokkos | UnitTest | '
  line += RD['testsuiteName'] + ' | '
  line += ' 1 | ' # TODO: Kokkos_DIR or some build info?
  line += "{:> 3.2f}".format(passRate) + ' | '
  line += ' % | ' # the unit as text, e.g., seconds
  line += ' Yes | ' if numErrors > 0 else ' | '
  line += getToday() + '\n'
  line.replace(' ', '')

  createOrAppend(outfile, line)


def transform(filename : str, outfilename : str) -> None:
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
      appendResultsToCODResultFile(results, outfilename)


if __name__ == '__main__':
    args = parser.parse_args()
    transform(args.filename, args.outfilename)
