import os
import subprocess

FPGA_TESTCASE_DIR = 'testcase/fpga'
TESTSPACE_DIR = 'testspace'
red_msg = "\033[31m{msg}\033[0m"
green_msg = "\033[32m{msg}\033[0m"
blue_msg = "\033[34m{msg}\033[0m"

def run_test(test_name):
    command = f'Arch.exe run make run_fpga name={test_name} > {TESTSPACE_DIR}/test.out 2> {TESTSPACE_DIR}/test.info -s'
    process = subprocess.run(command, shell=True)
    try:
        ans = open(f'{FPGA_TESTCASE_DIR}/{test_name}.ans').read()
        out = open(f'{TESTSPACE_DIR}/test.out').read()
        if ans == out:
            print(green_msg.format(msg=f'Test {test_name}: PASS'))
        else:
            print(red_msg.format(msg=f'Test {test_name}: FAIL'))
    except FileNotFoundError:
        print(blue_msg.format(msg=f'Test {test_name}: NO ANSWER FILE'))

test_cases = [f[:-2] for f in os.listdir(FPGA_TESTCASE_DIR) if f.endswith('.c')]
test_cases.remove('heart') # this testcase is too big
for test_case in test_cases:
    print(f'Running test {test_case}...')
    run_test(test_case)