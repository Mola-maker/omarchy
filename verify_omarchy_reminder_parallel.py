import concurrent.futures
import json
from pathlib import Path
import subprocess

root = Path('/home/omarchy/reminder-validation')
command = root / 'after/bin/omarchy-reminder'
subprocess.run([str(command), 'clear'], check=True, capture_output=True)
messages = [f'Parallel native reminder {i}' for i in range(1, 13)]
def create(message):
    result = subprocess.run([str(command), '10', message], capture_output=True, text=True)
    return {'message': message, 'returncode': result.returncode, 'stderr': result.stderr}
with concurrent.futures.ThreadPoolExecutor(max_workers=12) as pool:
    calls = list(pool.map(create, messages))
listing = json.loads(subprocess.check_output([str(command), 'show', '--json'], text=True))
assert all(call['returncode'] == 0 for call in calls)
assert listing['count'] == 12
assert sorted(item['message'] for item in listing['reminders']) == sorted(messages)
timers = [item['timer'] for item in listing['reminders']]
subprocess.run([str(command), 'clear'], check=True, capture_output=True)
cleared = json.loads(subprocess.check_output([str(command), 'show', '--json'], text=True))
assert cleared['count'] == 0
assert all(subprocess.run(['systemctl', '--user', 'is-active', '--quiet', timer]).returncode != 0 for timer in timers)
(root / 'parallel.json').write_text(json.dumps({'calls': calls, 'listing': listing, 'after_clear': cleared}, indent=2))
print('12 concurrent native systemd timers created, messages exact; clear stopped every timer.')
