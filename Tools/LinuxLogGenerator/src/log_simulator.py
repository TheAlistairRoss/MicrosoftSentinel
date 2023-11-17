"""
This script generates logs in either syslog or CEF format, with a specified logging facility, number of events, event logging rate, logging level, and total running time. The generated logs contain random data for various fields, such as device vendor, product, and version, as well as authentication-related fields like user, outcome, and reason.
This script can be run on any Linux system with Python 3.10 or later installed. It requires the following Python packages:
    - logging
    - time
    - argparse
    - sys
    - random
    - requests
    - configparser

It can be installed as a systemd service by running the following commands:
    /install/install.sh

Usage:
    python log_simulator.py [--format FORMAT] [--facility FACILITY] [--events EVENTS] [--rate RATE] [--level LEVEL] [--runtime RUNTIME]

Options:
    --format FORMAT         The logging format. Can be either 'syslog' or 'cef'. Default is 'syslog'.
    --facility FACILITY     The logging facility. Can be one of 'auth', 'authpriv', 'cron', 'daemon', 'ftp', 'kern', 'lpr', 'mail', 'news', 'syslog', 'user', 'uucp', 'local0', 'local1', 'local2', 'local3', 'local4', 'local5', 'local6', 'local7'. Default is 'syslog'.
    --events EVENTS         The total number of events to log. Default is 20.
    --rate RATE             The event logging rate (seconds per event). Default is 60.
    --level LEVEL           The logging level. Can be one of 'DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'. Default is 'INFO'.
    --runtime RUNTIME       The total running time in seconds. If set to 0, the script will run indefinitely. Default is 0.
    
Examples:
    Generate 50 syslog events with a logging rate of 30 seconds per event:
        python log_simulator.py --format syslog --events 50 --rate 30

        <34>Oct 11 22:14:15 myhost myprogram[12345]: User 'admin' logged in

    Generate CEF events with a logging rate of 10 seconds per event and a total running time of 300 seconds:
        python log_simulator.py --format cef --rate 10 --runtime 300
"""

import logging
import time
import argparse
import sys
import random
import configparser

if sys.version_info < (3, 10):
    print("This script requires Python 3.10 or later")
    sys.exit(1)

valid_facilities = ["auth", "authpriv", "cron", "daemon", "ftp", "kern", "lpr", "mail", "news", "syslog", "user", "uucp", "local0", "local1", "local2", "local3", "local4", "local5", "local6", "local7"]
valid_levels = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
def check_facility(facility):
    try:
        logger = logging.getLogger(__name__)
        handler = logging.handlers.SysLogHandler(facility=facility)
        logger.addHandler(handler)
        return True
    except Exception:
        return False


def parse_arguments():
    parser = argparse.ArgumentParser(description="Generate logs in either syslog or CEF format.")
    parser.add_argument("--config", type=str, help="Path to a configuration file.")
    parser.add_argument("--format", type=str, choices=["syslog", "cef"], default="syslog", help="The logging format. Default is 'syslog'.")
    parser.add_argument("--facility", type=str, choices=valid_facilities, default="syslog", help="The logging facility. Default is 'syslog'.")
    parser.add_argument("--events", type=int, default=20, help="The total number of events to log. Default is 20.")
    parser.add_argument("--rate", type=int, default=60, help="The event logging rate (seconds per event). Default is 60.")
    parser.add_argument("--level", type=str, choices=valid_levels, default="INFO", help="The logging level. Default is 'INFO'.")
    parser.add_argument("--runtime", type=int, default=0, help="The total running time in seconds. If set to 0, the script will run indefinitely. Default is 0.")
    args = parser.parse_args()

    if args.config:
        config = configparser.ConfigParser()
        config.read(args.config)

        args.format = config.get('DEFAULT', 'format', fallback=args.format)
        args.facility = config.get('DEFAULT', 'facility', fallback=args.facility)
        args.events = config.getint('DEFAULT', 'events', fallback=args.events)
        args.rate = config.getint('DEFAULT', 'rate', fallback=args.rate)
        args.level = config.get('DEFAULT', 'level', fallback=args.level)
        args.runtime = config.getint('DEFAULT', 'runtime', fallback=args.runtime)

    if not check_facility(args.facility):
        if args.facility == 'authpriv' and check_facility('security'):
            args.facility = 'security'
        else:
            print(f"Error: The facility '{args.facility}' is not supported on this system.")
            sys.exit(1)

    if args.events <= 0:
        print("Error: Number of events must be greater than 0.")
        sys.exit(1)

    if args.rate <= 0:
        print("Error: Logging rate must be greater than 0.")
        sys.exit(1)

    if args.level == "DEBUG" and args.runtime == 0:
        print("Error: Debug logging requires a finite runtime.")
        sys.exit(1)

    return args


