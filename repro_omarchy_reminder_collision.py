import json
from pathlib import Path
import re
import subprocess
import sys
import time

phase = sys.argv[1]
root = Path('/home/omarchy/reminder-validation')
command = root / phase / 'bin/omarchy-reminder'
root.mkdir(exist_ok=True)

def run(message):
    started = time.time()
    result = subprocess.run(['bash', '-x', str(command), '10', message], capture_output=True, text=True)
    return {'message': message, 'started': started, 'finished': time.time(),
            'returncode': result.returncode, 'stdout': result.stdout, 'stderr': result.stderr,
            'set_at': re.search(r'^\+ set_at=(\d+)$', result.stderr, re.M).group(1)}

for attempt in range(5):
    subprocess.run([str(command), 'clear'], check=True, capture_output=True)
    # Align with the start of a natural clock second. No clock or systemd mocks.
    time.sleep(1.04 - time.time() % 1)
    calls = [run('Check the oven'), run('Call mom')]
    if len({call['set_at'] for call in calls}) == 1:
        break
else:
    raise RuntimeError('Did not create both reminders within the same actual clock second')

listing = json.loads(subprocess.check_output([str(command), 'show', '--json'], text=True))
service_commands = {item['unit']: subprocess.check_output(
    ['systemctl', '--user', 'show', item['unit'] + '.service', '-p', 'ExecStart'], text=True)
    for item in listing['reminders']}
report = {'phase': phase, 'attempt': attempt + 1, 'calls': calls, 'listing': listing,
          'service_commands': service_commands,
          'bash_version': subprocess.check_output(['bash', '--version'], text=True).splitlines()[0],
          'systemd_version': subprocess.check_output(['systemd-run', '--version'], text=True).splitlines()[0]}
(root / f'{phase}.json').write_text(json.dumps(report, indent=2))
for index, call in enumerate(calls):
    (root / f'{phase}-call-{index + 1}.log').write_text(call['stderr'])
print(json.dumps(report, indent=2))
if phase == 'before':
    assert sorted(call['returncode'] for call in calls) == [0, 1]
    assert listing['count'] == 1
    assert listing['reminders'][0]['message'] == 'Call mom'
    assert 'Check the oven' in next(iter(service_commands.values()))
else:
    assert all(call['returncode'] == 0 for call in calls)
    assert listing['count'] == 2
    assert sorted(item['message'] for item in listing['reminders']) == ['Call mom', 'Check the oven']
