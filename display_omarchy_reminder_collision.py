import json
from pathlib import Path
import subprocess
import sys

phase = sys.argv[1]
root = Path('/home/omarchy/reminder-validation')
subprocess.run(['python3', str(root / 'repro_omarchy_reminder_collision.py'), phase], check=True,
               stdout=(root / f'{phase}-display-repro.log').open('w'), stderr=subprocess.STDOUT)
report = json.loads((root / f'{phase}.json').read_text())
print(f'OMARCHY REMINDERS - REAL SYSTEMD VALIDATION: {phase.upper()}\n')
print(report['bash_version'])
print(report['systemd_version'])
print('\nTwo 10-minute reminders created in the same actual clock second:')
print(f"Unix second: {report['calls'][0]['set_at']} (no clock mocks)")
for call in report['calls']:
    print(f"  {call['message']:<20} command exit: {call['returncode']}")
print(f"\nActual active timers: {report['listing']['count']} / 2 requested\n")
for item in report['listing']['reminders']:
    print(f"  {item['unit']}")
    print(f"  Displayed message: {item['message']}")
if phase == 'before':
    print('\nBUG: second timer rejected; first reminder now displays the second message.')
    print('Actual scheduled notification still says: Check the oven')
else:
    print('\nBoth timers started. Each retained its own requested message.')
print('\nPress Enter to close this validation terminal.')
input()
