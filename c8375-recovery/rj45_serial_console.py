import os, sys, termios, select, json, datetime, fcntl
from pathlib import Path

port = '/dev/cu.usbserial-AL00F7EQ'
logdir = Path('/Users/games/Documents/SOFTWARE/c8375-recovery/console-logs')
logdir.mkdir(parents=True, exist_ok=True)
stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
log = (logdir / (stamp + '-console.log')).open('ab', buffering=0)
fd = os.open(port, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
fcntl.ioctl(fd, termios.TIOCEXCL)
attrs = termios.tcgetattr(fd)
attrs[0] = 0
attrs[1] = 0
attrs[2] = termios.CLOCAL | termios.CREAD | termios.CS8
attrs[3] = 0
baud = int(sys.argv[1]) if len(sys.argv) > 1 else 115200
attrs[4] = attrs[5] = getattr(termios, 'B' + str(baud))
attrs[6][termios.VMIN] = 0
attrs[6][termios.VTIME] = 0
termios.tcsetattr(fd, termios.TCSANOW, attrs)
print('CONSOLE OPEN: ' + str(baud) + ' 8N1; log=' + str(logdir / (stamp + '-console.log')), flush=True)
triggers = []
recent = b''
try:
    while True:
        ready, _, _ = select.select([fd, sys.stdin], [], [], 0.5)
        if fd in ready:
            try:
                data = os.read(fd, 65536)
            except BlockingIOError:
                data = b''
            if data:
                log.write(data)
                sys.stdout.buffer.write(data)
                sys.stdout.buffer.flush()
                recent = (recent + data)[-32768:]
                for trigger in list(triggers):
                    if trigger['pattern'].encode() in recent:
                        payload = trigger['send'].encode()
                        os.write(fd, payload)
                        log.write(('\n[AUTO TX] ' + repr(payload) + '\n').encode())
                        print('\nAUTO TRIGGER SENT: ' + repr(payload), flush=True)
                        triggers.remove(trigger)
                        recent = b''
        if sys.stdin in ready:
            line = sys.stdin.readline()
            if not line:
                break
            try:
                action = json.loads(line)
                if action.get('close'):
                    break
                if 'baud' in action:
                    baud = int(action['baud'])
                    attrs = termios.tcgetattr(fd)
                    attrs[4] = attrs[5] = getattr(termios, 'B' + str(baud))
                    termios.tcsetattr(fd, termios.TCSANOW, attrs)
                    print('CONSOLE BAUD: ' + str(baud), flush=True)
                if 'expect_send' in action:
                    triggers.append(action['expect_send'])
                    recent = b''
                    print('ARMED TRIGGER: ' + action['expect_send']['pattern'], flush=True)
                if 'send' in action:
                    data = action['send'].encode()
                    log.write(('\n[TX ' + datetime.datetime.now().isoformat() + '] ' + repr(data) + '\n').encode())
                    while data:
                        _, writable, _ = select.select([], [fd], [], 5)
                        if not writable:
                            raise TimeoutError('Serial write timed out')
                        data = data[os.write(fd, data):]
                if action.get('break'):
                    log.write(b'\n[TX SERIAL BREAK]\n')
                    termios.tcsendbreak(fd, 0)
            except Exception as exc:
                print('CONTROL ERROR:', repr(exc), flush=True)
finally:
    os.close(fd)
    log.close()
