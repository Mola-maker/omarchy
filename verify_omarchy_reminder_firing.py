import json
from pathlib import Path
import subprocess
import time

root = Path('/home/omarchy/reminder-validation')
command = root / 'after/bin/omarchy-reminder'
subprocess.run([str(command), 'clear'], check=True, capture_output=True)
monitor_file = root / 'notification-bus.jsonl'
with monitor_file.open('w') as output:
    monitor = subprocess.Popen(['busctl', '--user', '--json=short', 'monitor', 'org.freedesktop.Notifications'],
                               stdout=output, stderr=subprocess.PIPE, text=True)
    try:
        time.sleep(0.2)
        assert monitor.poll() is None, monitor.stderr.read()
        subprocess.run([str(command), '1', 'Native firing verification'], check=True, capture_output=True)
        subprocess.run([str(command), '1'], check=True, capture_output=True)
        listing = json.loads(subprocess.check_output([str(command), 'show', '--json'], text=True))
        assert listing['count'] == 2
        message_files = [Path('/run/user/1000/omarchy-reminders') / (item['unit'] + '.message')
                         for item in listing['reminders']]
        assert all(p.exists() for p in message_files)
        started = time.monotonic()
        print('Two one-minute real timers started; waiting for actual notification delivery.', flush=True)
        while any(p.exists() for p in message_files) and time.monotonic() - started < 145:
            time.sleep(0.5)
        assert all(not p.exists() for p in message_files), 'Timer payload did not clear its own reserved message'
        elapsed = time.monotonic() - started
    finally:
        monitor.terminate()
        monitor.wait(timeout=5)

events = [json.loads(line) for line in monitor_file.read_text().splitlines() if line.startswith('{')]
notifications = [event['payload']['data'] for event in events
                 if event.get('member') == 'Notify' and event.get('interface') == 'org.freedesktop.Notifications']
fired = [data[4] for data in notifications if data[3] == 'Reminder']
assert sorted(fired) == ['Native firing verification', 'Your 1 minutes are up'], fired
remaining = json.loads(subprocess.check_output([str(command), 'show', '--json'], text=True))
assert remaining['count'] == 0
(root / 'firing.json').write_text(json.dumps({'initial_listing': listing, 'elapsed_seconds': elapsed,
    'delivered_reminder_bodies': fired, 'message_files_removed': True, 'after_firing': remaining}, indent=2))
print('Both real timer notifications delivered with exact bodies; both reservations removed; active count zero.')