def generate_random_log_data(i):

    # Map each combination of auth result and auth event to a unique number
    device_event_class_id_map = {
        ('success', 'login'): 1,
        ('success', 'logout'): 2,
        ('success', 'password_change'): 3,
        ('success', 'account_creation'): 4,
        ('failure', 'login'): 5,
        ('failure', 'logout'): 6,
        ('failure', 'password_change'): 7,
        ('failure', 'account_creation'): 8,
        ('failure', 'invalid_credentials'): 9,
        ('failure', 'expired_password'): 10,  
    }
    
    response_map = {
        'allow': 'success',
        'deny': 'failure',
    }

    decisions = ['allow', 'deny']
    reasons = ['unknown', 'expired_password', 'invalid_credentials']
    responses = ['success', 'failure']
    auth_events = ['login', 'logout', 'password_change', 'account_creation']
    users = ['alice', 'bob', 'charlie']

    response = random.choice(responses)
    auth_event = random.choice(auth_events)
    decision = random.choice(decisions) if response == 'failure' else None
    reason = random.choice(reasons) if response == 'failure' else None
    
    user = random.choice(users)

    log_data = {
        'device_vendor': 'Contoso',
        'device_product': 'auth_server',
        'device_version': '1.0',
        'device_event_class_id': device_event_class_id_map[(response, auth_event)],
        'name': f'Auth Event {i}',
        'severity': random.randint(1, 10),
        'extension': {
            'src': f'192.168.0.{random.randint(1, 255)}',
            'dst': f'192.168.0.{random.randint(1, 255)}',
            'spt': random.randint(1024, 65535),
            'dpt': 22,
            'request': f'/auth?user={user}&password=********',
            'response': response,
            'user': user,
            'outcome': response,
            'reason': reason,
            'cs1': 'password',
            'deviceProcessName': 'ssh',
            'authDecision': response_map[decision],
            'act': auth_event,
            'suser': random.choice(['user', 'admin', 'service_account'])
        }
    }
    return log_data

def configure_logger(level, facility, format):
    log_level = getattr(logging, level.upper(), None)
    if log_level is None:
        raise ValueError(f"Invalid logging level '{level}'")

    logger = logging.getLogger(__name__)
    logger.setLevel(log_level)

    try:
        if facility == 'console':
            handler = logging.StreamHandler()
        else:
            handler = logging.handlers.SysLogHandler(address='/dev/log', facility=facility)
    except OSError as e:
        raise ValueError(f"Unable to create handler: {e}")
    handler.setLevel(log_level)

    formatter = logging.Formatter(get_log_format(format))
    handler.setFormatter(formatter)

    logger.addHandler(handler)
    return logger

def generate_log_message(format, log_data, level, facility):
    level_number = getattr(logging, level.upper(), None)
    if level_number is None:
        raise ValueError(f"Invalid logging level '{level}'")

    if format == 'syslog':
        return f"<{valid_facilities.index(facility) * 8 + level_number}> {log_data['device_vendor']} {log_data['device_event_class_id']} {log_data['user']} {log_data['extension']['outcome']} {log_data['extension']['reason']}"
    elif format == 'cef':
        extension = ' '.join(f'{k}={v}' for k, v in log_data['extension'].items())
        return f"CEF:0|{log_data['device_vendor']}|{log_data['device_product']}|{log_data['device_version']}|{log_data['device_event_class_id']}|{log_data['name']}|{log_data['severity']}|{extension}"
    else:
        raise ValueError(f"Invalid format value '{format}'. Format must be either 'syslog' or 'cef'.")


def get_log_format(format):
    if format == 'cef':
        return '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    else:
        return '%(message)s'


def generate_logs(format, facility, events, rate, level, runtime):
    # Validate arguments
    if not isinstance(events, int) or events <= 0:
        raise ValueError("events must be a positive integer")
    if not isinstance(rate, (int, float)) or rate <= 0:
        raise ValueError("rate must be a positive number")
    if level.upper() not in ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]:
        raise ValueError("level must be one of 'DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'")
    if not isinstance(runtime, int) or runtime < 0:
        raise ValueError("runtime must be a non-negative integer")

    if facility not in ['console'] + valid_facilities:
        raise ValueError("facility must be 'console' or a valid syslog facility")

    log_level = getattr(logging, level.upper(), None)
    if log_level is None:
        raise ValueError(f"Invalid logging level '{level}'")

    logger = logging.getLogger(__name__)
    logger.setLevel(log_level)

    try:
        if facility == 'console':
            handler = logging.StreamHandler()
        else:
            handler = logging.handlers.SysLogHandler(address='/dev/log', facility=facility)
    except OSError as e:
        raise ValueError(f"Unable to create handler: {e}")
    handler.setLevel(log_level)

    formatter = logging.Formatter(get_log_format(format))
    handler.setFormatter(formatter)

    logger.addHandler(handler)

    start_time = time.time()
    for i in range(events):
        # Check if runtime has been exceeded
        if runtime > 0 and time.time() - start_time >= runtime:
            break

        log_start_time = time.time()

        try:
            log_data = generate_random_log_data(i)
        except ValueError as e:
            logging.error(f"Failed to generate log data: {e}")
            print(f"Failed to generate log data: {e}")
            return

        try:
            log_message = generate_log_message(format, log_data, log_level, facility)
            logger.log(log_level, log_message)
        except ValueError as e:
            logging.error(str(e))
            print(str(e))
            return

        time.sleep(max(0, rate - (time.time() - log_start_time)))


def main():
    args = parse_arguments()
    logger = configure_logger(args.level, args.facility)
    generate_logs(logger, args.format, args.events, args.rate, args.level, args.runtime)


if __name__ == "__main__":
    main()


