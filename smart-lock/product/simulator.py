# simulate an Internet-connected door lock using the Murano platform
import sys
import json

from murano import Murano

if len(sys.argv) < 3:
    print('Usage:')
    print('   python ./simulator <product_id> <device_id>');

PRODUCT_ID = sys.argv[1] # 'do5pjwoazfsf9a4i'
DEVICE_ID = sys.argv[2]  # '001'

def show_state():
    print('Product ID: {0} Device ID: {1}'.format(PRODUCT_ID, DEVICE_ID))

# create a murano object for the device
murano = Murano(PRODUCT_ID, DEVICE_ID)

# Get the device key (CIK)
try:
    cik = murano.load_cik()
    print('Loaded CIK from file {0}'.format(murano.filename))
except EnvironmentError:
    # no stored CIK, so activate
    cik = murano.activate()
    print('Activated device to obtain CIK')

# initialize the state of of the smart lock
class State:
    battery_percent = 100
    lock_state = 'locked'

# write current state of the lock to Murano
writes = {'battery-percent': State.battery_percent,
          'lock-state': State.lock_state}
murano.write(writes)

def print_state():
    print('---------------------------------')
    print('product id:      {0}'.format(PRODUCT_ID))
    print('device id:       {0}'.format(DEVICE_ID))
    print('lock_state:      {0}'.format(State.lock_state))
    print('battery_percent: {0}'.format(State.battery_percent))
    print('---------------------------------')

print('Waiting for lock commands from Murano')
print('Press Ctrl+C to quit')
timestamp = None
while True:
    print_state()
    if State.battery_percent > 1:
        State.battery_percent -= 1

    # long poll on the "locked" resource
    value, timestamp = murano.read_longpoll(
        ['lock-command'],
        timeout_millis=10000,
        if_modified_since=timestamp)

    writes = {'battery-percent': State.battery_percent}

    if value is not None and value != State.lock_state:
        State.lock_state = value
        writes['lock-state'] = State.lock_state

    # send current states up to Murano
    murano.write(writes)
