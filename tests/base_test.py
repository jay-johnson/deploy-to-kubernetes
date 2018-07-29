import logging
import unittest

log = logging.getLogger("base_test")


class BaseTestCase(unittest.TestCase):

    debug = False

    def setUp(self):
        if self.debug:
            print("setUp")
    # end of setUp

    def tearDown(self):
        if self.debug:
            print("tearDown")
    # end of tearDown

# end of BaseTestCase
