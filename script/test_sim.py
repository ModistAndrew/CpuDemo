import os
import subprocess

SIM_TESTCASE_DIR = 'testcase/sim'
TESTSPACE_DIR = 'testspace'
red_msg = "\033[31m{msg}\033[0m"
green_msg = "\033[32m{msg}\033[0m"
blue_msg = "\033[34m{msg}\033[0m"
msg_start = "VCD info: dumpfile test.vcd opened for output."
msg_end = "IO:Return"

def run_test(test_name):
    command = f'wsl make run_sim name={test_name} > {TESTSPACE_DIR}/test.out -s'
    process = subprocess.run(command, shell=True)
    try:
        ans = open(f'{SIM_TESTCASE_DIR}/{test_name}.ans').read()
        out = open(f'{TESTSPACE_DIR}/test.out').read()
        out = out[len(msg_start)+1:-len(msg_end)-1]
        if ans == out:
            print(green_msg.format(msg=f'Test {test_name}: PASS'))
        else:
            print(red_msg.format(msg=f'Test {test_name}: FAIL'))
            print(out)
    except FileNotFoundError:
        print(blue_msg.format(msg=f'Test {test_name}: NO ANSWER FILE'))

test_cases = [f[:-2] for f in os.listdir(SIM_TESTCASE_DIR) if f.endswith('.c')]
for test_case in test_cases:
    print(f'Running test {test_case}...')
    run_test(test_case)