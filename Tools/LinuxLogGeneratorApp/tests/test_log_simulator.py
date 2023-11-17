import unittest
import logging
import sys
from ..src.log_simulator import check_facility, parse_arguments, generate_random_log_data, configure_logger, generate_log_message, get_log_format, generate_logs

class TestLogSimulator(unittest.TestCase):
    def test_check_facility(self):
        self.assertTrue(check_facility('auth'))
        self.assertFalse(check_facility('invalid'))

    def test_parse_arguments(self):
        args = parse_arguments(['--format', 'syslog', '--facility', 'auth', '--events', '1000', '--rate', '1', '--level', 'INFO', '--runtime', '0'])
        self.assertEqual(args.format, 'syslog')
        self.assertEqual(args.facility, 'auth')
        self.assertEqual(args.events, 1000)
        self.assertEqual(args.rate, 1)
        self.assertEqual(args.level, 'INFO')

    def test_generate_random_log_data(self):
        log_data = generate_random_log_data(1)
        self.assertIn('auth_result', log_data)
        self.assertIn('auth_event', log_data)

    def test_configure_logger(self):
        logger = configure_logger('INFO', 'auth', 'syslog')
        self.assertEqual(logger.level, logging.INFO)
        self.assertIsInstance(logger.handlers[0], logging.StreamHandler)

    def test_generate_log_message(self):
        log_data = generate_random_log_data(1)
        log_message = generate_log_message('syslog', log_data, 'INFO', 'auth')
        self.assertIsInstance(log_message, str)

    def test_get_log_format(self):
        log_format = get_log_format('syslog')
        self.assertIsInstance(log_format, str)

    def test_generate_logs(self):
        generate_logs('syslog', 'auth', 1, 1, 'INFO', 1)
        # Check the output logs to verify the function's behavior

if __name__ == '__main__':
    unittest.main()