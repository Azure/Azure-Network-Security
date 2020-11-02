
import time

from ixia.bpcddos.session import Session

# constants
__USER_EMAIL    = 'username@example.com'
__PASSWORD      = 'password'

__POLL_TIME     = 15

# valid public ip for Web app or internet facing endpoint/resource
__TARGET_IP     = 'valid-public-ip-in-your-azure-subscription'
__TARGET_PORT   = 443
__PROFILE_ID    = 'tcp-syn-flood'
__PROFILE_SIZE  = 'small'
__TEST_DURATION = 600


if __name__ == '__main__':
    session = Session(__USER_EMAIL, __PASSWORD)

    # start test using string params
    new_test = session.start_test(
        __TARGET_IP, __TARGET_PORT,
        __PROFILE_ID, __PROFILE_SIZE, __TEST_DURATION
    )
    # wait for the test to finish:
    while not new_test.stopped:
        time.sleep(__POLL_TIME)
